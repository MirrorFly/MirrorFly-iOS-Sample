platform :ios, '12.1'
target 'MirrorflyUIkit' do

  use_frameworks!
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
  pod 'Floaty', '~> 4.2.0'
  pod "PulsingHalo"
  pod 'MenuItemKit', '~> 4.0.0'
  pod 'RealmSwift', '~> 10.20.1'
  pod 'MarqueeLabel'
  pod 'RxSwift', '6.5.0'
  pod 'RxCocoa', '6.5.0'
  pod 'SocketRocket'
  pod 'Socket.IO-Client-Swift', '~> 15.2.0'
  pod 'GoogleWebRTC'
  pod 'XMPPFramework/Swift'
  pod 'Alamofire'
  pod 'libPhoneNumber-iOS'

end

target 'NotificationExtention' do
  use_frameworks!
  pod 'SocketRocket'
  pod 'Socket.IO-Client-Swift', '~> 15.2.0'
  pod 'GoogleWebRTC'
  pod 'RealmSwift', '~> 10.20.1'
  pod 'XMPPFramework/Swift'
  pod 'Alamofire'
  pod 'libPhoneNumber-iOS'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.1'
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
    end
  end
end
