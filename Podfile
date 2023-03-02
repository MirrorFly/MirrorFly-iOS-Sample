platform :ios, '12.1'

workspace 'MirrorflyUIkit.xcworkspace'

use_frameworks!

def uikit_pods

  pod 'PhoneNumberKit', '~> 3.3'
  pod 'Alamofire'
  pod 'XMPPFramework/Swift'
  pod 'Toaster'
  pod 'IQKeyboardManagerSwift'
  pod 'Firebase/Auth'
  pod 'Firebase/Crashlytics'
  pod 'Firebase/Analytics'
  pod 'Firebase/Messaging'
  pod 'SDWebImage'
  pod 'GrowingTextViewHandler-Swift', '1.2'
  pod "BSImagePicker", "~> 3.1"
  pod 'libPhoneNumber-iOS'
  pod 'GoogleMaps'
  pod 'Tatsi'
  pod 'QCropper'
  pod 'KMPlaceholderTextView', '~> 1.4.0'
  pod 'NicoProgress'
  pod 'Firebase/RemoteConfig'
  pod 'SocketRocket'
  pod 'Socket.IO-Client-Swift', '~> 15.2.0' # To communicte Socket I/O server
  pod 'GoogleWebRTC' # WebRTC for Calls
  pod 'Floaty', '~> 4.2.0'
  pod "PulsingHalo"
  pod 'MenuItemKit', '~> 4.0.0'
  pod 'RealmSwift', '10.20.1'
  pod 'MarqueeLabel'
  pod 'RxSwift', '6.5.0'
  pod 'RxCocoa', '6.5.0'
  pod 'SwiftLinkPreview'


end

def notification_pods

  pod 'libPhoneNumber-iOS'
  pod 'Alamofire'
  pod 'SocketRocket'
  pod 'Socket.IO-Client-Swift' , '~> 15.2.0' # To communicte Socket I/O server
  pod 'GoogleWebRTC' # WebRTC for Calls
  pod 'XMPPFramework/Swift'
  pod 'RealmSwift', '10.20.1'
end

target 'UiKitQa' do
  uikit_pods
end

target 'UiKitQaNotificationExtention' do
  notification_pods
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.1'
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      config.build_settings['APPLICATION_EXTENSION_API_ONLY'] = 'No'
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
    end
  end
end
