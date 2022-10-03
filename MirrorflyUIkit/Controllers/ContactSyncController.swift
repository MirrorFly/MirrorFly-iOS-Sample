//
//  ContactSyncController.swift
//  MirrorflyUIkit
//
//  Created by User on 04/02/22.
//

import UIKit
import FlyCommon
import Contacts
import Toaster
import FlyCore
import RxSwift

class ContactSyncController: UIViewController {
    
    @IBOutlet weak var progressInfoLabel: UILabel!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var syncImage: UIImageView!
    var alertController : UIAlertController? = nil
    var internetObserver = PublishSubject<Bool>()
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        syncImage.isHidden = true
        NotificationCenter.default.addObserver(self, selector: #selector(networkChange(_:)), name:  Notification.Name(NetStatus.networkNotificationObserver), object: nil)
        progressInfoLabel.text = ""
        userName.text = FlyDefaults.myName
        
        internetObserver.throttle(.seconds(2), latest: false ,scheduler: MainScheduler.instance).subscribe { [weak self] event in
            switch event {
            case .next(let data):
                print("#contact next ")
                if data {
                    AppAlert.shared.showToast(message: "Connected to internet")
                    self?.progressInfoLabel.text = "Contact sync is in progress"
                    self?.startSyncingContacts()
                }else{
                    self?.progressInfoLabel.text = ""
                    self?.syncImage.stopRotating()
                }
            case .error(let error):
                print("#contactSync error \(error.localizedDescription)")
            case .completed:
                print("#contactSync completed")
            }
            
        }.disposed(by: disposeBag)
        
        showPermissionDescripTion()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if  CNContactStore.authorizationStatus(for: .contacts) == .authorized && FlyDefaults.isContactPermissionSkipped == false{
            alertController?.dismiss(animated: true)
        }
    }
    
    @objc func networkChange(_ notification: NSNotification) {
        DispatchQueue.main.async { [weak self] in
            let isNetworkAvailable = notification.userInfo?[NetStatus.isNetworkAvailable] as? Bool ?? false
            print("#contact networkChange ")
            self?.internetObserver.on(.next(isNetworkAvailable))
        }
        
    }
    
    
    func syncProgressUiUpdate(){
        let authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
        if authorizationStatus == .authorized {
            progressInfoLabel.text = "Contact sync is in progress"
            syncImage.isHidden = false
            syncImage.startRotating(duration: 1)
        }else if authorizationStatus == .denied {
            progressInfoLabel.text = "Contact permission denied"
            syncImage.isHidden = true
        }else {
            progressInfoLabel.text = "Contact read contact permission"
            syncImage.isHidden = true
        }
    }
    
    
    func startSyncingContacts(initialSync : Bool = true) {
        let authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
        if authorizationStatus == .authorized{
            FlyDefaults.isContactPermissionDenied = false
        }else if authorizationStatus == .denied{
            FlyDefaults.isContactPermissionDenied = true
            showGoToSettingsAlert()
        }
        FlyDefaults.isContactSyncNeeded = true
        if NetStatus.shared.isConnected{
            executeOnMainThread {
                self.syncProgressUiUpdate()
            }
            ContactSyncManager.shared.syncContacts(){ [weak self] (isSuccess, flyError, flyData)  in
                executeOnMainThread {
                    if isSuccess{
                        Utility.saveInPreference(key: isLoginContactSyncDone, value: true)
                        if authorizationStatus == .authorized{
                            Toast.init(text: "Contacts synced successfully  ").show()
                            self?.progressInfoLabel.text = "Contacts Synced"
                            self?.syncImage.stopRotating()
                        }
                        self?.moveToDashboard()
                    }else{
                        Utility.saveInPreference(key: isLoginContactSyncDone, value: false)
                        self?.progressInfoLabel.text = "Internet not available"
                        self?.syncImage.stopRotating()
                        AppAlert.shared.showToast(message: "Contact sync failure \(flyError?.localizedDescription)")
                    }
                }
            }
        }else{
            progressInfoLabel.text = "Internet not available"
            AppAlert.shared.showToast(message: "Enable internet to sync contacts")
        }
    }
    
    
    func contactPermissionDenied(){
        AppAlert.shared.showToast(message: "Contact permission denied")
        moveToDashboard()
    }
    
    func moveToDashboard(){
        DispatchQueue.main.async { [weak self] in
            Utility.saveInPreference(key: isLoginContactSyncDone, value: true)
            if !Utility.getBoolFromPreference(key: firstTimeSandboxContactSyncDone) {
                ChatManager.sendRegisterUpdate { isSuccess, error, data in
                    if isSuccess{
                        Utility.saveInPreference(key: firstTimeSandboxContactSyncDone, value: true)
                    }
                }
            }
            let storyboard = UIStoryboard.init(name: Storyboards.main, bundle: nil)
            let mainTabBarController = storyboard.instantiateViewController(withIdentifier: Identifiers.mainTabBarController) as! MainTabBarController
            self?.navigationController?.pushViewController(mainTabBarController, animated: true)
            self?.navigationController?.viewControllers.removeAll(where: { viewControllers in
                !viewControllers.isKind(of: MainTabBarController.self)
            })
        }
    }
    
    func showPermissionDescripTion() {
        let title = "We need permission to read your contacts"
        let message = "This app relies on read access to your contacts. We require access to this permission to find your contacts in our database and suggest people you know. We will not store any contact info in our database if they are not a part of our platform. For further info read our privacy policy."
        alertController =  UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        alertController?.setValue(NSAttributedString(string: title, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.semibold),NSAttributedString.Key.foregroundColor : UIColor.black]), forKey: "attributedTitle")
        alertController?.setValue(NSAttributedString(string: message, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 13, weight: UIFont.Weight.regular),NSAttributedString.Key.foregroundColor : UIColor.black]), forKey: "attributedMessage")
        let continueAction = UIAlertAction(title: "Continue", style: .default) { [weak self] _ in
            let authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
            if authorizationStatus == .authorized{
                self?.startSyncingContacts()
            }else if authorizationStatus == .denied{
                self?.showGoToSettingsAlert()
            }else{
                self?.progressInfoLabel.text = "Waiting for Contact permission"
                CNContactStore().requestAccess(for: .contacts){ [weak self] (access, error)  in
                    executeOnMainThread { [weak self] in
                        self?.startSyncingContacts()
                    }
                }
            }
        }
        alertController!.addAction(continueAction)
        let notNowAction = UIAlertAction(title: "Not now", style: .cancel) { [weak self] _ in
            FlyDefaults.isContactPermissionSkipped = true
            ContactSyncManager.shared.syncContacts(){ [weak self] (_, _, _)  in }
            self?.moveToDashboard()
        }
        alertController!.addAction(notNowAction)
        present(alertController!, animated: true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name(NetStatus.networkNotificationObserver), object: nil)
    }
    
    func showGoToSettingsAlert(){
        let settingsAppURL = URL(string: UIApplication.openSettingsURLString)!
        let alert = UIAlertController(
            title: "Need Contacts permission",
            message: "Contacts access has been denied. Kindly enable contact access in app settings.",
            preferredStyle: UIAlertController.Style.alert
        )
        alert.addAction(UIAlertAction(title: "Go to settings", style: .default, handler: { (alert) -> Void in
            UIApplication.shared.open(settingsAppURL, options: [:], completionHandler: nil)
        }))
        alert.addAction(UIAlertAction(title: "Don't  Allow ", style: .cancel, handler: { (alert) -> Void in
            executeOnMainThread { [weak self] in
                self?.moveToDashboard()
            }
        }))
        present(alert, animated: true, completion: nil)
    }
    
}


extension UIView {
    
    func startRotating(duration: CFTimeInterval = 3, repeatCount: Float = Float.infinity, clockwise: Bool = true) {
        DispatchQueue.main.async { [weak self] in
            if self?.layer.animation(forKey: "transform.rotation.z") != nil {
                return
            }
            let animation = CABasicAnimation(keyPath: "transform.rotation.z")
            let direction = clockwise ? 1.0 : -1.0
            animation.toValue = NSNumber(value: .pi * 2 * direction)
            animation.duration = duration
            animation.isCumulative = true
            animation.repeatCount = repeatCount
            self?.layer.add(animation, forKey:"transform.rotation.z")
        }
    }
    
    func stopRotating() {
        
        self.layer.removeAnimation(forKey: "transform.rotation.z")
        
    }
    
}
