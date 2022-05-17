//
//  ViewControllerExtension.swift
//  MirrorflyUIkit
//
//  Created by User on 19/08/21.
//

import Foundation
import UIKit
import FlyCommon
import FlyCore

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func setUpStatusBar() {
        if #available(iOS 13.0, *) {
            let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
            let statusBarFrame = window?.windowScene?.statusBarManager?.statusBarFrame
            let statusBarView = UIView(frame: statusBarFrame!)
            self.view.addSubview(statusBarView)
            statusBarView.backgroundColor = Color.navigationColor
        } else {
            let statusBarFrame = UIApplication.shared.statusBarFrame
            let statusBarView = UIView(frame: statusBarFrame)
            self.view.addSubview(statusBarView)
            statusBarView.backgroundColor = Color.navigationColor
        }
    }
    
    func handleBackgroundAndForground() {
        if #available(iOS 13.0, *) {
            NotificationCenter.default.addObserver(self, selector: #selector(didMoveToBackground), name: UIScene.willDeactivateNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(willCometoForeground), name: UIScene.willEnterForegroundNotification, object: nil)
        } else {
            NotificationCenter.default.addObserver(self, selector: #selector(didMoveToBackground), name: UIApplication.willResignActiveNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(willCometoForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        }
    }

    
    @objc func didMoveToBackground() {
        print("UIViewController moved to background")
        
    }
    
    @objc func willCometoForeground() {
        print("UIViewController appComestoForeground")
    }
    
    func exitApp() {
        executeOnMainThread {
            exit(0)
        }
    }
    
    func removeAdminBlockedContact(profileList : [ProfileDetails], jid : String, isBlockedByAdmin : Bool) -> [ProfileDetails]{
        var tempProfileList = profileList
        if tempProfileList.isEmpty {
            return tempProfileList
        }
        
        tempProfileList.filter({$0.jid == jid}).first?.isBlockedByAdmin = isBlockedByAdmin
        tempProfileList = tempProfileList.filter({!$0.isBlockedByAdmin})
        
        return tempProfileList
    }
    
    func addUnBlockedContact(profileList:  [ProfileDetails], jid: String, isBlockedByAdmin : Bool) -> [ProfileDetails]{
        var tempProfileList = profileList
        if tempProfileList.isEmpty {
            return tempProfileList
        }
        
        if let _ = tempProfileList.filter({$0.jid == jid}).first {
            return tempProfileList
        }
        
        if let profile = ChatManager.profileDetaisFor(jid: jid) {
            tempProfileList.append(profile)
        }
        
        tempProfileList = tempProfileList.sorted { getUserName(jid: $0.jid, name: $0.name, nickName: $0.nickName, contactType: $0.contactType).capitalized < getUserName(jid: $1.jid, name: $1.name, nickName: $1.nickName, contactType: $1.contactType).capitalized }
        
        return tempProfileList
    }
    
    func checkAndAddRecentChat(recentChatList : [RecentChat], jid : String, isBlockedByAdmin : Bool) -> [RecentChat] {
        var tempRecent = recentChatList
        if tempRecent.isEmpty {
            return tempRecent
        }
        
        if let _ = tempRecent.filter({$0.jid == jid}).first {
            return tempRecent
        }
        
        if let recent = ChatManager.getRechtChat(jid: jid) {
            tempRecent.append(recent)
        }
        
        return tempRecent
    }
    
    func removeAdminBlockedRecentChat(recentChatList : [RecentChat], jid : String, isBlockedByAdmin : Bool) -> [RecentChat] {
        var tempRecent = recentChatList
        if tempRecent.isEmpty {
            return tempRecent
        }
        
        tempRecent.filter({$0.jid == jid}).first?.isBlockedByAdmin = isBlockedByAdmin
        tempRecent = tempRecent.filter({!$0.isBlockedByAdmin})
        
        return tempRecent
    }
}
