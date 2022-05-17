//
//  ChatViewModel.swift
//  MirrorflyUIkit
//
//  Created by Sowmiya T on 16/11/21.
//

import Foundation
import FlyCore
import FlyCommon

class
RecentChatViewModel  {
  
    func getRecentChatList(isBackground: Bool, completionHandler:  @escaping ([RecentChat]?)-> Void) {
        if isBackground {
            ChatManager.getRecentChatList { (isSuccess, flyError, resultDict) in
                let flydata = resultDict
                completionHandler(flydata[FlyConstants.data] as? [RecentChat])
            }
        } else {
            completionHandler(ChatManager.getRecentChatList())
        }
    }
    
    func getMessageOfId(messageId: String, completionHandler:  @escaping (ChatMessage?)-> Void) {
        if messageId.isEmpty {
            ChatManager.getRecentChatList { (isSuccess, flyError, resultDict) in
                var flydata = resultDict
                print(flydata.getData())
            }
        } else {
            completionHandler(ChatManager.getMessageOfId(messageId: messageId))
        }
    }
    
    func getDeleteChat(jid: String, completionHandler:  @escaping (Bool?)-> Void) {
        if !jid.isEmpty {
            ChatManager.deleteRecentChat(jid: jid)
            completionHandler(true)
        } else {
            completionHandler(false)
        }
    }
    
    func getGroupDetails(groupJid : String) -> ProfileDetails? {
        return GroupManager.shared.getAGroupFromLocal(groupJid: groupJid)
    }
    
    func getRecentChat(jid : String)-> RecentChat?{
        return ChatManager.getRechtChat(jid: jid)
    }
}

struct SelectedForwardMessage {
    var isSelected: Bool = false
    var chatMessage: ChatMessage = ChatMessage()
}
