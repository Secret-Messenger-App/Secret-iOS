platform :ios, "12.0"

install! 'cocoapods', :deterministic_uuids => false, :disable_input_output_paths => true

use_modular_headers!
inhibit_all_warnings!

source 'https://cdn.cocoapods.org/'

workspace 'Secret.xcworkspace'
project 'Secret.xcodeproj', 'iOS_Debug' => :debug, 'macOS_Debug' => :debug, 'iOS_Release' => :release, 'macOS_Release' => :release

abstract_target 'ChatSecureCorePods' do  

  pod 'SmileLock', :git => 'https://github.com/recruit-lifestyle/Smile-Lock.git', :branch => 'master'
  pod 'ZXingObjC/QRCode', :git => 'https://github.com/ChatSecure/ZXingObjC.git', :branch => 'fix-catalyst'
  pod 'SQLCipher', :git => 'https://github.com/ChatSecure/sqlcipher.git', :branch => 'v4.3.0-catalyst'
  pod 'ParkedTextField', :git => 'https://github.com/gmertk/ParkedTextField.git', :commit => 'a3800e3'
  pod 'JSQMessagesViewController', :path => 'Submodules/JSQMessagesViewController/JSQMessagesViewController.podspec'
  pod 'LumberjackConsole', :path => 'Submodules/LumberjackConsole/LumberjackConsole.podspec'
  pod 'XMPPFramework/Swift', :path => 'Submodules/XMPPFramework/XMPPFramework.podspec'
  pod 'YapDatabase/SQLCipher', :path => 'Submodules/YapDatabase/YapDatabase.podspec'
  pod 'libsqlfs/SQLCipher', :path => 'Submodules/libsqlfs/libsqlfs.podspec'
  pod 'IOCipher/GCDWebServer', :path => 'Submodules/IOCipher/IOCipher.podspec'
  pod 'YapTaskQueue/SQLCipher', :path => 'Submodules/YapTaskQueue/YapTaskQueue.podspec'
  pod 'SignalProtocolObjC', :path => 'Submodules/SignalProtocol-ObjC/SignalProtocolObjC.podspec'
  pod 'ChatSecure-Push-iOS', :path => 'Submodules/ChatSecure-Push-iOS/ChatSecure-Push-iOS.podspec'
  pod 'ChatSecureCore', :path => 'ChatSecureCore.podspec'
  pod 'OTRAssets', :path => 'OTRAssets.podspec'
  pod 'OTRKit', :path => 'Submodules/OTRKit/OTRKit.podspec'

  target 'Secret'
  target 'ChatSecureCore'
end

post_install do |installer|
  installer.generated_projects.each do |project|
    project.build_configurations.each do |config|
        fix_config(config)
    end
    project.targets.each do |target|
      target.build_configurations.each do |config|
        fix_config(config)
      end
    end
  end
end