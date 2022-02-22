//
//  ChatSecureCore.h
//
//  Copyright (c) 2021 Secret, Inc. All rights reserved.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
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

@import UIKit;

FOUNDATION_EXPORT double ChatSecureCoreVersionNumber;
FOUNDATION_EXPORT const unsigned char ChatSecureCoreVersionString[];

#import "AppTheme.h"

#import "OTRAppDelegate.h"
#import "OTRConstants.h"

#import "OTRDatabaseManager.h"
#import "OTREncryptionManager.h"
#import "OTRProtocolManager.h"
#import "OTRXMPPManager.h"

#import "OTRAccountMigrationViewController.h"
#import "OTRInviteViewController.h"
#import "OTRBaseLoginViewController.h"
#import "OTRChooseAccountViewController.h"
#import "OTRComposeViewController.h"
#import "OTRConversationViewController.h"
#import "OTRDatabaseUnlockViewController.h"
#import "OTRLanguageListSettingViewController.h"
#import "OTRListSettingViewController.h"
#import "OTRMessagesViewController.h"
#import "OTRMessagesHoldTalkViewController.h"
#import "OTRNewBuddyViewController.h"
#import "OTRSettingsViewController.h"
#import "OTRSettingDetailViewController.h"

#import "OTRAccount.h"
#import "OTRAccountMigrator.h"
#import "OTRAttachmentPicker.h"
#import "OTRActivityItemProvider.h"
#import "OTRBuddyCache.h"
#import "OTRBuddy.h"
#import "OTRBuddyApprovalCell.h"
#import "OTRBuddyInfoCell.h"
#import "OTRCertificatePinning.h"
#import "OTRDatabaseView.h"
#import "OTRDownloadMessage.h"
#import "OTRImages.h"
#import "OTRIncomingMessage.h"
#import "OTRMessage.h"
#import "OTRMessageEncryptionInfo.h"
#import "OTRLanguageSetting.h"
#import "OTRListSetting.h"
#import "OTROutgoingMessage.h"
#import "OTRPasswordGenerator.h"
#import "OTRQRCodeActivity.h"
#import "OTRQRCodeReaderDelegate.h"
#import "OTRServerCapabilities.h"
#import "OTRSettingsGroup.h"
#import "OTRShareSetting.h"
#import "OTRTitleSubtitleView.h"
#import "OTRThreadOwner.h"
#import "OTRUserInfoProfile.h"
#import "OTRValueSetting.h"
#import "OTRXLFormCreator.h"
#import "OTRXMPPBuddy.h"
#import "OTRXMPPCreateAccountHandler.h"
#import "OTRXMPPError.h"
#import "OTRXMPPRoomManager.h"
#import "OTRXMPPServerInfo.h"
#import "OTRYapMessageSendAction.h"

// Media
#import "OTRAudioItem.h"
#import "OTRImageItem.h"
#import "OTRMediaItem.h"
#import "OTRVideoItem.h"

// Complex
#import "NSURL+ChatSecure.h"
#import "NSString+ChatSecure.h"
#import "UIImage+ChatSecure.h"
#import "YapDatabaseViewConnection+ChatSecure.h"

// Signal
#import "OTRAccountSignalIdentity.h"
#import "OTRSignalSenderKey.h"
#import "OTRSignalPreKey.h"
#import "OTRSignalSignedPreKey.h"
#import "OTRSignalSession.h"

// OMEMO
#import "OMEMODevice.h"

// MUC
#import "RoomOccupantRole.h"
