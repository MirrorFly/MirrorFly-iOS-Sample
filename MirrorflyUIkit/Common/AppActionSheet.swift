//
//  AppActionSheet.swift
//  MirrorflyUIkit
//
//  Created by John on 22/11/21.
//

import Foundation
import UIKit


class AppActionSheet : NSObject {
    
    public typealias SheetCallBack = (_ didCancelTap: Bool,_ tappedOption: String) -> Void
    
    public static let shared : AppActionSheet =  {
        return AppActionSheet()
    }()
    
    func showActionSeet(title : String, message : String, actions: [(String, UIAlertAction.Style)], titleBold : Bool = false ,sheetCallBack : @escaping SheetCallBack) {
        
        let mTitle = title.isEmpty ? nil : title
        let mMessage = message.isEmpty ? nil : message
        
        if !actions.isEmpty {
            let alertController = UIAlertController(title: mTitle, message: mMessage, preferredStyle: .actionSheet)
            
            if let mTitle = mTitle, mTitle.isNotEmpty, titleBold {
                
                let attributedString = NSAttributedString(string: mTitle, attributes: [
                    NSAttributedString.Key.font : UIFont.font18px_appSemibold(), //your font here
                    NSAttributedString.Key.foregroundColor : UIColor.blue,
                ])
                alertController.setValue(attributedString, forKey: "attributedTitle")
            }
            
            for (title, style) in actions {
                let alertAction = UIAlertAction(title: title, style: style) { (action) -> Void in
                    sheetCallBack(false, title)
                }
                alertController.addAction(alertAction)
            }
            let cancel = UIAlertAction(title: cancelUppercase, style: .cancel, handler: { (action) -> Void in
                sheetCallBack(true, cancelUppercase)
            })
            alertController.addAction(cancel)
            UIApplication.shared.keyWindow?.rootViewController?.present(alertController, animated: true, completion:nil)
        }
    }
}
