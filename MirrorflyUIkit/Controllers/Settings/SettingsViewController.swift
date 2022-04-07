//
//  SettingsViewController.swift
//  MirrorflyUIkit
//
//  Created by User on 08/12/21.
//

import Foundation
import UIKit
import FlyCore
import FlyCommon


class SettingsViewController : UIViewController {
    
    @IBAction func onLogout(_ sender: Any) {
        let appAlert = AppAlert.shared
        appAlert.showAlert(view: self, title: nil, message: "Are you sure you want to logout?", buttonOneTitle: "YES", buttonTwoTitle: "NO")
        AppAlert.shared.onAlertAction = { [weak self] (result) ->
            Void in
            if result == 0 {
                self?.requestLogout()
            }
        }

    }
    
    func requestLogout() {
        startLoading(withText: pleaseWait)
       
         ChatManager.logoutApi { [weak self] isSuccess, flyError, flyData in
            
            if isSuccess {
                self?.stopLoading()
                Utility.saveInPreference(key: isProfileSaved, value: false)
                Utility.saveInPreference(key: isLoggedIn, value: false)
                ChatManager.disconnectXMPPConnection()
                var controller : OTPViewController?
                if #available(iOS 13.0, *) {
                    controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "OTPViewController")
                } else {
                    // Fallback on earlier versions
                    controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "OTPViewController") as? OTPViewController
                }
                let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
                if let navigationController = window?.rootViewController  as? UINavigationController, let otpViewController = controller {
                    navigationController.popToRootViewController(animated: false)
                    navigationController.pushViewController(otpViewController, animated: false)
                }
                

            }else{
                print("Logout api error : \(String(describing: flyError))")
                self?.stopLoading()
            }
        }
    }
    
}
