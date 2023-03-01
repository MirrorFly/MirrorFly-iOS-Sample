//
//  FingerPrintPINViewController.swift
//  MirrorflyUIkit
//
//  Created by Ramakrishnan on 22/11/22.
//

import UIKit
import LocalAuthentication
import FlyCommon
import FlyCall

class FingerPrintPINViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        handleBackgroundAndForground()
        authenticationWithTouchID()
    }

    func daysBetween(start: Date, end: Date) -> Int {
        return Calendar.current.dateComponents([.day], from: start, to: end).day!
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
                        if self?.daysBetween(start: FlyDefaults.appLockPasswordDate, end: Date()) ?? 0 > 31 {
                            let initialViewController = AuthenticationPINViewController(nibName: "AuthenticationPINViewController", bundle: nil)
                            initialViewController.noFingerprintAdded = true
                            self?.navigationController?.pushViewController(initialViewController, animated: false)
                        } else {
                            FlyDefaults.showAppLock = false
                            self?.navigationController?.popToRootViewController(animated: false)
                        }
                    } else {
                        guard let error = authenticationError else {
                            return
                        }
                        self?.evaluateAuthenticationError(errorCode: error._code)
                    }
                }
            }
        } else {
            AppAlert.shared.showToast(message: ErrorMessage.fingerPrintIsNotRegisteredinDevice)
            let initialViewController = AuthenticationPINViewController(nibName: "AuthenticationPINViewController", bundle: nil)
            initialViewController.noFingerprintAdded = true
            self.navigationController?.pushViewController(initialViewController, animated: false)
        }
    }

    func evaluateAuthenticationError(errorCode: Int) {
        switch errorCode {
        case LAError.authenticationFailed.rawValue:
            navigateToAuthentication()
            FlyDefaults.faceOrFingerAuthenticationFails = true
        case LAError.userCancel.rawValue:
            navigateToAuthentication()
        case LAError.userFallback.rawValue:
            //FlyDefaults.faceOrFingerAuthenticationFails = true
            navigateToAuthentication()
        default:
            break
        }
    }

    func navigateToAuthentication() {
        let initialViewController = AuthenticationPINViewController(nibName: "AuthenticationPINViewController", bundle: nil)
        initialViewController.fingerPrintLogin = true
        self.navigationController?.pushViewController(initialViewController, animated: false)
    }


}
