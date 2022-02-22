//
//  OTRMessagesViewController.h
//
//  Copyright (c) 2021 Secret, Inc. All rights reserved.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
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

@import JSQMessagesViewController;
@import UIKit;

#import "OTRBuddy.h"
#import "OTROutgoingMessage.h"

@class OTRBuddy, OTRXMPPManager, OTRXMPPRoom, OTRXMPPAccount, YapDatabaseConnection, OTRYapDatabaseObject, MessagesViewControllerState, DatabaseConnections;
@class SupplementaryViewHandler;

@protocol OTRThreadOwner,OTRMessageProtocol,JSQMessageData;

@protocol OTRMessagesViewControllerProtocol <NSObject>

- (void)receivedTextViewChangedNotification:( NSNotification * _Nonnull )notification;
- (void)didUpdateState;

@end

@interface OTRMessagesViewController : JSQMessagesViewController <OTRMessagesViewControllerProtocol, UIPopoverPresentationControllerDelegate>

@property (nonatomic, readonly, nullable) SupplementaryViewHandler *supplementaryViewHandler;
@property (nonatomic, readonly, nullable) DatabaseConnections *connections;
@property (nonatomic, strong, readonly, nullable) YapDatabaseConnection *uiConnection DEPRECATED_MSG_ATTRIBUTE("Use connections.ui instead");
@property (nonatomic, strong, readonly, nullable) YapDatabaseConnection *readConnection DEPRECATED_MSG_ATTRIBUTE("Use connections.read instead");
@property (nonatomic, strong, readonly, nullable) YapDatabaseConnection *writeConnection DEPRECATED_MSG_ATTRIBUTE("Use connections.write instead");

@property (nonatomic, strong, nullable) NSString *threadKey;
@property (nonatomic, strong, nullable) NSString *threadCollection;
@property (nonatomic, strong, nullable) UIButton *microphoneButton;
@property (nonatomic, strong, nullable) UIButton *sendButton;
@property (nonatomic, strong, nullable) UIButton *cameraButton;

@property (nonatomic, strong, nonnull, readonly) MessagesViewControllerState *state;
@property (nonatomic) BOOL automaticURLFetchingDisabled;

- (nullable id<OTRMessageProtocol,JSQMessageData>)messageAtIndexPath:(nonnull NSIndexPath *)indexPath;
- (nullable id<OTRThreadOwner>)threadObjectWithTransaction:(nonnull YapDatabaseReadTransaction *)transaction;
- (nullable OTRXMPPAccount *)accountWithTransaction:(nonnull YapDatabaseReadTransaction *)transaction;
- (nullable OTRXMPPManager *)xmppManagerWithTransaction:(nonnull YapDatabaseReadTransaction *)transaction;
- (nullable OTRXMPPRoom *)roomWithTransaction:(nonnull YapDatabaseReadTransaction *)transaction;
- (nullable NSAttributedString*) deliveryStatusStringForMessage:(nonnull id<OTRMessageProtocol>)message;
- (nullable NSAttributedString *) encryptionStatusStringForMessage:(nonnull id<OTRMessageProtocol>)message;

- (void)setThreadKey:(nullable NSString *)key collection:(nullable NSString *)collection;
- (void)setupWithBuddies:(nonnull NSArray<NSString *> *)buddies accountId:(nonnull NSString *)accountId name:(nullable NSString *)name;
- (void)updateEncryptionState;
- (void)sendAudioFileURL:(nonnull NSURL *)url;
- (void)sendImageFilePath:(nonnull NSString *)filePath asJPEG:(BOOL)asJPEG shouldResize:(BOOL)shouldResize;
- (void)infoButtonPressed:(nullable id)sender;
- (void)newDeviceButtonPressed:(nonnull NSString *)buddyUniqueId;
- (void)didFinishTyping;
- (void)isTyping;
- (BOOL)isGroupChat;

@end
