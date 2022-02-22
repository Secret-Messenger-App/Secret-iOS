//
//  OTRSettingsViewController.m
//
//  Copyright (c) 2022 Secret, Inc. All rights reserved.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRSettingsViewController.h"
#import "OTRProtocolManager.h"
#import "OTRBoolSetting.h"
#import "OTRSettingTableViewCell.h"
#import "OTRSettingDetailViewController.h"
#import "OTRQRCodeViewController.h"
@import QuartzCore;
#import "OTRConstants.h"
#import "OTRAccountTableViewCell.h"
#import "OTRSecrets.h"
@import YapDatabase;
#import "OTRDatabaseManager.h"
#import "OTRDatabaseView.h"
#import "OTRAccount.h"
#import "OTRAppDelegate.h"
#import "OTRUtilities.h"
#import "OTRShareSetting.h"
#import "OTRActivityItemProvider.h"
#import "OTRQRCodeActivity.h"
#import "OTRBaseLoginViewController.h"
#import "OTRXLFormCreator.h"
#import "OTRViewSetting.h"
#import "OTRDonateSetting.h"
@import KVOController;
#import "OTRInviteViewController.h"
#import <ChatSecureCore/ChatSecureCore-Swift.h>
@import OTRAssets;
@import MobileCoreServices;

#import "NSURL+ChatSecure.h"

static NSString *const kSettingsCellIdentifier = @"kSettingsCellIdentifier";

@interface OTRSettingsViewController () <UITableViewDataSource, UITableViewDelegate, OTRShareSettingDelegate, OTRYapViewHandlerDelegateProtocol,OTRSettingDelegate,OTRDonateSettingDelegate, UIPopoverPresentationControllerDelegate, OTRAttachmentPickerDelegate>

@property (nonatomic, strong) OTRYapViewHandler *viewHandler;
@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, nullable) OTRAttachmentPicker *avatarPicker;

@end

@implementation OTRSettingsViewController

- (id) init
{
    if (self = [super init])
    {
        self.title = SETTINGS_STRING();
        _settingsManager = [[OTRSettingsManager alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.viewHandler = [[OTRYapViewHandler alloc] initWithDatabaseConnection:[OTRDatabaseManager sharedInstance].longLivedReadOnlyConnection databaseChangeNotificationName:[DatabaseNotificationName LongLivedTransactionChanges]];
    self.viewHandler.delegate = self;
    [self.viewHandler setup:OTRAllAccountDatabaseViewExtensionName groups:@[OTRAllAccountGroup]];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    self.tableView.accessibilityIdentifier = @"settingsTableView";
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    [self.view addSubview:self.tableView];
    [self.tableView registerClass:[OTRAccountTableViewCell class] forCellReuseIdentifier:[OTRAccountTableViewCell cellIdentifier]];
    
    NSBundle *bundle = [OTRAssets resourcesBundle];
    UINib *nib = [UINib nibWithNibName:[XMPPAccountCell cellIdentifier] bundle:bundle];
    [self.tableView registerNib:nib forCellReuseIdentifier:[XMPPAccountCell cellIdentifier]];
    
    [self setupVersionLabel];
    
    __weak typeof(self)weakSelf = self;
    [self.KVOController observe:[OTRProtocolManager sharedInstance] keyPaths:@[NSStringFromSelector(@selector(numberOfConnectedProtocols)),NSStringFromSelector(@selector(numberOfConnectingProtocols))] options:NSKeyValueObservingOptionNew block:^(id observer, id object, NSDictionary *change) {
        __strong typeof(weakSelf)strongSelf = weakSelf;
        dispatch_async(dispatch_get_main_queue(), ^{
            [strongSelf.tableView reloadSections:[[NSIndexSet alloc] initWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
        });
    }];
}

- (void)setupVersionLabel
{
    UIButton *versionButton = [[UIButton alloc] init];
    NSString *bundleVersion = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleShortVersionString"];
    NSString *buildNumber = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleVersion"];
    NSString *versionTitle = [NSString stringWithFormat:@"%@ %@ (%@)", VERSION_STRING(), bundleVersion, buildNumber];
    [versionButton setTitle:versionTitle forState:UIControlStateNormal];
    [versionButton setTitleColor:UIColor.lightGrayColor forState:UIControlStateNormal];
    [versionButton addTarget:self action:@selector(versionButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [versionButton sizeToFit];
    versionButton.titleLabel.font = [UIFont systemFontOfSize:13];
    CGRect frame = versionButton.frame;
    frame.size.height = frame.size.height * 2;
    versionButton.frame = frame;
    self.tableView.tableFooterView = versionButton;
}

- (void)versionButtonPressed:(id)sender
{
    NSURL *settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    [UIApplication.sharedApplication openURL:settingsURL options:@{} completionHandler:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.navigationBar.backgroundColor = [UIColor clearColor];
    
    if (@available(iOS 13.0, *)) {

        UINavigationBarAppearance* navBarAppearance = [self.navigationController.navigationBar standardAppearance];
        [navBarAppearance configureWithOpaqueBackground];
        
        if( self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark ){
            navBarAppearance.backgroundColor = [UIColor blackColor];
        }else{
            navBarAppearance.backgroundColor = [UIColor whiteColor];
        }
        
        self.navigationController.navigationBar.standardAppearance = navBarAppearance;
        self.navigationController.navigationBar.scrollEdgeAppearance = navBarAppearance;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serverCheckUpdate:) name:ServerCheck.UpdateNotificationName object:nil];
    self.tableView.frame = self.view.bounds;
    [self.settingsManager populateSettings];
    [self.tableView reloadData];
}

- (void) serverCheckUpdate:(NSNotification*)notification {
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
}

- (OTRXMPPAccount *)accountAtIndexPath:(NSIndexPath *)indexPath
{
    OTRXMPPAccount *account = [self.viewHandler object:indexPath];
    return account;
}

#pragma mark UITableViewDataSource methods

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && indexPath.row != [self.viewHandler.mappings numberOfItemsInSection:0])
    {
        return UITableViewCellEditingStyleDelete;
    }
    else
    {
        return UITableViewCellEditingStyleNone;
    }
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
     // Accounts
    
    if (indexPath.section == 0) {

        static NSString *addAccountCellIdentifier = @"addAccountCellIdentifier";
        UITableViewCell * cell = nil;
        
        if (indexPath.row == [self.viewHandler.mappings numberOfItemsInSection:indexPath.section]) {
            
            cell = [tableView dequeueReusableCellWithIdentifier:addAccountCellIdentifier];
            
            if (cell == nil) {

                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:addAccountCellIdentifier];
                cell.textLabel.text = NEW_ACCOUNT_STRING();
                //cell.imageView.image = [UIImage imageNamed:circleImageName inBundle:[OTRAssets resourcesBundle] compatibleWithTraitCollection:nil];
                cell.detailTextLabel.text = nil;

            }

        } else {
            
            OTRXMPPAccount *account = [self accountAtIndexPath:indexPath];
            OTRXMPPManager *xmpp = (OTRXMPPManager*)[[OTRProtocolManager sharedInstance] protocolForAccount:account];
            XMPPAccountCell *accountCell = [tableView dequeueReusableCellWithIdentifier:[XMPPAccountCell cellIdentifier] forIndexPath:indexPath];
            [accountCell setAppearanceWithAccount:account];
            
            UIImage *btnImage;

            if (@available(iOS 13.0, *)) {
                btnImage = [UIImage systemImageNamed:@"person.crop.circle"];
            } else {
                btnImage = [UIImage imageNamed:@"Lock_Locked" inBundle:[OTRAssets resourcesBundle] compatibleWithTraitCollection:nil];
            }
            
            if (xmpp.loginStatus == OTRLoginStatusDisconnected) {
                 
                if (@available(iOS 13.0, *)) {
                    btnImage = [UIImage systemImageNamed:@"person.crop.circle.badge.xmark"];
                } else {
                    btnImage = [UIImage imageNamed:@"Lock_Locked_red" inBundle:[OTRAssets resourcesBundle] compatibleWithTraitCollection:nil];
                }
                
            } else if (xmpp.loginStatus == OTRLoginStatusDisconnecting ||
                       xmpp.loginStatus == OTRLoginStatusConnecting ||
                       xmpp.loginStatus == OTRLoginStatusConnected ||
                       xmpp.loginStatus == OTRLoginStatusSecuring ||
                       xmpp.loginStatus == OTRLoginStatusSecured ||
                       xmpp.loginStatus == OTRLoginStatusAuthenticating) {
                
               if (@available(iOS 13.0, *)) {
                   btnImage = [UIImage systemImageNamed:@"person.crop.circle.badge.questionmark"];
               } else {
                   btnImage = [UIImage imageNamed:@"Lock_Locked_yellow" inBundle:[OTRAssets resourcesBundle] compatibleWithTraitCollection:nil];
               }
                
            } else if (xmpp.loginStatus == OTRLoginStatusAuthenticated) {
                
                if (account.isUsingProxy) {
                    
                    if (@available(iOS 13.0, *)) {
                        btnImage = [UIImage systemImageNamed:@"person.crop.circle.badge.checkmark"];
                    } else {
                        btnImage = [UIImage imageNamed:@"Lock_Locked_Verified" inBundle:[OTRAssets resourcesBundle] compatibleWithTraitCollection:nil];
                    }
                    
                } else {
                    
                    if (@available(iOS 13.0, *)) {
                        btnImage = [UIImage systemImageNamed:@"person.crop.circle.fill"];
                    } else {
                        btnImage = [UIImage imageNamed:@"Lock_Locked" inBundle:[OTRAssets resourcesBundle] compatibleWithTraitCollection:nil];
                    }
                }
            }

            accountCell.displayNameLabel.font = [UIFont boldSystemFontOfSize:17];
            accountCell.displayNameLabel.text = [account.username otr_displayName];
            accountCell.displayNameLabel.translatesAutoresizingMaskIntoConstraints = NO;
            
            NSString *labelString = [account.username otr_nickName];
            
            accountCell.accountNameLabel.text = labelString;
            accountCell.accountNameLabel.translatesAutoresizingMaskIntoConstraints = NO;
            accountCell.accountNameLabel.font = [UIFont systemFontOfSize:15];

            [accountCell.infoButton setImage:btnImage forState:UIControlStateNormal];

            accountCell.infoButtonAction = ^(UITableViewCell *cell, id sender) {
                [self showAccountDetailsView:account];
            };
            accountCell.avatarButtonAction = ^(UITableViewCell *cell, id sender) {
                self.avatarPicker = [[OTRAttachmentPicker alloc] initWithParentViewController:self delegate:self];
                self.avatarPicker.tag = account;
                [self.avatarPicker showAlertControllerFromSourceView:cell withCompletion:nil];
            };
            accountCell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell = accountCell;
        }
        return cell;
    }
    OTRSettingTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kSettingsCellIdentifier];
    if (cell == nil)
    {
        cell = [[OTRSettingTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kSettingsCellIdentifier];
    }
    OTRSetting *setting = [self.settingsManager settingAtIndexPath:indexPath];
    setting.delegate = self;
    cell.otrSetting = setting;
    
    return cell;
}

- (void) accountCellShareButtonPressed:(id)sender
{
    if ([sender isKindOfClass:[UIButton class]]) {
        UIButton *button = sender;
        OTRAccountTableViewCell *cell = (OTRAccountTableViewCell*)button.superview;
        OTRAccount *account = cell.account;
        [ShareController shareAccount:account sender:sender viewController:self];
    }
}

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.settingsManager.settingsGroups count];
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex
{
    if (sectionIndex == 0) {
        return [self.viewHandler.mappings numberOfItemsInSection:0]+1;
    }
    return [self.settingsManager numberOfSettingsInSection:sectionIndex];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        if (indexPath.row == [self.viewHandler.mappings numberOfItemsInSection:indexPath.section]) {
            return 50.0;
        } else {
            return [XMPPAccountCell cellHeight];
        }
    }
    return UITableViewAutomaticDimension;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self.settingsManager stringForGroupInSection:section];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) { // Accounts
        if (indexPath.row == [self.viewHandler.mappings numberOfItemsInSection:0]) {
            
            [self addAccount:[tableView cellForRowAtIndexPath:indexPath]];
        } else {
            OTRXMPPAccount *account = [self accountAtIndexPath:indexPath];
            [self showAccountDetailsView:account];
        }
    } else {
        OTRSetting *setting = [self.settingsManager settingAtIndexPath:indexPath];
        OTRSettingActionBlock actionBlock = setting.actionBlock;
        if (actionBlock) {
            actionBlock(self);
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section != 0) {
        return;
    }
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        OTRAccount *account = [self accountAtIndexPath:indexPath];
        
        UIAlertAction * cancelButtonItem = [UIAlertAction actionWithTitle:CANCEL_STRING() style:UIAlertActionStyleCancel handler:nil];
        UIAlertAction * okButtonItem = [UIAlertAction actionWithTitle:OK_STRING() style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            
            if( [[OTRProtocolManager sharedInstance] isAccountConnected:account])
            {
                id<OTRProtocol> protocol = [[OTRProtocolManager sharedInstance] protocolForAccount:account];
                [protocol disconnect];
            }
            [[OTRProtocolManager sharedInstance] removeProtocolForAccount:account];
            [OTRAccountsManager removeAccount:account];
        }];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:DELETE_ACCOUNT_TITLE_STRING() message:account.nickName preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:cancelButtonItem];
        [alert addAction:okButtonItem];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

#pragma - mark Other Methods

- (void) showAccountDetailsView:(OTRXMPPAccount*)account {
    OTRAccountDetailViewController *detailVC = [GlobalTheme.shared accountDetailViewControllerForAccount:account];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:detailVC];
    navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void) addAccount:(id)sender {
    UIStoryboard *onboardingStoryboard = [UIStoryboard storyboardWithName:@"Onboarding" bundle:[OTRAssets resourcesBundle]];
    UINavigationController *welcomeNavController = [onboardingStoryboard instantiateInitialViewController];
    welcomeNavController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:welcomeNavController animated:YES completion:nil];
}

- (void) editAccout:(OTRXMPPAccount*)account {
    OTRAccountDetailViewController *detailVC = [GlobalTheme.shared accountDetailViewControllerForAccount:account];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:detailVC];
    navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (NSIndexPath *)indexPathForSetting:(OTRSetting *)setting
{
    return [self.settingsManager indexPathForSetting:setting];
}

#pragma mark OTRSettingDelegate method

- (void)refreshView
{
    [self.tableView reloadData];
}

#pragma mark OTRSettingViewDelegate method
- (void) otrSetting:(OTRSetting*)setting showDetailViewControllerClass:(Class)viewControllerClass
{
    if (viewControllerClass == [EnablePushViewController class]) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Onboarding" bundle:[OTRAssets resourcesBundle]];
        EnablePushViewController *enablePushVC = [storyboard instantiateViewControllerWithIdentifier:@"enablePush"];
        enablePushVC.modalPresentationStyle = UIModalPresentationFormSheet;
        if (enablePushVC) {
            [self presentViewController:enablePushVC animated:YES completion:nil];
        }
        return;
    }
    UIViewController *viewController = [[viewControllerClass alloc] init];
    viewController.title = setting.title;
    if ([viewController isKindOfClass:[OTRSettingDetailViewController class]])
    {
        OTRSettingDetailViewController *detailSettingViewController = (OTRSettingDetailViewController*)viewController;
        detailSettingViewController.otrSetting = setting;
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:detailSettingViewController];
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentViewController:navController animated:YES completion:nil];
    } else {
        [self.navigationController pushViewController:viewController animated:YES];
    }
}

- (void) donateSettingPressed:(OTRDonateSetting *)setting {
    [PurchaseViewController showFrom:self];
}

#pragma - mark OTRAttachmentPickerDelegate

- (void)attachmentPicker:(OTRAttachmentPicker *)attachmentPicker gotPhoto:(UIImage *)photo withInfo:(NSDictionary *)info {
    self.avatarPicker = nil;
    OTRXMPPAccount *account = attachmentPicker.tag;
    if (![account isKindOfClass:OTRXMPPAccount.class]) {
        return;
    }
    OTRXMPPManager *xmpp = (OTRXMPPManager*)[OTRProtocolManager.shared protocolForAccount:account];
    if (![xmpp isKindOfClass:OTRXMPPManager.class]) {
        return;
    }
    [xmpp setAvatar:photo completion:nil];
}

- (void)attachmentPicker:(OTRAttachmentPicker *)attachmentPicker gotVideoURL:(NSURL *)videoURL {
    self.avatarPicker = nil;
}

- (NSArray <NSString *>*)attachmentPicker:(OTRAttachmentPicker *)attachmentPicker preferredMediaTypesForSource:(UIImagePickerControllerSourceType)source
{
    return @[(NSString*)kUTTypeImage];
}

#pragma - mark OTRShareSettingDelegate Method

- (void)didSelectShareSetting:(OTRShareSetting *)shareSetting
{
    NSURL *url = [NSURL URLWithString:@"https://www.secret.me/"];
    NSArray *data = @[url];
    
    UIActivityViewController * shareViewController = [[UIActivityViewController alloc] initWithActivityItems:data applicationActivities:nil];
    [self presentViewController:shareViewController animated:YES completion:nil];
}

#pragma mark OTRFeedbackSettingDelegate method

- (void) presentFeedbackViewForSetting:(OTRSetting *)setting {
    NSURL *faqURL = [NSURL URLWithString:@"https://www.secret.me/faq.html"];
    if (!faqURL) { return; }
    [UIApplication.sharedApplication openURL:faqURL options:@{} completionHandler:nil];
}

#pragma - mark YapDatabse Methods

- (void)didSetupMappings:(OTRYapViewHandler *)handler
{
    [self.tableView reloadData];
}

- (void)didReceiveChanges:(OTRYapViewHandler *)handler sectionChanges:(NSArray<YapDatabaseViewSectionChange *> *)sectionChanges rowChanges:(NSArray<YapDatabaseViewRowChange *> *)rowChanges
{
    if ([rowChanges count] == 0) {
        return;
    }
    
    [self.tableView beginUpdates];
    
    for (YapDatabaseViewRowChange *rowChange in rowChanges)
    {
        switch (rowChange.type)
        {
            case YapDatabaseViewChangeDelete :
            {
                [self.tableView deleteRowsAtIndexPaths:@[ rowChange.indexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeInsert :
            {
                [self.tableView insertRowsAtIndexPaths:@[ rowChange.newIndexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeMove :
            {
                [self.tableView deleteRowsAtIndexPaths:@[ rowChange.indexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.tableView insertRowsAtIndexPaths:@[ rowChange.newIndexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeUpdate :
            {
                [self.tableView reloadRowsAtIndexPaths:@[ rowChange.indexPath ]
                                      withRowAnimation:UITableViewRowAnimationNone];
                break;
            }
        }
    }
    
    [self.tableView endUpdates];
}


@end
