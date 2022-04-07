//
//  SceneDelegate.swift
//  MirrorflyUIkit
//
//  Created by User on 20/05/21.
//

import UIKit
import FlyCore
import FlyCommon

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    static var sharedAppDelegateVar: SceneDelegate? = nil

    @available(iOS 13.0, *)
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        if  Utility.getBoolFromPreference(key: isProfileSaved) {
            let navigationController : UINavigationController
            if IS_LIVE {
                let storyboard = UIStoryboard.init(name: Storyboards.profile, bundle: nil)
                let initialViewController = storyboard.instantiateViewController(withIdentifier: Identifiers.contactSyncController) as! ContactSyncController
                navigationController =  UINavigationController(rootViewController: initialViewController)
            }else{
                let storyboard = UIStoryboard(name: Storyboards.main, bundle: nil)
                let initialViewController = storyboard.instantiateViewController(withIdentifier: Identifiers.mainTabBarController) as! MainTabBarController
                navigationController =  UINavigationController(rootViewController: initialViewController)
            }
            self.window?.rootViewController = navigationController
            self.window?.makeKeyAndVisible()
        }else if  Utility.getBoolFromPreference(key: isLoggedIn) {
            let storyboard = UIStoryboard(name: "Profile", bundle: nil)
            let initialViewController = storyboard.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
            self.window?.rootViewController =  UINavigationController(rootViewController: initialViewController)
            self.window?.makeKeyAndVisible()
        }
        
        if #available(iOS 13.0, *) {
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
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    @available(iOS 13.0, *)
    func sceneDidBecomeActive(_ scene: UIScene) {
        print("#scene sceneDidBecomeActive \(FlyDefaults.isLoggedIn)")
        if (FlyDefaults.isLoggedIn) {
            ChatManager.makeXMPPConnection()
        }
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }


    @available(iOS 13.0, *)
    func sceneWillResignActive(_ scene: UIScene) {
        
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    @available(iOS 13.0, *)
    func sceneWillEnterForeground(_ scene: UIScene) {
        print("#scene sceneWillEnterForeground \(FlyDefaults.isLoggedIn)")
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    @available(iOS 13.0, *)
    func sceneDidEnterBackground(_ scene: UIScene) {
        print("#scene sceneDidEnterBackground")
        ChatManager.disconnectXMPPConnection()
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

