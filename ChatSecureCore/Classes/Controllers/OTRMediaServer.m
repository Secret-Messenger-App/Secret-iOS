//
//  OTRMediaServer.m
//  ChatSecure
//
//  Created by David Chiles on 2/24/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRMediaServer.h"
@import GCDWebServer;
@import IOCipher;
#import "OTRMediaFileManager.h"
#import "OTRLog.h"

@interface OTRMediaServer ()

@property (nonatomic, strong) GCDWebServer *webServer;

@end

@implementation OTRMediaServer


- (instancetype)init{
    if (self = [super init]) {
        self.webServer = [[GCDWebServer alloc] init];
        [GCDWebServer setLogLevel:0];
    }
    return self;
}

- (IOCipher *)ioCipher
{
    return [OTRMediaFileManager sharedInstance].ioCipher;
}

- (BOOL)startOnPort:(NSUInteger)port error:(NSError **)error
{
    __weak typeof(self)weakSelf = self;
    [self.webServer addHandlerForMethod:@"GET"
                              pathRegex:[NSString stringWithFormat:@"/%@/.*",kOTRRootMediaDirectory]
                           requestClass:[GCDWebServerRequest class]
                      asyncProcessBlock:^(GCDWebServerRequest *request, GCDWebServerCompletionBlock completionBlock) {
                          __strong typeof(weakSelf)strongSelf = weakSelf;
                          [strongSelf handleMediaRequest:request completion:completionBlock];
                      }];
    return [self.webServer startWithOptions:@{GCDWebServerOption_BindToLocalhost: @(YES),
                                              GCDWebServerOption_AutomaticallySuspendInBackground : @(NO),
                                              //GCDWebServerOption_ConnectedStateCoalescingInterval : @(5.0)
                                              
    }
                                      error:error];
    
}

- (void)handleMediaRequest:(GCDWebServerRequest *)request completion:(GCDWebServerCompletionBlock)completionBlock
{
    if (completionBlock) {
        GCDWebServerVirtualFileResponse *virtualFileResponse = [GCDWebServerVirtualFileResponse responseWithFile:request.path
                                                                                                       byteRange:request.byteRange
                                                                                                    isAttachment:NO
                                                                                                        ioCipher:[self ioCipher]];
        
        //DDLogError(@"request.contentLength: %lu", (unsigned long)request.contentLength);
        
        [virtualFileResponse setValue:@"bytes" forAdditionalHeader:@"Accept-Ranges"];
        completionBlock(virtualFileResponse);
    }
}

- (NSURL *)urlForMediaItem:(OTRMediaItem *)mediaItem buddyUniqueId:(NSString *)buddyUniqueId
{
    NSString *itemPath = [OTRMediaFileManager pathForMediaItem:mediaItem buddyUniqueId:buddyUniqueId withLeadingSlash:NO];
    NSURL *url = [self.webServer serverURL];
    url = [url URLByAppendingPathComponent:itemPath];
    return url;
}

- (BOOL)isStarted
{
    if (self.webServer.serverURL && self.webServer.port) {
        return YES;
    }
    return NO;
}

- (void)stop
{
    [self.webServer stop];
}

#pragma - mark Class Methods

+ (instancetype)sharedInstance
{
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

@end
