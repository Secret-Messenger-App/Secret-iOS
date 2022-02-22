//
//  OTRBuddyInfoCell.m
//  Off the Record
//
//  Created by David Chiles on 3/4/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRBuddyInfoCell.h"

@import OTRAssets;
@import PureLayout;
@import FormatterKit;

#import <ChatSecureCore/ChatSecureCore-Swift.h>

#import "OTRDatabaseManager.h"

#import "OTRBuddy.h"
#import "OTRBuddyCache.h"
#import "OTRAccount.h"
#import "OTRXMPPBuddy.h"

const CGFloat OTRBuddyInfoCellHeight = 80.0;

@interface OTRBuddyInfoCell ()

@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *identifierLabel;
@property (nonatomic, strong) UILabel *accountLabel;

@end

@implementation OTRBuddyInfoCell

- (id) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        self.nameLabel = [[UILabel alloc] initForAutoLayout];
        self.nameLabel.font = [UIFont boldSystemFontOfSize:17];
        self.nameLabel.textColor = [GlobalTheme.shared labelColor];
        self.nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        
        self.identifierLabel = [[UILabel alloc] initForAutoLayout];
        self.identifierLabel.font = [UIFont systemFontOfSize:15];
        self.identifierLabel.textColor = [GlobalTheme.shared secondaryLabelColor];
        self.identifierLabel.translatesAutoresizingMaskIntoConstraints = NO;
        
        self.accountLabel = [[UILabel alloc] initForAutoLayout];
        self.accountLabel.font = [UIFont fontWithName:@"FontAwesome" size:15];
        self.accountLabel.textColor = [GlobalTheme.shared secondaryLabelColor];
        self.accountLabel.translatesAutoresizingMaskIntoConstraints = NO;

        NSArray<UILabel*> *labels = @[self.nameLabel, self.identifierLabel, self.accountLabel];
        [labels enumerateObjectsUsingBlock:^(UILabel * _Nonnull label, NSUInteger idx, BOOL * _Nonnull stop) {
            //label.adjustsFontSizeToFitWidth = YES;
            [self.contentView addSubview:label];
        }];
        _infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
        [self.infoButton addTarget:self action:@selector(infoButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

- (void) setThread:(id<OTRThreadOwner>)thread
{
    [self setThread:thread account:nil];
}

- (void) setThread:(id<OTRThreadOwner>)thread account:(nullable OTRAccount*)account
{
    [super setThread:thread];
    
    NSString * name = [thread threadName];
    //NSString * nameString = [NSString stringWithFormat:@"%@ %@",[NSString fa_stringForFontAwesomeIcon:FALock],[thread threadName]];
    
    self.nameLabel.text = name;
    //self.accountLabel.text = account.username;
    
    NSString *identifier = nil;
    if ([thread isKindOfClass:[OTRBuddy class]]) {
        OTRBuddy *buddy = (OTRBuddy*)thread;
        identifier = buddy.nickName;
/*
        NSDate *lastSeen = [OTRBuddyCache.shared lastSeenDateForBuddy:buddy];
        OTRThreadStatus status = [OTRBuddyCache.shared threadStatusForBuddy:buddy];
        if (lastSeen) {

            TTTTimeIntervalFormatter *tf = [[TTTTimeIntervalFormatter alloc] init];
            tf.presentTimeIntervalMargin = 60;
            tf.usesAbbreviatedCalendarUnits = YES;
            NSTimeInterval lastSeenInterval = [lastSeen timeIntervalSinceDate:[NSDate date]];
            NSString *labelString = nil;
            if (status == OTRThreadStatusAvailable) {
                labelString = @"Подключен";
            } else {
                labelString = [NSString stringWithFormat:@"%@", [tf stringForTimeInterval:lastSeenInterval]];
            }
        }
*/
    } else if ([thread isGroupThread]) {
        identifier = [thread threadName];
    }
    
    self.identifierLabel.text = identifier;
    
    /*
    UIColor *textColor = [UIColor darkTextColor];
    if ([thread isArchived]) {
        textColor = [UIColor lightGrayColor];
    }
    [@[self.nameLabel, self.identifierLabel] enumerateObjectsUsingBlock:^(UILabel   * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.textColor = textColor;
    }];
    */
}

- (void) updateConstraints
{
    if (self.addedConstraints) {
        [super updateConstraints];
        return;
    }
    NSArray<UILabel*> *textLabelsArray = @[self.nameLabel,self.identifierLabel];
    
    //same horizontal contraints for all labels
    for(UILabel *label in textLabelsArray) {
        [label autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.avatarImageView withOffset:OTRBuddyImageCellPadding];
        [label autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:OTRBuddyImageCellPadding relation:NSLayoutRelationGreaterThanOrEqual];
    }
    
    [self.nameLabel autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:OTRBuddyImageCellPadding+5];
    [self.identifierLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:OTRBuddyImageCellPadding+5];
    
    //[self.accountLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.nameLabel withOffset:3];
    
    [super updateConstraints];
}

- (void) prepareForReuse
{
    [super prepareForReuse];
    /*
    self.nameLabel.textColor = [UIColor blackColor];
    self.identifierLabel.textColor = [UIColor darkTextColor];
    self.accountLabel.textColor = [UIColor lightGrayColor];
    */
}

- (void) infoButtonPressed:(UIButton*)sender
{
    if (!self.infoAction) {
        return;
    }
    self.infoAction(self, sender);
}

@end
