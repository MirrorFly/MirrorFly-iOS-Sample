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
    @IBOutlet weak var tblSettings : UITableView!
    @IBOutlet weak var lblVersion: UILabel!
    //@IBOutlet weak var lblLatestRelease: UILabel!
    
    //private var settingsArr = ["Chats","Starred Messages","Notifications","Blocked Contacts","Archived Chats","About and Help","App Lock","Connection Label", "Logout"]
    
    private var settingsArr = ["Chats","About and Help","Delete My Account","Logout"]

    override func viewDidLoad() {
        let info = Bundle.main.infoDictionary
        let appVersion = info?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let appBuild = info?[kCFBundleVersionKey as String] as? String ?? "Unknown"
        
        let appVersionString = "Version \(appVersion)(\(appBuild))"
        self.lblVersion.text = appVersionString
        //   self.lblLatestRelease.isHidden = true
        self.tblSettings.register(UINib(nibName: "SettingsTableViewCell", bundle: nil), forCellReuseIdentifier: "SettingsTableViewCell")
        self.tblSettings.delegate = self
        self.tblSettings.dataSource = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        AppAlert.shared.onAlertAction = nil
    }
    
    
    
 func onLogout() {
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
                ChatManager.disconnect()
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


extension SettingsViewController : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell : SettingsTableViewCell = tableView.dequeueReusableCell(withIdentifier: "SettingsTableViewCell", for: indexPath) as! SettingsTableViewCell
        cell.lblTitle.text = self.settingsArr[indexPath.row]
        cell.imgicon.image = UIImage(named: self.settingsArr[indexPath.row])
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.settingsArr.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch self.settingsArr[indexPath.row] {
            
        case "Chats":
            if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ChatSettingsViewController") as? ChatSettingsViewController {
                self.navigationController?.pushViewController(vc, animated: true)
            }
            break
        case "About and Help":
            if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AboutandHelpViewController") as? AboutandHelpViewController {
                self.navigationController?.pushViewController(vc, animated: true)
            }
            
            break
        case "Delete My Account":
            if let vc = UIStoryboard(name: "Profile", bundle: nil).instantiateViewController(withIdentifier: "DeleteMyAccountVC") as? DeleteMyAccountVC {
                self.navigationController?.pushViewController(vc, animated: true)
            }
            break
        case "Logout":
            self.onLogout()
            break
        default :
            break
        }
        
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    
}
