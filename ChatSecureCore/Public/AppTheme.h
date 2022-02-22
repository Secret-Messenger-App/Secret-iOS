//
//  AppTheme.h
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

@import Foundation;
@import UIKit;

@class OTRAccount;
@class OTRXMPPAccount;
@class OTRXMPPBuddy;
@class OTRXMPPManager;

NS_ASSUME_NONNULL_BEGIN

@protocol ViewControllerFactory
@required
/** Returns new instance. Override this in subclass to use a different conversation view controller class */
- (__kindof UIViewController*) conversationViewController;

/** Returns new instance. Override this in subclass to use a different message view controller class */
- (__kindof UIViewController *) messagesViewController;

/** Returns new instance. Override this in subclass to use a different settings view controller class */
- (__kindof UIViewController *) settingsViewController;

/** Returns new instance. Override this in subclass to use a different compose view controller class */
- (__kindof UIViewController *) composeViewController;

/** Returns new instance. Override this in subclass to use a different invite view controller class */
- (__kindof UIViewController* ) inviteViewControllerForAccount:(OTRAccount*)account NS_SWIFT_NAME(inviteViewController(account:));

/** This is the view for managing all of your own keys (OMEMO & OTR)*/
- (__kindof UIViewController* ) keyManagementViewControllerForAccount:(OTRXMPPAccount*)account NS_SWIFT_NAME(keyManagementViewController(account:));

/** This is "profile view" for managing all of the keys (OMEMO & OTR) of a single buddy, in the context of a 1:1 conversation. */
- (__kindof UIViewController* ) keyManagementViewControllerForBuddy:(OTRXMPPBuddy*)buddy NS_SWIFT_NAME(keyManagementViewController(buddy:));

/** This for managing all of the OMEMO keys of multiple buddies, in the context of a group conversation. Note: All buddies should be associated with the same account. */
- (__kindof UIViewController* ) groupKeyManagementViewControllerForBuddies:(NSArray<OTRXMPPBuddy*>*)buddies NS_SWIFT_NAME(groupKeyManagementViewController(buddies:));

/** This is shown whenever a new untrusted OMEMO or OTR key is found, so a user can mark the new key(s) as trusted/untrusted. Note: All buddies should be associated with the same account. */
- (__kindof UIViewController* ) newUntrustedKeyViewControllerForBuddies:(NSArray<OTRXMPPBuddy*>*)buddies NS_SWIFT_NAME(newUntrustedKeyViewController(buddies:));

/** Returns new instance. Override this in subclass to use a different account detail view controller class */
- (__kindof UIViewController* ) accountDetailViewControllerForAccount:(OTRXMPPAccount*)account NS_SWIFT_NAME(accountDetailViewController(account:));

@end

@protocol AppAppearance
@required
- (void) setupAppearance;
@end

@protocol AppColors
@required
@property (nonatomic, strong, readonly) UIColor *labelColor;
@property (nonatomic, strong, readonly) UIColor *secondaryLabelColor;
@end

@protocol AppTheme<AppAppearance, ViewControllerFactory, AppColors>
@required
@end

NS_ASSUME_NONNULL_END
