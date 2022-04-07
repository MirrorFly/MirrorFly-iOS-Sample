//
//  ContactViewModel.swift
//  MirrorflyUIkit
//
//  Created by User on 29/08/21.
//

import Foundation
import FlyCore
import FlyCommon
class ContactViewModel : NSObject
{
    
    override init() {
        super.init()
        
    }
    func getContacts(fromServer: Bool, completionHandler:  @escaping ([ProfileDetails]?, String?)-> Void) {
        ContactManager.shared.getFriendsList(fromServer: fromServer) {  isSuccess, flyError, flyData in
            var data  = flyData
            if isSuccess {
                if  let  contactsList = data.getData() as? [ProfileDetails]  {
                    let filteredContact = contactsList.filter( {$0.profileChatType != .groupChat && $0.jid != FlyDefaults.myJid})
                    completionHandler(filteredContact, nil)
                }else {
                    completionHandler(nil, data.getMessage() as? String)
                }
            } else{
                completionHandler(nil, data.getMessage() as? String)
            }
        }
    }
    
    func syncContacts(){
        ContactSyncManager.shared.syncContacts(firstLogin: false) { isSuccess, error, data in
            if isSuccess{
                print("#contact sync SUCCESS")
            }else {
                print("#contact sync Failed \(error?.localizedDescription)")
            }
        }
    }
}
