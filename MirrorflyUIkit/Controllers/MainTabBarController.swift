//
//  MainTabBarController.swift
//  MirrorflyUIkit
//
//  Created by User on 11/08/21.
//

import UIKit
import FlyCore
import FlyDatabase
import FlyCommon

class MainTabBarController: UITabBarController{
    @IBOutlet weak var chatTabBars: UITabBar?
    
    let defaults = UserDefaults.standard
    
    static var isConnected = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if FlyDefaults.isContactSyncNeeded {
            ContactSyncManager.shared.syncContacts(firstLogin: false){ isSuccess,_,_ in
               print("#contactSync status => \(isSuccess)")
            }
        }
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupUI()
        saveMyJidAsContacts()
        ChatManager.shared.connectionDelegate = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        defaults.set(view.safeAreaLayoutGuide.layoutFrame.height, forKey: "safeAreaHeight")
        defaults.set(view.safeAreaLayoutGuide.layoutFrame.width, forKey: "safeAreaWidth")
    }
    
    // MARK: - Functions
    func setupUI() {
        navigationController?.setNavigationBarHidden(true, animated: true)
        guard let items = tabBar.items else { return }
        items[0].title = chat
        items[1].title = contact
        items[2].title = call
        items[3].title = profile
        items[4].title = setting
    }
    
//    func getGroups() {
//        if !MainTabBarController.isConnected {
//            GroupManager.shared.getGroups(fetchFromServer: true) { isSuccess, flyError, flyData in
//                var data  = flyData
//                if isSuccess {
//                    print("MainTabBarController \(data.getMessage() as! String )")
//                    MainTabBarController.isConnected = true
//                } else{
//                    print("MainTabBarController \(data.getMessage() as! String )")
//                    MainTabBarController.isConnected = false
//                }
//           }
//        }
//    }
    
    func saveMyJidAsContacts() {
        let profileData = ProfileDetails(jid: FlyDefaults.myJid)
        profileData.name = FlyDefaults.myName
        profileData.nickName = FlyDefaults.myNickName
        profileData.mobileNumber  = FlyDefaults.myMobileNumber
        profileData.email = FlyDefaults.myEmail
        profileData.status = FlyDefaults.myStatus
        profileData.image = FlyDefaults.myImageUrl
        
        FlyDatabaseController.shared.rosterManager.saveContact(profileDetailsArray: [profileData], chatType: .singleChat, contactType: .live, saveAsTemp: false)
    }
    
}

extension MainTabBarController : ConnectionEventDelegate {
    func onConnected() {

    }
    
    func onDisconnected() {
        
    }
    
    func onConnectionNotAuthorized() {
        
    }
    
    
}
