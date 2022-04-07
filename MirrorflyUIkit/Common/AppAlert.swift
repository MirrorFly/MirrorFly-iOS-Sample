//
//  AppAlert.swift
//  MirrorflyUIkit
//
//  Created by User on 12/08/21.
//

import Foundation
import UIKit
import Toaster

class AppAlert: NSObject {

    //Singleton class
    static let shared = AppAlert()

    //MARK: - Delegate
    var onAlertAction : ((Int)->Void)?

    //Simple Alert view
    func showToast(message : String){
         let toast = Toast(text: message)
         toast.show()
    }
    
    func showAlert(view: UIViewController, buttonTitle: String) {

        let alert = UIAlertController(title: "", message: "", preferredStyle: UIAlertController.Style.alert)
        //okButton Action
        let okButton = UIAlertAction(title: buttonTitle, style: UIAlertAction.Style.default) {
            (result : UIAlertAction) -> Void in
            view.dismiss(animated: true, completion: nil)
            self.onAlertAction?(0)
        }
        alert.addAction(okButton)
        DispatchQueue.main.async {
            view.present(alert, animated: true, completion: nil)
        }
     
    }
    
    //Simple Alert view with button one
    func showAlert(view: UIViewController, title: String, message: String, buttonTitle: String) {

        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        //okButton Action
        let okButton = UIAlertAction(title: buttonTitle, style: UIAlertAction.Style.default) {
            (result : UIAlertAction) -> Void in
            view.dismiss(animated: true, completion: nil)
            self.onAlertAction?(0)
        }
        alert.addAction(okButton)
        DispatchQueue.main.async {
            view.present(alert, animated: true, completion: nil)
        }
     
    }

    //Simple Alert view with two button
    func showAlert(view: UIViewController, title: String? = nil, message: String, buttonOneTitle: String? = cancelUppercase.localized, buttonTwoTitle: String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)

        //Button One Action
        let buttonOne = UIAlertAction(title: buttonOneTitle, style: UIAlertAction.Style.default)  {
            (result : UIAlertAction) -> Void in
            //Cancel Action
            self.onAlertAction?(0)
            view.dismiss(animated: true, completion: nil)
        }
        
        //Button Two Action
        let buttonTwo = UIAlertAction(title: buttonTwoTitle,
                                      style: UIAlertAction.Style.default)
        {
            (result : UIAlertAction) -> Void in
            self.onAlertAction?(1)
        }
        
        alert.addAction(buttonOne)
        alert.addAction(buttonTwo)

        DispatchQueue.main.async {
            view.present(alert, animated: true, completion: nil)
        }
    }
}
