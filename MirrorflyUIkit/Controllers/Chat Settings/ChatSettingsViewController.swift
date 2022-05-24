//
//  AboutandHelpViewController.swift
//  MirrorflyUIkit
//
//  Created by user on 28/02/22.
//

import UIKit
import FlyCommon

class ChatSettingsViewController: UIViewController {
    
    @IBOutlet weak var chatSettingsTable: UITableView!
    private var chatSettingsArray = ["Translate Message"]
    let selectedCellHeight: CGFloat = 160.0
    let unselectedCellHeight: CGFloat = 80.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.chatSettingsTable.register(UINib(nibName: Identifiers.ChatSettingsTableViewCell, bundle: nil), forCellReuseIdentifier: Identifiers.ChatSettingsTableViewCell)
        self.chatSettingsTable.delegate = self
        self.chatSettingsTable.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.chatSettingsTable.reloadData()
        self.navigationController?.isNavigationBarHidden = true
    }
    
    @IBAction func onTapBack(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
}

//MARK: - Tableview
extension ChatSettingsViewController : UITableViewDelegate,UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.chatSettingsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell : ChatSettingsTableViewCell = tableView.dequeueReusableCell(withIdentifier: Identifiers.ChatSettingsTableViewCell, for: indexPath) as! ChatSettingsTableViewCell
        
        switch self.chatSettingsArray[indexPath.row] {
        case "Translate Message":
            cell.lblTitle.text = self.chatSettingsArray[indexPath.row]
            cell.defaultLanguageLabel.text = FlyDefaults.selectedLanguage
            cell.helpTextLabel.text = "Enable Translate Message to choose Translation Language"
            cell.selectedImageView.image = FlyDefaults.isTranlationEnabled ? UIImage(named: ImageConstant.ic_selected) : UIImage(named: ImageConstant.Translate_Unselected)
            let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
            let formaImageViewTap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
            cell.helpTextView.addGestureRecognizer(tap)
            cell.formaImageView.isUserInteractionEnabled = true
            cell.formaImageView.addGestureRecognizer(formaImageViewTap)
            break
        default:
            break
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if FlyDefaults.isTranlationEnabled {
            return selectedCellHeight
        }
        return unselectedCellHeight
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell:ChatSettingsTableViewCell = tableView.cellForRow(at: indexPath) as! ChatSettingsTableViewCell
        
        if indexPath.row == 0 && FlyDefaults.isTranlationEnabled == false {
            
            if NetworkReachability.shared.isConnected {
                cell.selectedImageView.image = UIImage(named: ImageConstant.ic_selected)
                cell.defaultLanguageLabel.text = FlyDefaults.selectedLanguage
                FlyDefaults.isTranlationEnabled = true
            } else {
                AppAlert.shared.showToast(message: ErrorMessage.noInternet)
            }
            
        }
        else if FlyDefaults.isTranlationEnabled == true {
            
            cell.selectedImageView.image = UIImage(named: ImageConstant.Translate_Unselected)
            FlyDefaults.isTranlationEnabled = false
        }
        animateCellHeighChangeForTableView(tableView: tableView, withDuration: 0.3)
    }
    
    private func animateCellHeighChangeForTableView(tableView: UITableView, withDuration duration: Double) {
        UIView.animate(withDuration: duration) { () -> Void in
        // These two calls make the cell animate to its new height
            tableView.beginUpdates()
            tableView.endUpdates()
        }
    }
    
    //MARK: - Handling Tap
    
    @objc func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        
        if NetworkReachability.shared.isConnected {
            if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: Identifiers.LanguageSelectionViewController) as? LanguageSelectionViewController {
                self.navigationController?.pushViewController(vc, animated: true)
            }
        } else {
            AppAlert.shared.showToast(message: ErrorMessage.noInternet)
        }
    }
}
