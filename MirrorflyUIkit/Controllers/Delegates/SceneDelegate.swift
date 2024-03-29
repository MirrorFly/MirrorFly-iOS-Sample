//
//  SceneDelegate.swift
//  MirrorflyUIkit
//
//  Created by User on 20/05/21.
//

import UIKit
import FlyCore
import FlyCommon
import FlyCall
import FirebaseRemoteConfig

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var remoteConfig: RemoteConfig!
    static var sharedAppDelegateVar: SceneDelegate? = nil
    
    var postNotificationdidEnterBackground : NotificationCenter? = nil

    @available(iOS 13.0, *)
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).

        if FlyDefaults.appLockenable || FlyDefaults.appFingerprintenable {
            FlyDefaults.showAppLock = true
        }

        if FlyDefaults.isBlockedByAdmin {
            navigateToBlockedScreen()
        } else if Utility.getBoolFromPreference(key: isProfileSaved) {
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
        
        if #available(iOS 13.0, *) {
            window?.overrideUserInterfaceStyle = .light
            guard let _ = (scene as? UIWindowScene) else { return }
            
        } else {
            // Fallback on earlier versions
        }
    }
    
    class func sharedAppDelegate() -> SceneDelegate? {
        let userInfoBlock = {
            // Code for the method goes here
            sharedAppDelegateVar = UIApplication.shared.delegate as? SceneDelegate
        }
        Thread.isMainThread ? userInfoBlock() : DispatchQueue.main.async(execute: userInfoBlock)
        
        return sharedAppDelegateVar
    }

    @available(iOS 13.0, *)
    func sceneDidDisconnect(_ scene: UIScene) {
        if FlyDefaults.appLockenable || FlyDefaults.appFingerprintenable {
            FlyDefaults.showAppLock = true
        }
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    @available(iOS 13.0, *)
    func sceneDidBecomeActive(_ scene: UIScene) {
        print("#scene sceneDidBecomeActive \(FlyDefaults.isLoggedIn)")
        if FlyDefaults.isBlockedByAdmin {
            navigateToBlockedScreen()
            return
        }
        if Utility.getBoolFromPreference(key: isLoggedIn) && (FlyDefaults.isLoggedIn) {
            ChatManager.makeXMPPConnection()
        }
        let current = UIApplication.shared.keyWindow?.getTopViewController()
        if (current is AuthenticationPINViewController || current is FingerPrintPINViewController) {
            if let vc = current as? FingerPrintPINViewController {
                if vc.isSystemCancel {
                    vc.authenticationWithTouchID()
                }
            }
           return
        }
        NotificationCenter.default.post(name: NSNotification.Name(didBecomeActive), object: nil)
        //setup remote config
        setupRemoteConfig()
        ForceUpdateChecker(listener: self).checkIsNeedUpdate()
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(didEnterBackground), object: nil)
        iCloudmanager().checkAutoBackupSchedule()
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }


    @available(iOS 13.0, *)
    func sceneWillResignActive(_ scene: UIScene) {
        //FlyDefaults.appBackgroundTime = Date()
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    @available(iOS 13.0, *)
    func sceneWillEnterForeground(_ scene: UIScene) {
        NetworkReachability.shared.startMonitoring()

        if (FlyDefaults.appLockenable || FlyDefaults.appFingerprintenable) {
            let secondsDifference = Calendar.current.dateComponents([.minute, .second], from: FlyDefaults.appBackgroundTime, to: Date())
            if secondsDifference.second ?? 0 > 32 || secondsDifference.minute ?? 0 > 0 {
                FlyDefaults.showAppLock = true
            }
        }
        print("#scene sceneWillEnterForeground \(FlyDefaults.isLoggedIn)")
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    @available(iOS 13.0, *)
    func sceneDidEnterBackground(_ scene: UIScene) {
        print("#scene sceneDidEnterBackground")
        FlyDefaults.appBackgroundTime = Date()
        postNotificationdidEnterBackground = NotificationCenter.default
        postNotificationdidEnterBackground?.post(name: Notification.Name(didEnterBackground), object: nil)
        if Utility.getBoolFromPreference(key: isLoggedIn){
            ChatManager.disconnectXMPPConnection()
        }
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

extension SceneDelegate {
    func navigateToBlockedScreen() {
        Utility.saveInPreference(key: isProfileSaved, value: false)
        Utility.saveInPreference(key: isLoggedIn, value: false)
        ChatManager.disconnect()
        ChatManager.shared.resetFlyDefaults()
        FlyDefaults.isBlockedByAdmin = false
        if CallManager.isOngoingCall() {
            CallManager.disconnectCall()
        }
        let storyboard = UIStoryboard(name: "Profile", bundle: nil)
        let initialViewController = storyboard.instantiateViewController(withIdentifier: "BlockedByAdminViewController") as! BlockedByAdminViewController
        self.window?.rootViewController =  UINavigationController(rootViewController: initialViewController)
        self.window?.makeKeyAndVisible()
    }
}

//Mark:- RemoteConfig Setup
extension SceneDelegate {
    func setupRemoteConfig(){
        
        remoteConfig = RemoteConfig.remoteConfig()
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0
        remoteConfig.configSettings = settings
        remoteConfig.setDefaults(fromPlist: "RemoteConfigDefaults")
        var expirationDuration = 60
        
        remoteConfig?.fetch(withExpirationDuration: TimeInterval(expirationDuration)) { [weak self] (status, error) in
            if status == .success {
                print("config fetch done")
                self?.remoteConfig?.activate()
                self?.setVersionDetails()
            } else {
                print("Config not fetched")
                print("Error: \(error?.localizedDescription ?? "No error available.")")
            }
        }
    }
    
    func setVersionDetails() {
        let isUpdateNeed = remoteConfig?.configValue(forKey: "iOS_remote_Update_IsNeed").boolValue
        let liveAppVersion = remoteConfig?.configValue(forKey: "iOS_remote_Update_Version").stringValue
        let remoteStoreURL = remoteConfig?.configValue(forKey: "iOS_force_update_store_url").stringValue
        let remoteTitle = remoteConfig?.configValue(forKey: "iOS_remote_title").stringValue
        let remote_Description = remoteConfig?.configValue(forKey: "iOS_remote_description").stringValue
        
        //set in app defaults
        let defaults : [String : Any] = [
            ForceUpdateChecker.FORCE_UPDATE_REQUIRED : isUpdateNeed ?? false,
            ForceUpdateChecker.FORCE_UPDATE_CURRENT_VERSION : liveAppVersion ?? "",
            ForceUpdateChecker.FORCE_UPDATE_STORE_URL : remoteStoreURL ?? "",
            ForceUpdateChecker.FORCE_UPDATE_TITLE : remoteTitle ?? "",
            ForceUpdateChecker.FORCE_UPDATE_DESCRIPTION : remote_Description ?? ""
        ]
        remoteConfig?.setDefaults(defaults as? [String : NSObject])
    }
}

extension SceneDelegate : OnUpdateNeededListener {
    func onUpdateNeeded(updateUrl: String) {
        let initialViewController = ForceUpdateAlertViewController(nibName: "ForceUpdateAlert", bundle: nil)
        initialViewController.modalPresentationStyle = .overFullScreen
        let current = UIApplication.shared.keyWindow?.getTopViewController()
        if current is ForceUpdateAlertViewController {
           return
        }
        current?.present(initialViewController, animated: true,completion: nil)
    }
    
    func onNoUpdateNeeded() {
        print("onNoUpdateNeeded()")
    }
}
