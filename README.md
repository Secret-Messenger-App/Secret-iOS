# [Secret Messenger for iOS](https://github.com/Secret-Messenger-App/Secret-iOS)

[![Build Status](https://app.travis-ci.com/secret-msg/secret-messenger-ios.svg?branch=master)](https://app.travis-ci.com/secret-msg/secret-messenger-ios)

[Secret Messenger](https://www.secret.me) is a free and open source Jabber ([XMPP](https://en.wikipedia.org/wiki/XMPP)) messaging client for Apple and Android devices focused on Privacy and Security with full [OMEMO](https://en.wikipedia.org/wiki/OMEMO) encrypted messaging support. 

Secret app is available for iOS and iPadOS, with the abilty to run on the new M1 Macs.

Download the latest version of Secret Messenger app from the Apple App Store:

[![download secret messenger on the app store](https://www.secret.me/images/appstore.svg)](https://apps.apple.com/us/app/secret-private-messenger/id1438306682)

## Build Instructions

You should use the latest stable version of Xcode to build Secret.

### 1. Install [CocoaPods](http://cocoapods.org) for the dependencies:
    
    gem install cocoapods
    
### 2. Download the source code and the submodules:

    git clone https://github.com/Secret-Messenger-App/Secret-iOS && cd Secret-iOS
    git submodule update --init --recursive
    
### 3. Build the dependencies:
    
    ./Submodules/CPAProxy/scripts/build-all.sh
    ./Submodules/OTRKit/scripts/build-all.sh
    
    pod repo update
    pod install
    
### 4. Set up your developer profile:

Manually change the Team ID under Project -> Targets -> Secret -> Signing.

### 5. Open `Secret.xcworkspace` in Xcode and build:

    open Secret.xcworkspace

## License
	
Licensed under GPLv3

Copyright (c) 2022, Secret Messenger Developers
