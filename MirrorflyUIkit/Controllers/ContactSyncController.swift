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
    var internetObserver = PublishSubject<Bool>()
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(networkChange(_:)), name:  Notification.Name(NetworkMonitor.networkNotificationObserver), object: nil)
        progressInfoLabel.text = ""
        userName.text = FlyDefaults.myName
        
        let authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
        if authorizationStatus == .authorized{
            executeOnMainThread { [weak self] in
                self?.startSyncingContacts()
            }
        }else{
            progressInfoLabel.text = ""
            CNContactStore().requestAccess(for: .contacts){ [weak self] (access, error)  in
                if access {
                    executeOnMainThread { [weak self] in
                        self?.startSyncingContacts()
                    }
                }else{
                    self?.contactPermissionDenied()
                }
            }
        }
        
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
    }
    
    @objc func networkChange(_ notification: NSNotification) {
        DispatchQueue.main.async { [weak self] in
            let isNetworkAvailable = notification.userInfo?[NetworkMonitor.isNetworkAvailable] as? Bool ?? false
            print("#contact networkChange ")
            self?.internetObserver.on(.next(isNetworkAvailable))
        }
        
    }
    
    
    func startSyncingContacts(initialSync : Bool = true) {
        if NetworkMonitor.shared.isConnected{
            self.progressInfoLabel.text = "Contact sync is in progress"
            syncImage.startRotating(duration: 1)
            ContactSyncManager.shared.syncContacts(firstLogin: initialSync){ [weak self] (isSuccess, flyError, flyData)  in
                if isSuccess{
                    Utility.saveInPreference(key: isLoginContactSyncDone, value: true)
                    Toast.init(text: "Contacts synced successfully  ").show()
                    self?.progressInfoLabel.text = "Contacts Synced"
                    self?.syncImage.stopRotating()
                    self?.moveToDashboard()
                }else{
                    Utility.saveInPreference(key: isLoginContactSyncDone, value: false)
                    self?.progressInfoLabel.text = "Internet not available"
                    self?.syncImage.stopRotating()
                    AppAlert.shared.showToast(message: "Contact sync failure \(flyError?.localizedDescription)")
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
        Utility.saveInPreference(key: isLoginContactSyncDone, value: true)
        let storyboard = UIStoryboard.init(name: Storyboards.main, bundle: nil)
        let mainTabBarController = storyboard.instantiateViewController(withIdentifier: Identifiers.mainTabBarController) as! MainTabBarController
        navigationController?.pushViewController(mainTabBarController, animated: true)
        navigationController?.viewControllers.removeAll(where: { viewControllers in
            !viewControllers.isKind(of: MainTabBarController.self)
        })
       
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name(NetworkMonitor.networkNotificationObserver), object: nil)
    }
    
}


extension UIView {
    
    func startRotating(duration: CFTimeInterval = 3, repeatCount: Float = Float.infinity, clockwise: Bool = true) {
        if self.layer.animation(forKey: "transform.rotation.z") != nil {
            return
        }
        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        let direction = clockwise ? 1.0 : -1.0
        animation.toValue = NSNumber(value: .pi * 2 * direction)
        animation.duration = duration
        animation.isCumulative = true
        animation.repeatCount = repeatCount
        self.layer.add(animation, forKey:"transform.rotation.z")
    }
    
    func stopRotating() {
        
        self.layer.removeAnimation(forKey: "transform.rotation.z")
        
    }
    
}
