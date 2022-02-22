//
//  PTEConsoleTableViewController.h
//  LumberjackConsole
//
//  Created by Ernesto Rivera on 2014/04/09.
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

@class PTEConsoleTableView;
@class PTEConsoleLogger;

NS_ASSUME_NONNULL_BEGIN
@interface PTEConsoleTableViewController : UIViewController

/// The logger that will also officiate as the table view's delegate, data source and
/// search bar delegate.
@property (nonatomic, nullable) PTEConsoleLogger * logger;


/// @name Actions

/// Clear all console messages.
/// @param sender The sender object.
- (IBAction)clearConsole:(id)sender;

/// Add a marker object to the console.
/// @param sender The sender object.
- (IBAction)addMarker:(id)sender;

@end
NS_ASSUME_NONNULL_END
