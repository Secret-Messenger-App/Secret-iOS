//
//  OTRTitleSubtitleView.m
//
//  Copyright (c) 2021 Secret, Inc. All rights reserved.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
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

#import "OTRTitleSubtitleView.h"

@import PureLayout;

#import "ChatSecureCoreCompat-Swift.h"

#import "OTRUtilities.h"

@interface OTRTitleSubtitleView ()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;

@property (nonatomic, strong) UIImageView *titleImageView;
@property (nonatomic, strong) UIImageView *subtitleImageView;

@property (nonatomic) BOOL addedConstraints;

@end

@implementation OTRTitleSubtitleView

- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.addedConstraints = NO;
        self.backgroundColor = [UIColor clearColor];
        //self.autoresizesSubviews = YES;
        
        self.titleLabel = [[UILabel alloc] initForAutoLayout];
        self.titleLabel.backgroundColor = [UIColor clearColor];
        self.titleLabel.textColor = [GlobalTheme.shared labelColor];
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.font = [UIFont boldSystemFontOfSize:17];
        //self.titleLabel.adjustsFontSizeToFitWidth = YES;
        
        self.subtitleLabel = [[UILabel alloc] initForAutoLayout];
        self.subtitleLabel.backgroundColor = [UIColor clearColor];
        self.subtitleLabel.textColor = [GlobalTheme.shared secondaryLabelColor];
        self.subtitleLabel.textAlignment = NSTextAlignmentCenter;
        self.subtitleLabel.font = [UIFont systemFontOfSize:12];
        //self.subtitleLabel.adjustsFontSizeToFitWidth = YES;
        
        [self addSubview:self.titleLabel];
        [self addSubview:self.subtitleLabel];
        
        [self updateConstraints];
    }
    return self;
}

- (void) updateConstraints
{
    if (!self.addedConstraints) {
        [self setupContraints];
        self.addedConstraints = YES;
    }
    [super updateConstraints];
}

- (void) setupContraints
{
    [self.titleLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeTop];
    //[self.titleLabel autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:0.6];
    //[self.titleLabel autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:0.9 relation:NSLayoutRelationLessThanOrEqual];
    
    [self.subtitleLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [self.subtitleLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom];
    [self.subtitleLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.titleLabel]; //  withOffset:1
}

@end
