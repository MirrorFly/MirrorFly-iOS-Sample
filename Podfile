platform :ios, '12.1'

workspace 'MirrorflyUIkit.xcworkspace'

use_frameworks!

def uikit_pods

  pod 'PhoneNumberKit', '~> 3.3'
  pod 'Toaster'
  pod 'IQKeyboardManagerSwift'
  pod 'Firebase/Auth'
  pod 'Firebase/Crashlytics'
  pod 'Firebase/Analytics'
  pod 'Firebase/Messaging'
  pod 'SDWebImage'
  pod 'GrowingTextViewHandler-Swift', '1.2'
  pod "BSImagePicker", "~> 3.1"
  pod 'GoogleMaps'
  pod 'Tatsi'
  pod 'QCropper'
  pod 'KMPlaceholderTextView', '~> 1.4.0'
  pod 'NicoProgress'
  pod 'Firebase/RemoteConfig'
  pod 'Floaty', '~> 4.2.0'
  pod "PulsingHalo"
  pod 'MenuItemKit', '~> 4.0.0'
  pod 'MarqueeLabel'
  pod 'RxSwift', '6.5.0'
  pod 'RxCocoa', '6.5.0'
  pod 'SwiftLinkPreview'
  
  #submodule dependency pods
  
  pod 'Alamofire', '5.5'
  pod 'XMPPFramework/Swift'
  pod 'libPhoneNumber-iOS', '0.9.15'
  pod 'RealmSwift', '10.20.1'
  pod 'SocketRocket'
  pod 'Socket.IO-Client-Swift', '~> 15.2.0' # To communicte Socket I/O server
  pod 'GoogleWebRTC' # WebRTC for Calls

end

def notification_pods

  #submodule dependency pods

  pod 'libPhoneNumber-iOS', '0.9.15'
  pod 'Alamofire', '5.5'
  pod 'SocketRocket'
  pod 'Socket.IO-Client-Swift' , '~> 15.2.0' # To communicte Socket I/O server
  pod 'GoogleWebRTC' # WebRTC for Calls
  pod 'RealmSwift', '10.20.1'
  pod 'XMPPFramework/Swift'
  
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
