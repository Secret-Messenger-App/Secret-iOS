//
//  OTRXMPPManager_Private.h
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

#import "OTRXMPPManager.h"

@import XMPPFramework;

#import "ChatSecureCoreCompat-Swift.h"

#import "OTRXMPPBuddyManager.h"
#import "OTRXMPPRoomManager.h"
#import "OTRXMPPBuddyTimers.h"
#import "OTRCertificatePinning.h"
#import "ProxyXMPPStream.h"

NS_ASSUME_NONNULL_BEGIN
@interface OTRXMPPManager() <OTRCertificatePinningDelegate>

@property (nonatomic, strong, readonly) XMPPStream *xmppStream;
@property (nonatomic, strong, readonly) XMPPReconnect *xmppReconnect;
@property (nonatomic, strong, readonly) XMPPvCardTempModule *xmppvCardTempModule;
@property (nonatomic, strong, readonly) XMPPvCardAvatarModule *xmppvCardAvatarModule;
@property (nonatomic, strong, readonly) RosterStorage * xmppRosterStorage;
@property (nonatomic, strong) OTRCertificatePinning * certificatePinningModule;

@property (nonatomic, strong, readonly) XMPPStreamManagement *streamManagement;

@property (nonatomic, strong, readonly) OTRXMPPBuddyManager* xmppBuddyManager;
@property (nonatomic, strong, readonly) OMEMOModule *omemoModule;
@property (nonatomic, strong, nullable) OTRXMPPChangePasswordManager *changePasswordManager;

@property (nonatomic, strong, readonly) XMPPMessageDeliveryReceipts *deliveryReceipts;
@property (nonatomic, strong, readonly) OTRXMPPMessageStatusModule *messageStatusModule;
@property (nonatomic, strong, readonly) OTRStreamManagementDelegate *streamManagementDelegate;
@property (nonatomic, strong, readonly) XMPPStanzaIdModule *stanzaIdModule;
/// This is a readwrite connection
@property (nonatomic, strong, readonly) YapDatabaseConnection *databaseConnection;

@property (nonatomic, strong, readonly) dispatch_queue_t workQueue;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString*,OTRXMPPBuddyTimers*> * buddyTimers;

@property (nonatomic, strong, nullable) OTRXMPPChangeAvatar *changeAvatar;

@property (nonatomic, readwrite) BOOL isRegisteringNewAccount;
@property (nonatomic, readwrite) BOOL userInitiatedConnection;
@property (atomic, readwrite) OTRLoginStatus loginStatus;

- (void)setupStream;
- (void)teardownStream;

- (void)goOnline;
- (void)goOffline;
- (void)failedToConnect:(NSError *)error;

/** wtf. why isn't this being picked up by OTRProtocol */
- (void) connectUserInitiated:(BOOL)userInitiated;

/** Return a newly allocated stream object. This is overridden in OTRXMPPTorManager to use ProxyXMPPStream instead of XMPPStream */
- (XMPPStream*) newStream;
- (ProxyXMPPStream*) newProxyStream;

@end
NS_ASSUME_NONNULL_END
