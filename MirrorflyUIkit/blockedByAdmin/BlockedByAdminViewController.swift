//
//  BlockedByAdminViewController.swift
//  UiKitQa
//
//  Created by John on 18/04/22.
//

import UIKit

class BlockedByAdminViewController: UIViewController {

    @IBOutlet weak var emailLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emailLabel.underLine(text: adminEmail)
    }
    
    @IBAction func didTapOkButton(_ sender: Any) {
        exitApp()
    }
    
}
