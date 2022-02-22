//
//  OTRXMPPCreateAccountHandler.m
//  ChatSecure
//
//  Created by David Chiles on 5/13/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRXMPPCreateAccountHandler.h"
#import "OTRXMPPManager.h"
@import XLForm;
#import "OTRXLFormCreator.h"
#import "OTRProtocolManager.h"
#import "OTRDatabaseManager.h"
#import "XMPPServerInfoCell.h"
@import XMPPFramework;
#import "OTRXMPPManager.h"
#import "OTRXMPPServerInfo.h"
#import "OTRPasswordGenerator.h"
#import "OTRTorManager.h"
#import "OTRLog.h"


@implementation OTRXMPPCreateAccountHandler

- (OTRXMPPAccount *)moveValues:(XLFormDescriptor *)form intoAccount:(OTRXMPPAccount *)account
{
    account = (OTRXMPPAccount *)[super moveValues:form intoAccount:account];
    
    //DDLogError(@"OTRXMPPCreateAccountHandler moveValues %@ %@", form, account);

    //OTRXMPPServerInfo *serverInfo = [[form formRowWithTag:kOTRXLFormXMPPServerTag] value];
    //NSString *jidDomain = serverInfo.domain;
    
    NSString *jidNode = nil;
    NSString *jidDomain = nil;
    
    if (account.username) {
        NSArray *components = [account.username componentsSeparatedByString:@"@"];
        if (components.count == 2) {
            jidNode = [components firstObject];
            jidDomain = [components lastObject];
        } else {
            jidNode = account.username;
            jidDomain = @"secret.me";
        }
        //DDLogError(@"jidNode %@ jidDomain %@", jidNode, jidDomain);
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
    
    //DDLogError(@"OTRXMPPCreateAccountHandler movedValues %@", account);
    
    return account;
}

- (void)performActionWithValidForm:(XLFormDescriptor *)form account:(OTRAccount *)account progress:(void (^)(NSInteger, NSString *))progress completion:(void (^)(OTRAccount * account, NSError *error))completion
{
    if (form) {
        account = (OTRXMPPAccount *)[super moveValues:form intoAccount:(OTRXMPPAccount*)account];
    }
    self.completion = completion;
    [self finishRegisteringWithForm:form account:account];
}

- (void) finishRegisteringWithForm:(XLFormDescriptor *)form account:(OTRAccount *)account {
    [self prepareForXMPPConnectionFrom:form account:(OTRXMPPAccount *)account];
    XLFormRowDescriptor *passwordRow = [form formRowWithTag:kOTRXLFormPasswordTextFieldTag];
    NSString *passwordFromForm = [passwordRow value];
    NSString *password = nil;
    if (passwordRow.sectionDescriptor.isHidden == NO &&
        passwordRow.isHidden == NO &&
        passwordFromForm.length > 0) {
        password = passwordFromForm;
    } else {
        // if no password provided, generate a strong one
        password = [OTRPasswordGenerator passwordWithLength:11];
    }
    account.password = password;
    
    //DDLogError(@"finishRegisteringWithForm %@", account);

    [self.xmppManager startRegisteringNewAccount];
}

@end
