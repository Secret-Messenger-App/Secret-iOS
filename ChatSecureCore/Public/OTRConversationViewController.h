//
//  OTRConversationViewController.h
//
//  Copyright (c) 2021 Secret, Inc. All rights reserved.
//  Copyright (c) 2014 David Chiles. All rights reserved.
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

@import UIKit;

#import "OTRThreadOwner.h"

@class OTRBuddy;
@class OTRConversationViewController;

@protocol OTRConversationViewControllerDelegate <NSObject>

- (void)conversationViewController:(OTRConversationViewController *)conversationViewController didSelectThread:(id <OTRThreadOwner>)threadOwner;
- (void)conversationViewController:(OTRConversationViewController *)conversationViewController didSelectCompose:(id)sender;

@end

/**
 The puropose of this class is to list all curent conversations (with single buddy or group chats) in a list view.
 When the user selects a conversation to enter the delegate method fires.
 */
@interface OTRConversationViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) id <OTRConversationViewControllerDelegate> delegate;

@property (nonatomic, strong) UITableView *tableView;

@end
