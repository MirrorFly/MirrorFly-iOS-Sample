//
//  FingerPrintPINViewController.swift
//  MirrorflyUIkit
//
//  Created by Ramakrishnan on 22/11/22.
//

import UIKit
import LocalAuthentication

class FingerPrintPINViewController: UIViewController {
    
   
    
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
                        self?.navigationController?.popViewController(animated: true)
                      
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

