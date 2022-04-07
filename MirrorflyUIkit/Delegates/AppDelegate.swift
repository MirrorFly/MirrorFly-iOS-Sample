//
//  AppDelegate.swift
//  MirrorflyUIkit
//
//  Created by User on 20/05/21.
//

import UIKit
import IQKeyboardManagerSwift
import UserNotifications
import Firebase
import FirebaseMessaging
import IQKeyboardManagerSwift
import GoogleMaps
import FlyCommon
import FlyCore
import PushKit
import FlyCall
import RxSwift
import Contacts

let BASE_URL = "https://api-preprod-sandbox.mirrorfly.com/api/v1/"
let LICENSE_KEY = "lu3Om85JYSghcsB6vgVoSgTlSQArL5"
let XMPP_DOMAIN = "xmpp-preprod-sandbox.mirrorfly.com"
let XMPP_PORT = 5222
let SOCKETIO_SERVER_HOST = "https://signal-preprod-sandbox.mirrorfly.com/"
let JANUS_URL = "wss://janus.mirrorfly.com"
let CONTAINER_ID = "group.com.mirrorfly.qa"
let IS_LIVE = false

@main
class AppDelegate: UIResponder, UIApplicationDelegate, MessagingDelegate {
    var window: UIWindow?
    static var sharedAppDelegateVar: AppDelegate? = nil
    let contactSyncSubject = PublishSubject<Bool>()
    var contactSyncSubscription : Disposable? = nil
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        CallManager.setAppGroupContainerId(id: CONTAINER_ID )
        FlyDefaults.licenseKey = LICENSE_KEY
        FlyDefaults.isTrialLicense = !IS_LIVE
        startObservingContactChanges()
        IQKeyboardManager.shared.enable = true
        GMSServices.provideAPIKey(googleApiKey)
        IQKeyboardManager.shared.shouldResignOnTouchOutside = true
        NetworkReachability.shared.startMonitoring()
        
        // Clear Push
        clearPushNotifications()
        registerForPushNotifications()
        
        if Utility.getBoolFromPreference(key: isProfileSaved) {
            let navigationController : UINavigationController
            if IS_LIVE {
                if !Utility.getBoolFromPreference(key: isLoginContactSyncDone){
                    let storyboard = UIStoryboard.init(name: Storyboards.profile, bundle: nil)
                    let initialViewController = storyboard.instantiateViewController(withIdentifier: Identifiers.contactSyncController) as! ContactSyncController
                    navigationController =  UINavigationController(rootViewController: initialViewController)
                }else{
                    let storyboard = UIStoryboard(name: Storyboards.main, bundle: nil)
                    let initialViewController =  storyboard.instantiateViewController(withIdentifier: Identifiers.mainTabBarController) as! MainTabBarController
                    navigationController =  UINavigationController(rootViewController: initialViewController)
                }
            }else{
                let storyboard = UIStoryboard(name: Storyboards.main, bundle: nil)
                let initialViewController = storyboard.instantiateViewController(withIdentifier: Identifiers.mainTabBarController) as! MainTabBarController
                navigationController =  UINavigationController(rootViewController: initialViewController)
            }
            self.window?.rootViewController = navigationController
            self.window?.makeKeyAndVisible()
        }else if Utility.getBoolFromPreference(key: isLoggedIn) {
            let storyboard = UIStoryboard(name: "Profile", bundle: nil)
            let initialViewController = storyboard.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
            self.window?.rootViewController =  UINavigationController(rootViewController: initialViewController)
            self.window?.makeKeyAndVisible()
        }
        
        let groupConfig = try? GroupConfig.Builder.enableGroupCreation(groupCreation: true)
            .onlyAdminCanAddOrRemoveMembers(adminOnly: true)
            .setMaximumMembersInAGroup(membersCount: 200)
            .build()
        assert(groupConfig != nil)
        
        try? ChatSDK.Builder.enableMobileNumberLogin(isEnable: true)
            .setDomainBaseUrl(baseUrl: BASE_URL)
            .setMaximumPinningForRecentChat(maxPinChat: 4)
            .setGroupConfiguration(groupConfig: groupConfig!)
            .deleteMediaFromDevice(delete: true)
            .setAppGroupContainerID(containerID: CONTAINER_ID)
            .buildAndInitialize()
        
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: { val, error in
                }
            )
        } else {
            let settings: UIUserNotificationSettings =
            UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()
        
        if Utility.getBoolFromPreference(key: isLoggedIn) {
            VOIPManager.sharedInstance.updateDeviceToken()
            RootViewController.sharedInstance.initCallSDK()
        }
        // Added this line so that we can start receing contact updates
        let contactPermissionStatus = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.CNContactStoreDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(contactsDidChange), name: NSNotification.Name.CNContactStoreDidChange, object: nil)
        NetworkMonitor.shared.startMonitoring()
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        NetworkReachability.shared.stopMonitoring()
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if let deviceToken = fcmToken {
            print(deviceToken)
            Utility.saveInPreference(key: googleToken, value: deviceToken)
        }
    }
    
    class func sharedAppDelegate() -> AppDelegate? {
        let userInfoBlock = {
            // Code for the method goes here
            sharedAppDelegateVar = UIApplication.shared.delegate as? AppDelegate
        }
        Thread.isMainThread ? userInfoBlock() : DispatchQueue.main.async(execute: userInfoBlock)
        
        return sharedAppDelegateVar
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        print("#appDelegate applicationDidBecomeActive")
        if (FlyDefaults.isLoggedIn) {
            ChatManager.makeXMPPConnection()
        }
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        print("#appDelegate applicationDidEnterBackground")
        NetStatus.shared.stopMonitoring()
        if (FlyDefaults.isLoggedIn) {
            ChatManager.disconnectXMPPConnection()
        }
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        contactSyncSubscription?.dispose()
        NetworkMonitor.shared.stop()
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.CNContactStoreDidChange, object: nil)
    }
    

}

// MARK:- Push Notifications
extension AppDelegate : UNUserNotificationCenterDelegate {
    /// Register for APNS Notifications
    func registerForPushNotifications() {
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                    FlyUtils.setBaseUrl(BASE_URL)
                }
            }
        }
        registerForVOIPNotifications()
    }
    /// This method is used to clear notifications and badge count
    func clearPushNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%.2hhx", $0) }.joined()
        if token.count == 0 {
            print("Push Status Credentials APNS:")
            return;
        }
        print("#token appDelegate \(token)")
        FlyCallUtils.sharedInstance.setConfigUserDefaults(token, withKey: "updatedTokenAPNS")
        VOIPManager.sharedInstance.updateDeviceToken()
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Push didFailToRegisterForRemoteNotificationsWithError)")
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler(.alert)
    }
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("Push userInfo \(userInfo)")
        completionHandler(.noData)
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.notification.request.identifier.contains("#missed_call"){
//            if let navRootController = window?.rootViewController as? UINavigationController {
//                if !(navRootController.viewControllers.last?.isKind(of: callLogViewController.self) ?? false) {
//                    let storyBoard = UIStoryboard(name: Storyboards.main, bundle: nil)
//                    let callLogController = storyBoard.instantiateViewController(withIdentifier: "callLogViewController") as! callLogViewController
//                    navRootController.pushViewController(callLogController, animated: true)
//                }
//            }
        }
    }
}
// MARK:- VOIP Notifications
extension AppDelegate : PKPushRegistryDelegate {
    func registerForVOIPNotifications() {
        let pushRegistry = PKPushRegistry(queue: .main)
        pushRegistry.delegate = self
        pushRegistry.desiredPushTypes = [.voIP]
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        
        //print out the VoIP token. We will use this to test the nofications.
        NSLog("VoIP Token: \(pushCredentials)")
        let deviceTokenString = pushCredentials.token.reduce("") { $0 + String(format: "%02X", $1) }
        print(deviceTokenString)
        FlyCallUtils.sharedInstance.setConfigUserDefaults(deviceTokenString, withKey: "updatedTokenVOIP")
        VOIPManager.sharedInstance.updateDeviceToken()
    }
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        NSLog("Push VOIP Received with Payload - %@",payload.dictionaryPayload)
        VOIPManager.sharedInstance.processPayload(payload.dictionaryPayload)
    }
}


extension AppDelegate {
    
    func startObservingContactChanges(){
        contactSyncSubscription = contactSyncSubject.throttle(.seconds(3), latest: false ,scheduler: MainScheduler.instance).subscribe(onNext: { bool in
            if bool{
                ContactSyncManager.shared.syncContacts(firstLogin: false){ isSuccess,_,_ in
                   print("#contact Sync status => \(isSuccess)")
                }
            }
        })
    }
    
    
    @objc func contactsDidChange(notification: NSNotification){
        print("#contact #appdelegate @contactsDidChange")
        if Utility.getBoolFromPreference(key: isLoggedIn) {
            FlyDefaults.isContactSyncNeeded = true
            contactSyncSubject.onNext(true)
        }
    }
}
