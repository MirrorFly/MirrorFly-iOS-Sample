//  ChatViewController.swift
//  MirrorflyUIkit
//  Created by User on 28/08/21.


import UIKit
import FlyCore
import FlyCommon
class ChatViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let chatManager = ChatManager.shared
        initiateChat()
        ChatManager.shared.connectionDelegate = self
       print( FlyDefaults.myJid)
        // Do any additional setup after loading the view.
    }
    func initiateChat() {
        let userName = Utility.getStringFromPreference(key: username)
        let userPassword = Utility.getStringFromPreference(key: password)
        FlyDefaults.myXmppPassword = userPassword
        FlyDefaults.myXmppUsername = userName
        let verifyOTPViewModel = VerifyOTPViewModel()
       verifyOTPViewModel.initializeChatCredentials(username: userName, secretKey: userPassword)
    }
    @IBAction func viewContact(_ sender: Any) {
//        let vc = UIStoryboard.init(name: Storyboards.chat, bundle: Bundle.main).instantiateViewController(withIdentifier: Identifiers.chatViewParentController) as? ChatViewParentController
//        self.navigationController?.pushViewController(vc!, animated: true)
        let storyboard = UIStoryboard.init(name: Storyboards.main, bundle: nil)
        let mainTabBarController = storyboard.instantiateViewController(withIdentifier: Identifiers.contactViewController) as! ContactViewController
        self.navigationController?.pushViewController(mainTabBarController, animated: true)
    }
}
extension ChatViewController : ConnectionEventDelegate {
    
    func onConnected() {
        
    }
    func onDisconnected() {
        
    }
    
    func onConnectionNotAuthorized() {
        
    }
}
