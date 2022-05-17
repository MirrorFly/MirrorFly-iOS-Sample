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
import Contacts

class MainTabBarController: UITabBarController{
    @IBOutlet weak var chatTabBars: UITabBar?
    
    let defaults = UserDefaults.standard
    
    static var isConnected = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupUI()
        updateSelection()
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
        self.chatTabBars?.backgroundColor = Color.navigationColor
        navigationController?.setNavigationBarHidden(true, animated: true)
        guard let items = tabBar.items else { return }
        items[0].title = chat
        items[1].title = contact
        items[2].title = call
        items[3].title = profile
        items[4].title = setting
        //Mark:- You can also set any custom fonts in the code
        let fontAttributes = [NSAttributedString.Key.font: UIFont.font12px_appLight()]
        UITabBarItem.appearance().setTitleTextAttributes(fontAttributes, for: .normal)
        self.chatTabBars?.backgroundColor = Color.navigationColor
    }
    
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
        if FlyDefaults.isFriendsListSyncPending {
            ContactManager.shared.getFriendsList(fromServer: true){isSuccess,_,_ in
                FlyDefaults.isFriendsListSyncPending = !isSuccess
            }
        }
    }
    
    func onDisconnected() {
        
    }
    
    func onConnectionNotAuthorized() {
        
    }
}

extension MainTabBarController : UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        updateSelection()
      }

      func updateSelection() {
        let normalFont = UIFont.font12px_appLight()
        let selectedFont = UIFont.font12px_appMedium()
        viewControllers?.forEach {
          let selected = $0 == self.selectedViewController
          $0.tabBarItem.setTitleTextAttributes([.font: selected ? selectedFont : normalFont], for: .normal)
        }
      }

}


