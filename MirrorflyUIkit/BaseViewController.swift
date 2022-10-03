//
//  BaseViewController.swift
//  MirrorflyUIkit
//
//  Created by John on 08/08/22.
//

import Foundation
import UIKit
import FlyCall



class BaseViewController : UIViewController {
    
    private let TAG = "BaseViewController"
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        CallManager.setMobileCallActionDelegate(delegate: self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        CallManager.setMobileCallActionDelegate(delegate: nil)
    }
    
    func disableIdleTimer(disable : Bool) {
        UIApplication.shared.isIdleTimerDisabled = disable
    }

}

/**
 * General call action Delegate to detect from mobile (other applications)
 * It is not used to application call actions
 */
extension BaseViewController : MobileCallActionDelegate {
    @objc func didCallAnswered() {
        print("\(TAG) didCallAnswered")
    }
    
    @objc func whileDialing() {
        print("\(TAG) whileDialing")
    }
    
    @objc func didCallDisconnected() {
        print("\(TAG) didCallDisconnected")
    }
    
    @objc func whileIncoming() {
        print("\(TAG) whileIncoming")
    }
}
