//
//  GroupInfoViewModel.swift
//  MirrorflyUIkit
//
//  Created by Prabakaran M on 09/03/22.
//

import Foundation
import FlyDatabase
import FlyCommon
import FlyCore

class GroupInfoViewModel: NSObject {
    
    // MARK: - Properties
    
    var databaseController : FlyDatabaseController?
    
    override init() {
        databaseController = FlyDatabaseController.shared
    }
    
    // MARK: - Public Methods
    
    func getContactInfo(jid : String) -> ProfileDetails? {
        return databaseController?.rosterManager.getContact(jid: jid)
    }
    
    func muteNotification(jid : String, mute : Bool) {
        ChatManager.updateChatMuteStatus(jid: jid, muteStatus: mute)
    }
    
    func makeGroupAdmin(groupID: String, userJid: String,
                        completionHandler: @escaping (Bool) -> Void) {
        
        try! GroupManager.shared.makeAdmin(groupJid: groupID, userJid: userJid) {
            isSuccess,error,data in
            
            if isSuccess {
                print("SUCCESSSS")
            }
            completionHandler(isSuccess)
        }
    }
}
