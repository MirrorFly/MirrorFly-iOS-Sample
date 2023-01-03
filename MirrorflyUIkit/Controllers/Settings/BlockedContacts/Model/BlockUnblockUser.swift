//
//  BlockUnblockUser.swift
//  UiKitQa
//
//  Created by Amose Vasanth on 02/12/22.
//

import Foundation
import FlyCore
import FlyCommon

class BlockUnblockViewModel: NSObject {

    static func unblockUser(jid: String,  completionHandler : @escaping FlyCompletionHandler) {
        if NetworkReachability.shared.isConnected {
            do {
                try ContactManager.shared.unblockUser(for: jid) { isSuccess, error, data in
                    completionHandler(isSuccess,error,data)
                }
            } catch let error as NSError {
                print("block user error: \(error)")
            }
        } else {
            AppAlert.shared.showToast(message: ErrorMessage.checkYourInternet)
        }
    }

}
