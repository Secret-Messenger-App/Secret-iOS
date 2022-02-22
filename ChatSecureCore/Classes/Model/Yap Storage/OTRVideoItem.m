//
//  OTRVideoItem.m
//  ChatSecure
//
//  Created by David Chiles on 1/26/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRVideoItem.h"
#import "OTRImages.h"
@import YapDatabase;
#import "OTRDatabaseManager.h"
#import "OTRIncomingMessage.h"
#import "OTROutgoingMessage.h"
@import JSQMessagesViewController;
@import PureLayout;
#import "OTRMediaServer.h"
#import "OTRThreadOwner.h"
#import "OTRMediaItem+Private.h"

@import AVFoundation;

@interface OTRVideoItem()
@property (nonatomic) CGFloat width;
@property (nonatomic) CGFloat height;
@end

@implementation OTRVideoItem

- (CGSize) size {
    return CGSizeMake(_width, _height);
}

- (void) setSize:(CGSize)size {
    _width = size.width;
    _height = size.height;
}


- (NSURL *)mediaURL
{
    __block id<OTRMessageProtocol> message = nil;
    __block id<OTRThreadOwner> thread = nil;

    //DDLogInfo(@"mediaURL uiConnection init");

    
    [OTRDatabaseManager.shared.readConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        message = [self parentMessageWithTransaction:transaction];
        thread = [message threadOwnerWithTransaction:transaction];
    }];
    
    if (!message || !thread) {
        //DDLogError(@"Missing parent message or thread for media message!");
        return nil;
    }
    
    NSString *buddyUniqueId = [thread threadIdentifier];
    
    //DDLogInfo(@"buddyUniqueId = %@", buddyUniqueId);
    
    return [[OTRMediaServer sharedInstance] urlForMediaItem:self buddyUniqueId:buddyUniqueId];
}

- (CGSize)mediaViewDisplaySize
{
    if (self.height && self.width) {
        return [[self class] normalizeWidth:self.width height:self.height];
    }
    return [super mediaViewDisplaySize];
}

- (BOOL) shouldFetchMediaData {
    return ![OTRImages imageWithIdentifier:self.uniqueId];
}

- (void) fetchMediaData {
    if (![self shouldFetchMediaData]) {
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        AVURLAsset *asset = [AVURLAsset assetWithURL:[self mediaURL]];
        AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
        imageGenerator.appliesPreferredTrackTransform = YES;
        NSError *error = nil;
        //Grab middle frame
        CMTime time = CMTimeMultiplyByFloat64(asset.duration, 0.5);
        CGImageRef imageRef = [imageGenerator copyCGImageAtTime:time actualTime:NULL error:&error];
        UIImage *image = [UIImage imageWithCGImage:imageRef];
        CGImageRelease(imageRef);
        if (image && !error) {
            [OTRImages setImage:image forIdentifier:self.uniqueId];
            [[OTRDatabaseManager sharedInstance].writeConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
                [self touchParentMessageWithTransaction:transaction];
            }];
        }
    });
}

- (UIView *)mediaView
{
    UIView *errorView = [self errorView];
    if (errorView) { return errorView; }
    UIImage *image = [OTRImages imageWithIdentifier:self.uniqueId];
    if (!image) {
        [self fetchMediaData];
        return nil;
    }
    CGSize size = [self mediaViewDisplaySize];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.frame = CGRectMake(0, 0, size.width, size.height);
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.layer.cornerRadius = 15.0f;
    imageView.clipsToBounds = YES;
    
    //[JSQMessagesMediaViewBubbleImageMasker applyBubbleImageMaskToMediaView:imageView isOutgoing:!self.isIncoming];
    
    UIImage *playIcon = [[UIImage jsq_defaultPlayImage] jsq_imageMaskedWithColor:[UIColor lightGrayColor]];
    UIImageView *playImageView = [[UIImageView alloc] initWithImage:playIcon];
    playImageView.backgroundColor = [UIColor clearColor];
    playImageView.contentMode = UIViewContentModeCenter;
    playImageView.clipsToBounds = YES;
    playImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [imageView addSubview:playImageView];
    [playImageView autoCenterInSuperview];
    
    return imageView;
}

/** If mimeType is not provided, it will be guessed from filename */
- (instancetype) initWithVideoURL:(NSURL*)url
                       isIncoming:(BOOL)isIncoming {
    NSParameterAssert(url);
    if (self = [super initWithFilename:url.lastPathComponent mimeType:nil isIncoming:isIncoming]) {
        AVURLAsset *asset = [AVURLAsset assetWithURL:url];
        AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
        CGSize videoSize = videoTrack.naturalSize;
        
        CGAffineTransform transform = videoTrack.preferredTransform;
        if ((videoSize.width == transform.tx && videoSize.height == transform.ty) || (transform.tx == 0 && transform.ty == 0))
        {
            _width = videoSize.width;
            _height = videoSize.height;
        }
        else
        {
            _width = videoSize.height;
            _height = videoSize.width;
        }
    }
    return self;
}

+ (NSString *)collection
{
    return [OTRMediaItem collection];
}

@end
