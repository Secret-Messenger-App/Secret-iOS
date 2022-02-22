//
//  OTRProtocolManager.h
//
//  Copyright (c) 2021 Secret, Inc. All rights reserved.
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

@import Foundation;
@import XMPPFramework;

#import "OTRProtocol.h"

#import "OTRAccountsManager.h"
#import "OTREncryptionManager.h"
#import "OTRSettingsManager.h"

@class OTRAccount, OTRXMPPAccount, OTRBuddy, OTROutgoingMessage, PushController, OTRXMPPManager;

NS_ASSUME_NONNULL_BEGIN
@interface OTRProtocolManager : NSObject

@property (atomic, readonly) NSUInteger numberOfConnectedProtocols;
@property (atomic, readonly) NSUInteger numberOfConnectingProtocols;

- (nullable id <OTRProtocol>)protocolForAccount:(OTRAccount *)account;
- (nullable OTRXMPPManager*)xmppManagerForAccount:(OTRAccount *)account;
- (void)setProtocol:(id <OTRProtocol>)protocol forAccount:(OTRAccount *)account;
- (void)removeProtocolForAccount:(OTRAccount *)account;
- (BOOL)existsProtocolForAccount:(OTRAccount *)account;
- (BOOL)isAccountConnected:(OTRAccount *)account;

- (void)loginAccount:(OTRAccount *)account;
- (void)loginAccount:(OTRAccount *)account userInitiated:(BOOL)userInitiated;
- (void)loginAccounts:(NSArray<OTRAccount*> *)accounts;
- (void)goAwayForAllAccounts;
- (void)disconnectAllAccounts;
- (void)disconnectAllAccountsSocketOnly:(BOOL)socketOnly timeout:(NSTimeInterval)timeout completionBlock:(nullable void (^)())completionBlock;
+ (void)handleInviteForJID:(XMPPJID *)jid otrFingerprint:(nullable NSString *)otrFingerprint buddyAddedCallback:(nullable void (^)(OTRBuddy *buddy))buddyAddedCallback;
- (void)sendMessage:(OTROutgoingMessage *)message;

+ (instancetype)sharedInstance;

@property (class, nonatomic, readonly) OTRProtocolManager *shared;

@end
NS_ASSUME_NONNULL_END
