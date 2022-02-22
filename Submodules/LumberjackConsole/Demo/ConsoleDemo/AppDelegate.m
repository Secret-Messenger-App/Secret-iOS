//
//  AppDelegate.m
//  ConsoleDemo
//
//  Created by Ernesto Rivera on 2013/11/13.
//  Copyright (c) 2013-2017 PTEz.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "AppDelegate.h"
#import <CocoaLumberjack/CocoaLumberjack.h>
#import <LumberjackConsole/PTEDashboard.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#ifndef PRODUCTION
    // Add the console dashboard for testing builds
    [PTEDashboard.sharedDashboard show];
    
    DDLogInfo(@"Added console dashboard");
#endif
    
    return YES;
}

- (void)adjust
{
    PTEDashboard.sharedDashboard.windowLevel += 100;
    NSLog(@"%@ ", @(PTEDashboard.sharedDashboard.windowLevel));
}

@end

