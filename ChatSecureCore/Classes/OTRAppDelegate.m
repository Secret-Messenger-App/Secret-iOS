//
//  OTRAppDelegate.m
//
//  Copyright (c) 2022 Secret, Inc. All rights reserved.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
//
//  This is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This software is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this software. If not, see <http://www.gnu.org/licenses/>
//

#import "OTRAppDelegate.h"

@import OTRAssets;
@import OTRKit;

@import AVFoundation;
@import CocoaLumberjack;
@import SAMKeychain;
@import UserNotifications;
@import XMPPFramework;
@import YapDatabase;

#import "ChatSecureCoreCompat-Swift.h"

#import "OTRConstants.h"
#import "OTRUtilities.h"
#import "OTRLog.h"

#import "OTRAccount.h"
#import "OTRBuddy.h"
#import "OTRXMPPAccount.h"
#import "OTRXMPPTorAccount.h"

#import "OTRIncomingMessage.h"
#import "OTROutgoingMessage.h"
#import "OTRCertificatePinning.h"
#import "OTRPasswordGenerator.h"

#import "OTRAccountsManager.h"
#import "OTRDatabaseManager.h"
#import "OTRProtocolManager.h"
#import "OTRSettingsManager.h"

#import "OTRAudioPlaybackController.h"
#import "OTRConversationViewController.h"
#import "OTRDatabaseUnlockViewController.h"
#import "OTRInviteViewController.h"
#import "OTRMessagesViewController.h"
#import "OTRMessagesHoldTalkViewController.h"
#import "OTRSettingsViewController.h"

#import "NSURL+ChatSecure.h"
#import "UIViewController+ChatSecure.h"

#import <LocalAuthentication/LocalAuthentication.h>

#import "OTRChatDemo.h"

#if KSCRASH
#import <KSCrash/KSCrash.h>
#import <KSCrash/KSCrashInstallationQuincyHockey.h>
#import <KSCrash/KSCrashInstallation+Alert.h>
#endif

@interface OTRAppDelegate ()

@property (nonatomic, strong) OTRSplitViewControllerDelegateObject *splitViewControllerDelegate;

@property (nonatomic, strong) NSTimer *fetchTimer;
@property (nonatomic, strong) NSTimer *backgroundTimer;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTask;

@end

@implementation OTRAppDelegate
@synthesize window = _window;

#pragma mark - Secret App

- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [LogManager.shared setupLogging];
 
    BOOL usePasscode = [OTRSettingsManager boolForOTRSettingKey:kOTRUsePasscodeKey];
    
    if (usePasscode) {
        
        LAContext *context = [[LAContext alloc] init];
        if ([context canEvaluatePolicy: LAPolicyDeviceOwnerAuthentication error:nil]) {
            
            DDLogInfo(@"Fingerprint authentication requested");
            
            __block BOOL passed = NO;
            __block NSString* passedString;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [context evaluatePolicy:LAPolicyDeviceOwnerAuthentication localizedReason:@"Secret" reply:^(BOOL success, NSError *authenticationError) {
                    if (success) {
                        
                        DDLogInfo(@"Fingerprint validation passed");
                        
                        passed = YES;
                        passedString = @"YES";
                        
                    } else {
                        
                        DDLogInfo(@"Fingerprint validation failed: %@.", authenticationError.localizedDescription);
                        
                        passed = NO;
                        passedString = @"NO";
                    }
                }];
            });
            
            while (CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0, true) && !passed && passed == NO) {
                // Run until 'flag' is not flagged (wait for the completion block to finish executing)
            };
        }
    }
 
    [SAMKeychain setAccessibilityType:kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly];
    
    // VC
    
    UIViewController *rootViewController = nil;
    
    _conversationViewController = [GlobalTheme.shared conversationViewController];
    _messagesViewController = [GlobalTheme.shared messagesViewController];
    
    //self.conversationViewController.navigationController.navigationBar.translucent = YES;
    //self.messagesViewController.navigationController.navigationBar.translucent = YES;
    
    if ([OTRDatabaseManager existsYapDatabase] && ![[OTRDatabaseManager sharedInstance] hasPassphrase]) {
        rootViewController = [[OTRDatabaseUnlockViewController alloc] init];
    } else {
        if (![OTRDatabaseManager existsYapDatabase]) {
            NSString *newPassword = [OTRPasswordGenerator passwordWithLength:OTRDefaultPasswordLength];
            NSError *error = nil;
            [[OTRDatabaseManager sharedInstance] setDatabasePassphrase:newPassword remember:YES error:&error];
            if (error) {
                DDLogError(@"Password Error: %@",error);
            }
        }

        [[OTRDatabaseManager sharedInstance] setupDatabaseWithName:OTRYapDatabaseName];
        rootViewController = [self setupDefaultSplitViewControllerWithLeadingViewController:[[UINavigationController alloc] initWithRootViewController:self.conversationViewController]];
    }
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = rootViewController;
    self.window.tintColor = [UIColor colorWithWhite:.5 alpha:1.0];
    
    [self.window makeKeyAndVisible];
    [TransactionObserver.shared startObserving];
    
    if ([PushController getPushPreference] == PushPreferenceEnabled) {
        [PushController registerForPushNotifications];
    }
    
    //[self autoLoginFromBackground:NO];
    [self configureBackgroundTasksWithApplication:application];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(batteryStateDidChange:) name:UIDeviceBatteryStateDidChangeNotification object:nil];
    [UIDevice currentDevice].batteryMonitoringEnabled = YES;
    [self batteryStateDidChange:nil];
    
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];

    [UNUserNotificationCenter currentNotificationCenter].delegate = self;
    [application registerForRemoteNotifications];
    
    NSString *b64 = [OTRBranding secretCert];
    NSData *der = [[NSData alloc] initWithBase64EncodedString:b64 options:0];
    //[OTRCertificatePinning addCertToKeychain:der];
    [OTRCertificatePinning addCertificateData:der withHostName:@"secret.me"];

    NSURL *url = [launchOptions objectForKey:UIApplicationLaunchOptionsURLKey];
    if (url) {

        if ([url.scheme isEqualToString:@"xmpp"] || [url.scheme isEqualToString:@"secret"]) {
            XMPPURI *xmppURI = [[XMPPURI alloc] initWithURL:url];
            XMPPJID *jid = xmppURI.jid;
            NSString *otrFingerprint = @"otr";
            // NSString *action = xmppURI.queryAction;
            if (jid) { //  && [action isEqualToString:@"subscribe"]
                [OTRProtocolManager handleInviteForJID:jid otrFingerprint:otrFingerprint buddyAddedCallback:^ (OTRBuddy *buddy) {
                    OTRXMPPBuddy *xmppBuddy = (OTRXMPPBuddy *)buddy;
                    if (xmppBuddy != nil) {
                        [self enterThreadWithKey:xmppBuddy.threadIdentifier collection:xmppBuddy.threadCollection];
                    }
                }];
            }
        }
    }
    
    return YES;
}

- (void) applicationDidBecomeActive:(UIApplication *)application
{
    [OTRAppDelegate setLastInteractionDate:NSDate.date];
    
    [self autoLoginFromBackground:NO];
    [self batteryStateDidChange:nil];
    
    if (self.backgroundTimer) {
        
        [self.backgroundTimer invalidate];
        self.backgroundTimer = nil;
    }
    
    if (self.backgroundTask != UIBackgroundTaskInvalid) {
        
        [application endBackgroundTask:self.backgroundTask];
        self.backgroundTask = UIBackgroundTaskInvalid;
    }
    
    [UIApplication.sharedApplication removeExtraForegroundNotifications];
    [self resetFetchTimerWithResult:UIBackgroundFetchResultNewData];
}

- (void) applicationWillResignActive:(UIApplication *)application
{
    DDLogInfo(@"applicationWillResignActive");
    
    [OTRAppDelegate setLastInteractionDate:NSDate.date];
}

- (void) applicationWillEnterForeground:(UIApplication *)application
{
    DDLogInfo(@"applicationWillEnterForeground");
}

- (void) applicationWillTerminate:(UIApplication *)application
{
    DDLogInfo(@"applicationWillTerminate");

    [[OTRProtocolManager sharedInstance] disconnectAllAccounts];
}

- (void) applicationDidEnterBackground:(UIApplication *)application
{
    DDLogInfo(@"applicationDidEnterBackground");
    
    NSAssert(self.backgroundTask == UIBackgroundTaskInvalid, nil);
    
    [self scheduleBackgroundTasksWithApplication:application completionHandler:nil];
    
    __block NSUInteger unread = 0;
    [[OTRDatabaseManager sharedInstance].readConnection asyncReadWithBlock:^(YapDatabaseReadTransaction *transaction) {
        unread = [transaction numberOfUnreadMessages];
        
    } completionBlock:^{
        
        application.applicationIconBadgeNumber = unread;
        DDLogInfo(@"numberOfUnreadMessages: %lu", (unsigned long)unread);

        // Temporary hack to fix corrupted development database
        
        if (unread > 0) {
            [self fixUnreadMessageCount:^(NSUInteger count) {
                application.applicationIconBadgeNumber = count;
            }];
        }
    }];
    
    self.backgroundTask = [application beginBackgroundTaskWithExpirationHandler: ^{
        DDLogInfo(@"Background task expired, disconnecting all accounts. Remaining: %f", application.backgroundTimeRemaining);
        if (self.backgroundTimer)
        {
            [self.backgroundTimer invalidate];
            self.backgroundTimer = nil;
        }
        [[OTRProtocolManager sharedInstance] disconnectAllAccountsSocketOnly:YES timeout:application.backgroundTimeRemaining - .5 completionBlock:^{
            [application endBackgroundTask:self.backgroundTask];
            self.backgroundTask = UIBackgroundTaskInvalid;
        }];
    }];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.backgroundTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerUpdate:) userInfo:nil repeats:YES];
    });
    
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
}

#pragma mark - Opt

- (void) application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(nonnull NSData *)deviceToken
{
    NSString *token = [[deviceToken description] stringByTrimmingCharactersInSet: [NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    NSData *data = deviceToken;
    
    NSUInteger capacity = data.length * 2;
    NSMutableString *sbuf = [NSMutableString stringWithCapacity:capacity];
    const unsigned char *buf = data.bytes;
    NSInteger i;
    for (i=0; i<data.length; ++i) {
        [sbuf appendFormat:@"%02lX", (unsigned long)buf[i]];
    }
    
    NSString *decodeString = sbuf;
    
    NSData *encodeData = [decodeString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64String = [encodeData base64EncodedStringWithOptions:0];
    
    [NSUserDefaults.standardUserDefaults setObject:base64String forKey:@"OTRDeviceToken"];
    [[NSUserDefaults standardUserDefaults]synchronize];
    //[OTRProtocolManager.pushController didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err {
    DDLogError(@"Error in registration. Error: %@%@", [err localizedDescription], [err userInfo]);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    DDLogError(@"didReceiveRemoteNotification %@", userInfo);
    
    [self scheduleBackgroundTasksWithApplication:application completionHandler:completionHandler];
}

-(void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    DDLogError(@"performFetchWithCompletionHandler");
    
    // If we have an old fetch happening, call completion on that
    [self resetFetchTimerWithResult:UIBackgroundFetchResultNoData];
    
    if(application.applicationState == UIApplicationStateBackground) {
        [self autoLoginFromBackground:YES];

        self.fetchTimer = [NSTimer scheduledTimerWithTimeInterval:28.5 target:self selector:@selector(fetchTimerUpdate:) userInfo:@{@"completion": completionHandler} repeats:NO];
    } else {
        // Must call completion handler
        completionHandler(UIBackgroundFetchResultNoData);
    }
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> *restorableObjects))restorationHandler
{
    if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
        NSURL *url = userActivity.webpageURL;
       
        if ([url otr_isInviteLink]) {
            __block XMPPJID *jid = nil;
            __block NSString *fingerprint = nil;
            NSString *otr = [OTRAccount fingerprintStringTypeForFingerprintType:OTRFingerprintTypeOTR];
            [url otr_decodeShareLink:^(XMPPJID * _Nullable inJid, NSArray<NSURLQueryItem*> * _Nullable queryItems) {
                jid = inJid;
                [queryItems enumerateObjectsUsingBlock:^(NSURLQueryItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([obj.name isEqualToString:otr]) {
                        fingerprint = obj.value;
                        *stop = YES;
                    }
                }];
            }];
            if (jid) {
                [OTRProtocolManager handleInviteForJID:jid otrFingerprint:fingerprint buddyAddedCallback:nil];
            }
            return YES;
        }
    }
    return NO;
}

- (BOOL) application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
    
    if ([url.scheme isEqualToString:@"xmpp"] || [url.scheme isEqualToString:@"secret"]) {
        XMPPURI *xmppURI = [[XMPPURI alloc] initWithURL:url];
        XMPPJID *jid = xmppURI.jid;
        NSString *otrFingerprint = xmppURI.queryParameters[@"otr-fingerprint"];
        // NSString *action = xmppURI.queryAction;
        if (jid) {//  && [action isEqualToString:@"subscribe"]
            [OTRProtocolManager handleInviteForJID:jid otrFingerprint:otrFingerprint buddyAddedCallback:^ (OTRBuddy *buddy) {
                OTRXMPPBuddy *xmppBuddy = (OTRXMPPBuddy *)buddy;
                if (xmppBuddy != nil) {
                    [self enterThreadWithKey:xmppBuddy.threadIdentifier collection:xmppBuddy.threadCollection];
                }
            }];
            return YES;
        }
    }
    return YES;
}

#pragma mark - UI

/**
 * This creates a UISplitViewController using a leading view controller (the left view controller). It uses a navigation controller with
 * self.messagesViewController as teh right view controller;
 * This also creates and sets up teh OTRSplitViewCoordinator
 *
 * @param leadingViewController The leading or left most view controller in a UISplitViewController. Should most likely be some sort of UINavigationViewController
 * @return The base default UISplitViewController
 *
 */
- (UIViewController *) setupDefaultSplitViewControllerWithLeadingViewController:(nonnull UIViewController *)leadingViewController
{
    YapDatabaseConnection *connection = [OTRDatabaseManager sharedInstance].writeConnection;
    _splitViewCoordinator = [[OTRSplitViewCoordinator alloc] initWithDatabaseConnection:connection];
    
    self.splitViewControllerDelegate = [[OTRSplitViewControllerDelegateObject alloc] init];
    self.conversationViewController.delegate = self.splitViewCoordinator;
    
    //MessagesViewController Nav
    UINavigationController *messagesNavigationController = [[UINavigationController alloc ]initWithRootViewController:self.messagesViewController];
    
    //SplitViewController
    UISplitViewController *splitViewController = [[UISplitViewController alloc] init];
    splitViewController.viewControllers = @[leadingViewController,messagesNavigationController];
    splitViewController.delegate = self.splitViewControllerDelegate;
    splitViewController.title = CHAT_STRING();
    
    //setup 'back' button in nav bar
    messagesNavigationController.topViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem;
    messagesNavigationController.topViewController.navigationItem.leftItemsSupplementBackButton = YES;
    
    self.splitViewCoordinator.splitViewController = splitViewController;
    
    return splitViewController;
}

- (void) showConversationViewController
{
    self.window.rootViewController = [self setupDefaultSplitViewControllerWithLeadingViewController:[[UINavigationController alloc] initWithRootViewController:self.conversationViewController]];
}

- (void) showSubscriptionRequestForBuddy:(NSDictionary*)userInfo
{
    // This is probably in response to a user requesting subscriptions from us
    [self.splitViewCoordinator showConversationsViewController];
}

#pragma mark - Core

- (void) addCertToKeychain:(NSData*)certInDer
{
    OSStatus            err = noErr;
    SecCertificateRef   cert;

    cert = SecCertificateCreateWithData(NULL, (CFDataRef) certInDer);
    assert(cert != NULL);

    CFTypeRef result;

    NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          (id)kSecClassCertificate, kSecClass,
                          cert, kSecValueRef,
                          nil];

    err = SecItemAdd((CFDictionaryRef)dict, &result);
    assert(err == noErr || err == errSecDuplicateItem);

    CFRelease(cert);
}

/** Doesn't stop autoLogin if previous crash when it's a background launch */
- (void) autoLoginFromBackground:(BOOL)fromBackground
{
    //DDLogInfo(@"autoLoginFromBackground");
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[OTRProtocolManager sharedInstance] loginAccounts:[OTRAccountsManager allAutoLoginAccounts]];
    });
    
}

- (void) timerUpdate:(NSTimer*)timer {
    //UIApplication *application = [UIApplication sharedApplication];
    //NSTimeInterval timeRemaining = application.backgroundTimeRemaining;
    //DDLogVerbose(@"Timer update, background time left: %f", timeRemaining);
}

- (void) fetchTimerUpdate:(NSTimer*)timer {
    void (^completion)(UIBackgroundFetchResult) = timer.userInfo[@"completion"];
    NSTimeInterval timeout = [[UIApplication sharedApplication] backgroundTimeRemaining] - .5;

    [[OTRProtocolManager sharedInstance] disconnectAllAccountsSocketOnly:YES timeout:timeout completionBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIApplication.sharedApplication removeExtraForegroundNotifications];
            // We should probably return accurate fetch results
            if (completion) {
                completion(UIBackgroundFetchResultNewData);
            }
        });
    }];
    self.fetchTimer = nil;
}

/**
 If we have a fetch timer set, call the completion callback and invalidate the timer
 */
- (void)resetFetchTimerWithResult:(UIBackgroundFetchResult)result {
    if (self.fetchTimer) {
        if (self.fetchTimer.isValid) {
            NSDictionary *userInfo = self.fetchTimer.userInfo;
            void (^completion)(UIBackgroundFetchResult) = [userInfo objectForKey:@"completion"];
            // We should probbaly return accurate fetch results
            if (completion) {
                completion(result);
            }
            [self.fetchTimer invalidate];
        }
        self.fetchTimer = nil;
    }
}

// To improve usability, keep the app open when you're plugged in
- (void) batteryStateDidChange:(NSNotification*)notification
{
    UIDeviceBatteryState currentState = [[UIDevice currentDevice] batteryState];
    if (currentState == UIDeviceBatteryStateCharging || currentState == UIDeviceBatteryStateFull) {
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    } else {
        [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    }
}

- (void) remoteControlReceivedWithEvent:(UIEvent *)event
{

    if (event.type == UIEventTypeRemoteControl) {
        switch (event.subtype) {
            case UIEventSubtypeRemoteControlPlay:
                [[OTRAudioPlaybackController shared] resumeCurrentlyPlaying];
                DDLogError(@"UIEventSubtypeRemoteControlTogglePlay");
                break;
            case UIEventSubtypeRemoteControlPause:
                [[OTRAudioPlaybackController shared] pauseCurrentlyPlaying];
                DDLogError(@"UIEventSubtypeRemoteControlTogglePause");
                break;
            case UIEventSubtypeRemoteControlTogglePlayPause:
                if ([[OTRAudioPlaybackController shared] isPlaying]) {
                    [[OTRAudioPlaybackController shared] pauseCurrentlyPlaying];
                } else {
                    [[OTRAudioPlaybackController shared] resumeCurrentlyPlaying];
                }
                DDLogError(@"UIEventSubtypeRemoteControlTogglePlayPause");
                break;
            case UIEventSubtypeRemoteControlStop:
                [[OTRAudioPlaybackController shared] stopCurrentlyPlaying];
                DDLogError(@"UIEventSubtypeRemoteControlStop");
                break;
            case UIEventSubtypeRemoteControlNextTrack:
                // Next track action
                break;
            case UIEventSubtypeRemoteControlPreviousTrack:
                // Previous track action
                break;
            default:
                // catch all action
                break;
        }
    }
}

- (BOOL) canBecomeFirstResponder
{
    return YES;
}

+ (instancetype) appDelegate
{
    return (OTRAppDelegate*)[[UIApplication sharedApplication] delegate];
}

- (void) setupTheme
{
    // ?
}

@end
