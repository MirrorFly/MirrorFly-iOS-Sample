//
//  FingerPrintPINViewController.swift
//  MirrorflyUIkit
//
//  Created by Ramakrishnan on 22/11/22.
//

import UIKit
import LocalAuthentication
import FlyCommon

var fingerPrintDidCancel = false

class FingerPrintPINViewController: UIViewController {
    
    var chatId = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        authenticationWithTouchID()
        
    }
    
    func authenticationWithTouchID() {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Identify yourself!"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) {
                [weak self] success, authenticationError in
                
                DispatchQueue.main.async {
                    if success {
                        FlyDefaults.showAppLock = false
                        let storyboard = UIStoryboard(name: Storyboards.main, bundle: nil)
                        let initialViewController = storyboard.instantiateViewController(withIdentifier: Identifiers.mainTabBarController) as! MainTabBarController
                        let navigationController =  UINavigationController(rootViewController: initialViewController)
                        UIApplication.shared.windows.first?.rootViewController = navigationController
                        UIApplication.shared.windows.first?.makeKeyAndVisible()

                    } else {
                        let vc = AuthenticationPINViewController(nibName:Identifiers.authenticationPINViewController, bundle: nil)
                        self?.navigationController?.pushViewController(vc, animated: true)
                        vc.fingerPrintLogin = true
                    }
                }
            }
        } else {
            AppAlert.shared.showToast(message: ErrorMessage.fingerPrintIsNotRegisteredinDevice)
            let vc = AuthenticationPINViewController(nibName:Identifiers.authenticationPINViewController, bundle: nil)
            self.navigationController?.pushViewController(vc, animated: true)
            vc.noFingerprintAdded = true
        }
    }
}

