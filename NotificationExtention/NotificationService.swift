//
//  NotificationService.swift
//  notificationextention
//
//  Created by User on 10/11/21.
//

import UserNotifications
import FlyCall
import FlyXmpp
import FlyCore
import FlyCommon

class NotificationService: UNNotificationServiceExtension {
    
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        let payloadType = bestAttemptContent?.userInfo["type"] as? String
        print("Push Received UserInfo \(String(describing: bestAttemptContent?.userInfo))")
        CallManager.setAppGroupContainerId(id: "group.com.mirrorfly.qa")
        if payloadType == "media_call" {
            NotificationExtensionSupport.shared.didReceiveNotificationRequest(request.content.mutableCopy() as? UNMutableNotificationContent, onCompletion: { [self] bestAttemptContent in
                if let userInfo = bestAttemptContent?.userInfo["message_id"] {
                    print("Push Show title: \(bestAttemptContent?.title ?? "") body: \(bestAttemptContent?.body ?? ""), ID - \(userInfo)")
                }
                self.bestAttemptContent = bestAttemptContent
                contentHandler(self.bestAttemptContent!)
            })
        }
        else {
            ChatSDK.Builder.initializeDelegate()
            // Handle Message Push messages
            print("Push Received UserInfo \(String(describing: bestAttemptContent?.userInfo))")
            NotificationMessageSupport.shared.didReceiveNotificationRequest(request.content.mutableCopy() as? UNMutableNotificationContent, onCompletion: { [self] bestAttemptContent in
                if let userInfo = bestAttemptContent?.userInfo["message_id"] {
                    print("Push Show title: \(bestAttemptContent?.title ?? "") body: \(bestAttemptContent?.body ?? ""), ID - \(userInfo)")
                }
                self.bestAttemptContent = bestAttemptContent
                contentHandler(self.bestAttemptContent!)
            })
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}
