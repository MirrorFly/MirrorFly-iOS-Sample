<p align="center">
  <img  src="https://dasa7d6hxd0bp.cloudfront.net/images/mirrorfly.webp" data-canonical-src="https://dasa7d6hxd0bp.cloudfront.net/images/mirrorfly.webp" width="400"  alt=""/>
</p>

# **MirrorFly iOS SDK For Video Chat & Calls**

Integrate enterprise-grade communication capabilities into your iOS app following this step-by-step implementation guide. MirrorFly's customizable white-label SDK delivers pre-built messaging and calling functionality optimized for Apple devices with straightforward client-side integration. This readme covers required frameworks, dependency management, supplementary components, and complete setup procedures.

# **🤹 Key Product Offerings**

MirrorFly helps build omni-channel communication apps for any kind of business

**💬 [In-app Messaging](https://www.mirrorfly.com/chat-api-solution.php)** \- Connect users individually or as groups via instant messaging features.  
**🎯 [HD Video Calling](https://www.mirrorfly.com/video-call-solution.php)**\- Engage users over face-to-face conversations anytime, and from anywhere.  
**🦾 [HQ Voice Calling](https://www.mirrorfly.com/voice-call-solution.php)** \- Deliver crystal clear audio calling experiences with latency as low as 3ms.  
🤖 [**AI Voice Agent**](https://www.mirrorfly.com/conversational-ai/voice-agent/) \- Build custom AI voicebots that can understand, act and respond to user questions.  
**🤖 [AI Chatbot](https://www.mirrorfly.com/conversational-ai/chatbot/)** \- Deploy white-label AI chatbots that drive autonomous conversations across any web or mobile app.  
**🦾 [Live Streaming](https://www.mirrorfly.com/live-streaming-sdk.php)** \- Broadcast video content to millions of viewers around the world, within your own enterprise app.

### **⚒️Call & Chat SDK for iOS**

### [**Requirements**](https://www.mirrorfly.com/docs/chat/ios/v3/quick-start#requirements)

The below are the requirements for chat SDK for iOS,

- Xcode 15.0 or later
- iOS 13.0 or later
- Swift 6.0 or later

### [**Things To Be Noted Before You Get Started**](https://www.mirrorfly.com/docs/chat/ios/v3/quick-start#things-to-be-noted-before-you-get-started)

#### [**SDK License Key**](https://www.mirrorfly.com/docs/chat/ios/v3/quick-start#sdk-license-key)

To integrate the MirrorFly Chat SDK into your app, you need an SDK License Key. The MirrorFly server uses this key to authenticate the SDK in your application.

##### [**To get the License Key**](https://www.mirrorfly.com/docs/chat/ios/v3/quick-start#to-get-the-license-key)**,**

Step 1: Register [here](https://www.mirrorfly.com/contact-sales.php) to get a MirrorFly User account.  
Step 2: [Login](https://console.mirrorfly.com/) to your Account  
Step 3: Get the License key from the application Info’ section  
Step 4: Download the iOS SDK

<img  src="https://www.mirrorfly.com/docs/assets/images/license-key-a1173e922ebff14b6ae1a2428f822eec.png" data-canonical-src="https://www.mirrorfly.com/docs/assets/images/license-key-a1173e922ebff14b6ae1a2428f822eec.png" width="100%"  alt=""/>

### [**Integrate the Chat SDK**](https://www.mirrorfly.com/docs/chat/ios/v3/quick-start#integrate-the-chat-sdk)

**Step 1:** Add the ChatSDK pod to your Podfile. If you haven’t initialized CocoaPods yet, create a Podfile by running the `pod init` command.

```ruby
pod 'MirrorFlySDK', '5.18.22'
```

**Step 2:** Add the following pod hook code block at the end of your Podfile, then install the pods by running the `pod install` command.

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET']        = '13.0'
      config.build_settings['ENABLE_BITCODE']                     = 'NO'
      config.build_settings['APPLICATION_EXTENSION_API_ONLY']     = 'No'
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulators*]'] = 'arm64'
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION']     = 'YES'
    end
  end
end
```

**Step 3 :** Now, disable the bitcode for your project

```txt
Goto Project -> Build Settings -> Filter the term `Bitcode` -> and select No from the dropdown
```

<img  src="https://mirrorfly.com/assets/images/tutorials/ios/integrate.webp" data-canonical-src="https://mirrorfly.com/assets/images/tutorials/ios/integrate.webp" width="100%"  alt=""/>

### [**Configure the SDK server & Data**](https://www.mirrorfly.com/docs/chat/ios/v3/quick-start#configure-the-sdk-server--data)

Configure the server details in the SDK, then access the data globally through the AppDelegate class.  
You can copy the license key from the Overview section in the Console dashboard.

```swift
let LICENSE_KEY = "xxxxxxxxxxxxxxxxxxxxxx"
```

## [**Initialize ChatSDK**](https://www.mirrorfly.com/docs/chat/ios/v3/quick-start#initialize-chatsdk)

Add the following import statement before using the SDK anywhere in your project.

```swift
import MirrorFlySDK
```

To start using the SDK, you need to provide a few basic pieces of information so it can work properly. The `initializeSDK` function handles this by checking your license key and pulling the important setup data from the server.

In your project, you should call this initialization method inside the AppDelegate class, specifically in the `didFinishLaunchingWithOptions` method. Just pass in your license key. Here’s an example to show how it works.

```swift
ChatManager.initializeSDK(licenseKey: LICENSE_KEY) { isSuccess, flyError, flyData in
    // handle initialization result
}
```

![AppDelegate][image4]

## [Registration](https://www.mirrorfly.com/docs/chat/ios/v3/quick-start#registration)

Use the method below to register a new user. This single method handles registration for both Sandbox mode and Live mode.

Make sure you call the registration method only once in your app, unless the user has logged out of their session.

```swift
try! ChatManager.registerApiService(for: USER_IDENTIFIER) { isSuccess, flyError, flyData in
    let data = flyData
    if isSuccess {
        // This is your Username
        guard let username = data["username"] as? String else {
            return
        }
        // This is your JID
        // Ex. 12345678@xmpp-preprod-sandbox.mirrorfly.com (USER_IDENTIFIER + @ + domain of the chat server)
        guard let userJid = data["userJid"] as? String else {
            return
        }
    } else {
        let error = data.getMessage()
        print("#chatSDK \(error)")
    }
}
```

To know more about `FlyCompletionHandler` click [here](https://www.mirrorfly.com/docs/chat/ios/v3/callback-delegates#flycompletionhandler)

**Caution**

If `IS_FORCE_REGISTER` is set to false and the user has already reached the maximum number of allowed sessions, the registration will fail and return a 405 error. To continue, either set `IS_FORCE_REGISTER` to true or log out one of the existing sessions before trying again.

Note: If you want to use your own ID, you can use the `userJid` provided in the registration response.

```swift
let userProfile: ProfileDetails = ContactManager.shared.saveTempContact(
    userId: "OUR OWN JID",
    name: "OUR NAME"
)
```

**Info**

After registration, save your own contact details in the database. These details are needed when you send group messages. Use the method below to store your contact information.

To create a unique user ID, pass the username into the method like this:

## [**Connect to the Chat Server**](https://www.mirrorfly.com/docs/chat/ios/v3/quick-start#connect-to-the-chat-server)

After registration is successful, the ChatSDK automatically tries to connect to the chat server. It also watches for changes in your app’s state and will connect or disconnect from the server as needed.

## [**Observe Connection Events**](https://www.mirrorfly.com/docs/chat/ios/v3/quick-start#observe-connection-events)

You can track the connection status by using the `ConnectionEventDelegate`. To do this, set the delegate in your `ViewController`’s `viewDidAppear` method, like this.

```swift
ChatManager.shared.connectionDelegate = self
```

After you set the `ConnectionEventDelegate`, you’ll start receiving connection status updates through the delegate method shown below.

```swift
func onConnected() {
    // Navigate to Conversation screen
}
```

To know more about `ConnectionEventDelegate` visit [ConnectionEvent Delegate](https://www.mirrorfly.com/docs/chat/ios/v3/callback-delegates#observe-chat-connection)

### [**Preparing user jid**](https://www.mirrorfly.com/docs/chat/ios/v3/quick-start#preparing-user-jid)

To generate a JID for any user, use the method shown below.

```swift
try? FlyUtils.getJid(USER_NAME)
```

## [**Send a One-to-One Message**](https://www.mirrorfly.com/docs/chat/ios/v3/quick-start#send-a-one-to-one-message)

Use the method below to send a text message from one user to another.

```swift
var textMessage = TextMessage()
textMessage.toId        = TO_JID
textMessage.messageText = TEXT

FlyMessenger.sendTextMessage(messageParams: textMessage) { isSuccess, error, chatMessage in
    if isSuccess {
        // Update the UI
    } else {
        // Handle the error
    }
}
```

## [**Receive a One-to-One Message**](https://www.mirrorfly.com/docs/chat/ios/v3/quick-start#receive-a-one-to-one-message)

Set the delegate in your `ViewController`’s `viewDidAppear` method using the syntax below and implement the `MessageEventsDelegate` class to receive incoming messages and related events.

```swift
ChatManager.shared.messageEventsDelegate = self
```

Once the delegate is set, the app can receive incoming messages through the method shown below. Refer to the `MessageEventsDelegate` class for details on other available methods.

```swift
func onMessageReceived(message: ChatMessage, chatJid: String) {
    // Message received from chatJid, content is message.messageTextContent
}
```

# **Making a call**

## [**Required permissions**](https://www.mirrorfly.com/docs/audio-video/ios/v2/making-a-call/#required-permissions)

For audio call, the below permissions:

```txt
Record Permission
```

You can use the below method to check audio call permissions:

```swift
CallManager.isAudioCallPermissionsGranted()
```

For video call, we need below permissions:

```txt
Record Permission
Video Permission
```

You can use the below method to check video call permissions:

```swift
CallManager.isVideoCallPermissionsGranted()
```

### [**Call Metadata**](https://www.mirrorfly.com/docs/audio-video/ios/v2/making-a-call/#call-metadata)

To send custom data when making a call, use the optional `metaData` parameter in all `makeCall` methods. This parameter accepts an array of type `CallMetadata`.

Caution: The Call SDK processes only the first three metadata elements. Avoid including large data, as it may disrupt the successful transfer of the VoIP call payload.

### [**Make a voice call**](https://www.mirrorfly.com/docs/audio-video/ios/v2/making-a-call/#make-a-voice-call)

The Voice Call feature allows users to initiate a one-to-one audio call with another SDK user, including optional call metadata. Use the following method to initiate a voice call:

```swift
try CallManager.makeVoiceCall(TO_USERID, CALL_METADATA) { isSuccess, flyError in
    if isSuccess {
        // SDK will take care of presenting the Call UI.
        // It will present the ViewController that is passed using
        // the method `CallManager.setCallViewController()`
    } else {
        let errorMessage = flyError?.description
        print("makeVoiceCall failed with error \(errorMessage ?? "")")
    }
}
```

### [**Make a video call**](https://www.mirrorfly.com/docs/audio-video/ios/v2/making-a-call/#make-a-video-call)

The Video Call feature allows users to initiate a one-to-one video call with another SDK user, including optional call metadata. Use the following method to initiate a video call:

```swift
try CallManager.makeVideoCall(TO_USERID, CALL_METADATA) { isSuccess, flyError in
    if isSuccess {
        // SDK will take care of presenting the Call UI.
        // It will present the ViewController that is passed using
        // the method `CallManager.setCallViewController()`
    } else {
        let errorMessage = flyError?.description
        print("makeVideoCall failed with error \(errorMessage ?? "")")
    }
}
```

### [**Make a group voice call**](https://www.mirrorfly.com/docs/audio-video/ios/v2/making-a-call/#make-a-group-voice-call)

The Group Voice Call feature allows users to initiate a voice call with multiple SDK users, including optional call metadata. Use the following method to start a group voice call:

```swift
try CallManager.makeGroupVoiceCall(USERID_LIST, GROUP_ID, CALL_METADATA) { isSuccess, flyError in
    if isSuccess {
        // SDK will take care of presenting the Call UI.
        // It will present the ViewController that is passed using
        // the method `CallManager.setCallViewController()`
    } else {
        let errorMessage = flyError?.description
        print("makeGroupVoiceCall failed with error \(errorMessage ?? "")")
    }
}
```

### [**Make a group video call**](https://www.mirrorfly.com/docs/audio-video/ios/v2/making-a-call/#make-a-group-video-call)

The Group Video Call feature allows users to initiate a video call with multiple SDK users, including optional call metadata. Use the following method to start a group video call:

```swift
try CallManager.makeGroupVideoCall(USERID_LIST, GROUP_ID, CALL_METADATA) { isSuccess, flyError in
    if isSuccess {
        // SDK will take care of presenting the Call UI.
        // It will present the ViewController that is passed using
        // the method `CallManager.setCallViewController()`
    } else {
        let errorMessage = flyError?.description
        print("makeGroupVideoCall failed with error \(errorMessage ?? "")")
    }
}
```

### [**Add participants to the call**](https://www.mirrorfly.com/docs/audio-video/ios/v2/making-a-call/#add-participants-to-the-call)

After a call is connected, you can add participants to the ongoing session. The SDK provides methods to invite users, and once they accept the incoming call, they join the active call.

```swift
CallManager.inviteUsersToOngoingCall(USERID_LIST) { isSuccess, flyError in
    if isSuccess {
        // users invited to ongoing call
    } else {
        let errorMessage = flyError?.description
        print("inviteUsersToOngoingCall failed with error \(errorMessage ?? "")")
    }
}
```

### [**Receiving a incoming audio/video call**](https://www.mirrorfly.com/docs/audio-video/ios/v2/making-a-call/#receiving-a-incoming-audiovideo-call)

Whenever an audio or video call is received from another SDK user, report it to FlyCallSDK via NotificationCenter.

```swift
NotificationCenter.default.post(
    name: NSNotification.Name("CallPayloadReceived"),
    object: messageDict
)
```

Through `messageDict` pass the payload of the call.

### [**Disconnect the ongoing call**](https://www.mirrorfly.com/docs/audio-video/ios/v2/making-a-call/#disconnect-the-ongoing-call)

When making an audio or video call to another SDK user, you can disconnect either before the call connects or after the conversation ends. Invoke the following SDK method when the user presses the disconnect button in your call UI to terminate the call and notify the other participant.

```swift
CallManager.disconnectCall()
```

# **☁️ Deployment Models \- Self-hosted and Cloud**

MirrorFly offers full freedom with the hosting options:  
**Self-hosted:** Deploy your client on your own data centers, private cloud or third-party servers.  
[Check out our multi-tenant cloud hosting](https://www.mirrorfly.com/self-hosted-chat-solution.php)  
**Cloud:** Host your client on MirrorFly’s multi-tenant cloud servers.  
[Check out our multi-tenant cloud hosting](https://www.mirrorfly.com/multi-tenant-chat-for-saas.php)

# **📱 Mobile Client**

MirrorFly offers a fully-built client SafeTalk that is available in:

- iOS
- Android

You can use this client as a messaging app, or customize, rebrand & white-label it as your chat client.

# **📚 Learn More**

- [Developer Documentation](https://www.mirrorfly.com/docs/)
- [Product Tutorials](https://www.mirrorfly.com/tutorials/)
- [Dart Documentation](https://pub.dev/packages/mirrorfly_plugin)
- [Pubdev Documentation](https://pub.dev/packages/mirrorfly_plugin)
- [Npmjs Documentation](https://www.npmjs.com/~contus)
- [On-premise Deployment](https://www.mirrorfly.com/on-premises-chat-server.php)
- [See who's using MirrorFly](https://www.mirrorfly.com/chat-use-cases.php)

# **🧑‍💻 Hire Experts**

Need a tech team to build your enterprise app? [Hire a full team of experts](https://www.mirrorfly.com/hire-video-chat-developer.php). From concept to launch, we handle every step of the development process. Get a high-quality, fully-built app ready to launch, carefully built by industry experts

# **⏱️ Round-the-clock Support**

If you’d like to take help when working with our solution, feel free to [contact our experts](https://www.mirrorfly.com/contact-sales.php) who will be available to help you anytime of the day or night.

## **💼 Become a Part of our amazing team**

We're always on the lookout for talented developers, support specialists, and product managers. Visit our [careers page](https://www.contus.com/careers.php) to explore current opportunities.

## **🗞️ Get the Latest Updates**

- [Blog](https://www.mirrorfly.com/blog/)
- [Facebook](https://www.facebook.com/MirrorFlyofficial/)
- [Twitter](https://twitter.com/mirrorflyteam)
- [LinkedIn](https://www.linkedin.com/showcase/mirrorfly-official/)
- [Youtube](https://www.youtube.com/@mirrorflyofficial)
- [Instagram](https://www.instagram.com/mirrorflyofficial/)
