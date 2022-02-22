//
//  OTRXMPPLoginHandler.m
//  ChatSecure
//
//  Created by David Chiles on 5/13/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRXMPPLoginHandler.h"
#import "OTRXMPPManager.h"
@import XLForm;
#import "OTRXLFormCreator.h"
#import "OTRProtocolManager.h"
#import "OTRDatabaseManager.h"
#import "OTRPasswordGenerator.h"
#import <ChatSecureCore/ChatSecureCore-Swift.h>
@import XMPPFramework;
#import "OTRXMPPServerInfo.h"
#import "OTRXMPPTorAccount.h"
#import "OTRTorManager.h"
#import "OTRLog.h"
@import KVOController;

@interface OTRXMPPLoginHandler()
@end

@implementation OTRXMPPLoginHandler


- (void)moveAccountValues:(OTRXMPPAccount *)account intoForm:(XLFormDescriptor *)form
{
    if (!account) {
        return;
    }
    
    //DDLogError(@"moveAccountValues intoForm %@", account);

    [[form formRowWithTag:kOTRXLFormNicknameTextFieldTag] setValue:account.username];
    [[form formRowWithTag:kOTRXLFormPasswordTextFieldTag] setValue:account.password];
    [[form formRowWithTag:kOTRXLFormRememberPasswordSwitchTag] setValue:@(account.rememberPassword)];
    [[form formRowWithTag:kOTRXLFormLoginAutomaticallySwitchTag] setValue:@(account.autologin)];
    [[form formRowWithTag:kOTRXLFormHostnameTextFieldTag] setValue:account.domain];
    
    //if (account.proxyHost && account.proxyPort && account.proxyUser && account.proxyPass) {

    [[form formRowWithTag:kOTRXLFormProxyHostTextFieldTag] setValue:account.proxyHost];
    [[form formRowWithTag:kOTRXLFormProxyPortTextFieldTag] setValue:account.proxyPort];
    [[form formRowWithTag:kOTRXLFormProxyUserTextFieldTag] setValue:account.proxyUser];
    [[form formRowWithTag:kOTRXLFormProxyPassTextFieldTag] setValue:account.proxyPass];
    //}
    
    if (account.port != [OTRXMPPAccount defaultPort]) {
        [[form formRowWithTag:kOTRXLFormPortTextFieldTag] setValue:@(account.port)];
    } else {
        [[form formRowWithTag:kOTRXLFormPortTextFieldTag] setValue:nil];
    }
    
    XLFormRowDescriptor *autofetch = [form formRowWithTag:kOTRXLFormAutomaticURLFetchTag];
    autofetch.value = @(!account.disableAutomaticURLFetching);
    
    [[form formRowWithTag:kOTRXLFormResourceTextFieldTag] setValue:account.resource];
}

- (OTRXMPPAccount *)moveValues:(XLFormDescriptor *)form intoAccount:(OTRXMPPAccount *)intoAccount
{
    OTRXMPPAccount *account = nil;
    if (!intoAccount) {
         BOOL useTor = [[form formRowWithTag:kOTRXLFormUseTorTag].value boolValue];
        OTRAccountType accountType = OTRAccountTypeJabber;
        if (useTor) {
            accountType = OTRAccountTypeXMPPTor;
        }
        account = [OTRAccount accountWithUsername:@"" accountType:accountType];
        if (!account) {
            return nil;
        }
    } else {
        account = [intoAccount copy];
    }
    
    //DDLogError(@"moveValues intoAccount %@", account);
    
    // Username
    
    NSString *username = [[form formRowWithTag:kOTRXLFormNicknameTextFieldTag] value];

    NSString *jidNode = nil;
    NSString *jidDomain = nil;

    if (username) {
        NSArray *components = [username componentsSeparatedByString:@"@"];
        if (components.count == 2) {
            jidNode = [components firstObject];
            jidDomain = [components lastObject];
        } else {
            jidNode = username;
            jidDomain = @"secret.me";
        }
        //DDLogError(@"jidNode %@ jidDomain %@", jidNode, jidDomain);
    }

    if (!jidNode.length) { // ??
        DDLogError(@"jidNode.length error %@", jidNode);
        jidNode = [username stringByReplacingOccurrencesOfString:@" " withString:@""];
        jidNode = [jidNode lowercaseString];
        DDLogError(@"jidNode.length fixed %@", jidNode);
    }
    
    // Password
    
    NSString *password = [[form formRowWithTag:kOTRXLFormPasswordTextFieldTag] value];
    
    if (password && password.length > 0) {
        account.password = password;
    } else if (account.password.length == 0) {
        // No password in field, generate strong password for user
        account.password = [OTRPasswordGenerator passwordWithLength:20];
    }
    
    NSNumber *rememberPassword = [[form formRowWithTag:kOTRXLFormRememberPasswordSwitchTag] value];
    if (rememberPassword) {
        account.rememberPassword = [rememberPassword boolValue];
    } else {
        account.rememberPassword = YES;
    }
    
    NSNumber *autologin = [[form formRowWithTag:kOTRXLFormLoginAutomaticallySwitchTag] value];
    if (autologin) {
        account.autologin = [autologin boolValue];
    } else {
        account.autologin = YES;
    }
    
    NSNumber *autofetch = [form formRowWithTag:kOTRXLFormAutomaticURLFetchTag].value;
    if (autofetch) {
        account.disableAutomaticURLFetching = !autofetch.boolValue;
    }
    
    NSString *resource = @"secret";//[[form formRowWithTag:kOTRXLFormResourceTextFieldTag] value];
    NSString *hostname = jidDomain;//[[form formRowWithTag:kOTRXLFormHostnameTextFieldTag] value];
    NSNumber *port = [[form formRowWithTag:kOTRXLFormPortTextFieldTag] value];
    
    if (![hostname length]) { // ?
        DDLogError(@"hostname.length error %@", hostname);
        hostname = @"secret.me";
        DDLogError(@"hostname.length fixed %@", hostname);
    }
    
    account.resource = resource;
    account.domain = hostname;
    
    if (port) {
        account.port = [port intValue];
    }
    
    // Post-process values via XMPPJID for stringprep
    
    if (!jidDomain.length) { // ?
        jidDomain = account.domain;
    }
    
    XMPPJID *jid = [XMPPJID jidWithUser:jidNode domain:jidDomain resource:account.resource];
    if (!jid) {
        
        DDLogError(@"jidNode %@ jidDomain %@", jidNode, jidDomain);
        NSParameterAssert(jid != nil);
        DDLogError(@"Error creating JID from account values!");
    }
    
    account.username = jid.bare;
    account.displayName = jidNode;
    
    // Setup Proxy
    
    NSString *proxyHost = [[form formRowWithTag:kOTRXLFormProxyHostTextFieldTag] value];
    NSString *proxyPort = [[form formRowWithTag:kOTRXLFormProxyPortTextFieldTag] value];
    NSString *proxyUser = [[form formRowWithTag:kOTRXLFormProxyUserTextFieldTag] value];
    NSString *proxyPass = [[form formRowWithTag:kOTRXLFormProxyPassTextFieldTag] value];

    account.proxyHost = proxyHost;
    account.proxyPort = proxyPort;
    account.proxyUser = proxyUser;
    account.proxyPass = proxyPass;
    
    if ([proxyHost length] &&
        [proxyPort length] &&
        [proxyUser length] &&
        [proxyPass length]) {
        
        account.isUsingProxy = YES;
    } else {
        account.isUsingProxy = NO;
    }
    
    //DDLogError(@"moveValues intoAccount finished %@", account);
    
    return account;
}

#pragma - mark OTRBaseLoginViewController

- (void)prepareForXMPPConnectionFrom:(XLFormDescriptor *)form account:(OTRXMPPAccount *)account
{
    if (form) {
        account = (OTRXMPPAccount *)[self moveValues:form intoAccount:account];
    }
    
    //Reffresh protocol manager for new account settings
    [[OTRProtocolManager sharedInstance] removeProtocolForAccount:account];
    _xmppManager = (OTRXMPPManager *)[[OTRProtocolManager sharedInstance] protocolForAccount:account];
    
    [self.KVOController observe:self.xmppManager keyPath:NSStringFromSelector(@selector(loginStatus)) options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld action:@selector(connectionStatusDidChange:)];
}

- (void)performActionWithValidForm:(XLFormDescriptor *)form account:(OTRXMPPAccount *)account progress:(void (^)(NSInteger progress, NSString *summaryString))progress completion:(void (^)(OTRAccount * account, NSError *error))completion
{
    if (form) {
        account = (OTRXMPPAccount *)[self moveValues:form intoAccount:(OTRXMPPAccount*)account];
    }
    self.completion = completion;
    [self finishConnectingWithForm:form account:account];
}

- (void) finishConnectingWithForm:(XLFormDescriptor *)form account:(OTRXMPPAccount *)account {
    [self prepareForXMPPConnectionFrom:form account:account];
    NSString *password = [[form formRowWithTag:kOTRXLFormPasswordTextFieldTag] value];
    if (password.length > 0) {
        account.password = password;
    }
    [self.xmppManager connectUserInitiated:YES];
}

- (void)connectionStatusDidChange:(NSDictionary *)change
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSError *error = self.xmppManager.lastConnectionError;
        OTRAccount *account = self.xmppManager.account;
        OTRLoginStatus status = self.xmppManager.loginStatus;
        
        if (status == OTRLoginStatusAuthenticated) {
            if (self.completion) {
                self.completion(account,nil);
            }
        }
        else if (error) {
            if (self.completion) {
                self.completion(account,error);
            }
        }
    });
}

@end
