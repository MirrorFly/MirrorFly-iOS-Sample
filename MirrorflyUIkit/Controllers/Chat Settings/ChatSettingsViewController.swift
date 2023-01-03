//
//  AboutandHelpViewController.swift
//  MirrorflyUIkit
//
//  Created by user on 28/02/22.
//

import UIKit
import FlyCommon
import FlyCore

protocol ClearAllChatsDelegate {
    func clearAllConversations(isCleared : Bool)
}

enum ChatSettingList: String, CaseIterable {
    //case ArchiveSettings = "Archive Settings"
    case TranslateMessage = "Translate Message"
    case lastseen = "Last Seen"
    //case autodownload = "Auto Download"
    //case clearAllConversation = "Clear All Conversation"

}

class ChatSettingsViewController: UIViewController {
    
    @IBOutlet weak var chatSettingsTable: UITableView!
    private var chatSettingsArray = ChatSettingList.allCases
    let selectedCellHeight: CGFloat = 160.0
    let unselectedCellHeight: CGFloat = 80.0
    let clearAllChatsHeight: CGFloat = 60.0
    var clearBadgeCountDelegate : ClearAllChatsDelegate?
   
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.chatSettingsTable.register(UINib(nibName: Identifiers.chatSettingsTableViewCell, bundle: nil), forCellReuseIdentifier: Identifiers.chatSettingsTableViewCell)
        self.chatSettingsTable.register(UINib(nibName: Identifiers.clearAllChatTableViewCell, bundle: nil), forCellReuseIdentifier: Identifiers.clearAllChatTableViewCell)
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
//
//        if self.chatSettingsArray[indexPath.row].rawValue == ChatSettingList.clearAllConversation.rawValue {
//            let cell = chatSettingsTable.dequeueReusableCell(withIdentifier: Identifiers.clearAllChatTableViewCell, for: indexPath) as! ClearAllChatTableViewCell
//            cell.clearAllChat.text = self.chatSettingsArray[indexPath.row].rawValue
//            cell.clearAllChat.font = AppFont.Medium.size(14)
//            cell.clearAllChat.textColor = Color.clearAllConversation
//            return cell
//        } else {
            
            let cell : ChatSettingsTableViewCell = tableView.dequeueReusableCell(withIdentifier: Identifiers.chatSettingsTableViewCell, for: indexPath) as! ChatSettingsTableViewCell
            
            switch self.chatSettingsArray[indexPath.row] {
            case .TranslateMessage:
                cell.lblTitle.text = self.chatSettingsArray[indexPath.row].rawValue
                cell.defaultLanguageHeight.constant = 14.5
                cell.defaultLanguageLabel.text = FlyDefaults.selectedLanguage
                cell.defaultLanguageLabel.isHidden = false
                cell.helpTextLabel.text =  enableTranslateMessageToChooseTranslationLanguage
                cell.ChooseLangugaeLabel.text = chooseTranslationLaguage
                cell.doubleTapLabel.text =  doubleTapTheReceivedMessageToTranslate
                cell.separaterView.isHidden = true
                cell.selectedImageView.image = FlyDefaults.isTranlationEnabled ? UIImage(named: ImageConstant.ic_selected) : UIImage(named: ImageConstant.Translate_Unselected)
                let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
                let formaImageViewTap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
                cell.helpTextView.addGestureRecognizer(tap)
                cell.formaImageView.isUserInteractionEnabled = true
                cell.formaImageView.addGestureRecognizer(formaImageViewTap)
                cell.setCell(isArchive: false)
                break
            case .lastseen:
                cell.lblTitle.text = self.chatSettingsArray[indexPath.row].rawValue
                cell.helpTextLabel.text = hidingLastSeenActivityToOtherusers
                cell.selectedImageView.image = FlyDefaults.hideLastSeen ? UIImage(named: ImageConstant.ic_selected) : UIImage(named: ImageConstant.Translate_Unselected)
                cell.separaterView.isHidden = true
                cell.setCell(isArchive: false)
                break
//            case .autodownload:
//                cell.lblTitle.text = self.chatSettingsArray[indexPath.row].rawValue
//                cell.helpTextLabel.text = enableAutodownlaodToTurnAllTypes
//                cell.selectedImageView.image = FlyDefaults.autoDownloadEnable ? UIImage(named: ImageConstant.ic_selected) : UIImage(named: ImageConstant.Translate_Unselected)
//                cell.defaultLanguageLabel.isHidden = true
//                cell.ChooseLangugaeLabel.text = dataUsageSettings
//                cell.doubleTapLabel.text = setupYourMobileAndWifiDataUsageBasedOnMediaType
//                cell.separaterView.isHidden = FlyDefaults.autoDownloadEnable ? false : true
//                cell.defaultLanguageHeight.constant = 0
//                cell.doubleTapHeight.constant = 5
//                let tap = UITapGestureRecognizer(target: self, action: #selector(self.download(_:)))
//                let formaImageViewTap = UITapGestureRecognizer(target: self, action: #selector(self.download(_:)))
//                cell.helpTextView.addGestureRecognizer(tap)
//                cell.formaImageView.isUserInteractionEnabled = true
//                cell.formaImageView.addGestureRecognizer(formaImageViewTap)
//                cell.setCell(isArchive: false)
//                break
//            case .ArchiveSettings:
//                cell.lblTitle.text = self.chatSettingsArray[indexPath.row].rawValue
//                cell.helpTextLabel.text = ArchiveSettingsDescription
//                cell.selectSwitch.isOn = FlyDefaults.isArchivedChatEnabled
//                cell.selectSwitch.addTarget(self, action: #selector(handleSwitch), for: .touchUpInside)
//                cell.setCell(isArchive: true)
            default:
                break
                
            }
            return cell
        //}
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch chatSettingsArray[indexPath.row] {
        case .TranslateMessage:
            return FlyDefaults.isTranlationEnabled ? selectedCellHeight : unselectedCellHeight
            
        case .lastseen:
            return unselectedCellHeight
            
//        case .clearAllConversation:
//            return clearAllChatsHeight
//
//        case .autodownload:
//            return FlyDefaults.autoDownloadEnable ? selectedCellHeight : unselectedCellHeight
//
//        case .ArchiveSettings:
//            return unselectedCellHeight

        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let isInternetConnected = NetworkReachability.shared.isConnected
//        if self.chatSettingsArray[indexPath.row].rawValue == ChatSettingList.clearAllConversation.rawValue {
//            if isInternetConnected {
//                AppAlert.shared.showAlert(view: self,
//                                          message: clearAllChat,
//                                          buttonOneTitle: yesButton,
//                                          buttonTwoTitle: noButton)
//                AppAlert.shared.onAlertAction = { [weak self] (result) ->
//                    Void in
//                    if result == 0 {
//                        print("clearAllConversation")
//                        self?.startLoading(withText: "")
//                        ChatManager.shared.clearAllConversation{ isSuccess, error, data in
//                            executeOnMainThread {
//                                AppAlert.shared.onAlertAction = nil
//                            }
//                            if isSuccess{
//                                self?.clearBadgeCountDelegate?.clearAllConversations(isCleared: true)
//                                self?.stopLoading()
//                                AppAlert.shared.showToast(message: allYourConversationareCleared )
//                            }
//                            else{
//                                self?.clearBadgeCountDelegate?.clearAllConversations(isCleared: false)
//                                print("failed")
//                                self?.stopLoading()
//                                AppAlert.shared.showToast(message: serverError )
//
//                            }
//
//                        }
//                    }else {
//
//                    }
//
//                }
//
//            }
//
//        }
//
//        else{
        let cell:ChatSettingsTableViewCell = tableView.cellForRow(at: indexPath) as! ChatSettingsTableViewCell
       
        switch chatSettingsArray[indexPath.row]{
        case .TranslateMessage:
            if isInternetConnected {
                FlyDefaults.isTranlationEnabled = !FlyDefaults.isTranlationEnabled
                cell.defaultLanguageLabel.text = FlyDefaults.selectedLanguage
            }
        case .lastseen:
            if isInternetConnected {
                FlyDefaults.hideLastSeen = !FlyDefaults.hideLastSeen
                ChatManager.enableDisableHideLastSeen( EnableLastSeen:FlyDefaults.hideLastSeen ) { isSuccess, flyError, flyData in
                    print(flyData)
                }
            }
//        case .clearAllConversation:
//         break
//
//        case.autodownload:
//            FlyDefaults.autoDownloadEnable = !FlyDefaults.autoDownloadEnable
//
//
//        case .ArchiveSettings:
//            if isInternetConnected {
//                FlyDefaults.isArchivedChatEnabled = !FlyDefaults.isArchivedChatEnabled
//                ChatManager.enableDisableArchivedSettings(FlyDefaults.isArchivedChatEnabled) { isSuccess, error, data in
//                    if !isSuccess {
//                        FlyDefaults.isArchivedChatEnabled = !FlyDefaults.isArchivedChatEnabled
//                    }
//                }
//            }

        }
    //}
        if !isInternetConnected {
            AppAlert.shared.showToast(message: ErrorMessage.noInternet)
        }
        animateCellHeighChangeForTableView(tableView: tableView, withDuration: 0.3)
        chatSettingsTable.reloadData()
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

    @objc func download(_ sender: UITapGestureRecognizer? = nil) {
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let nextViewController = storyBoard.instantiateViewController(withIdentifier: "AutodownloadSelectionViewController") as! AutodownloadSelectionViewController
        self.navigationController?.pushViewController(nextViewController, animated: true)
    }

    @objc func handleSwitch(_ sender: UISwitch) {
        if NetworkReachability.shared.isConnected {
            FlyDefaults.isArchivedChatEnabled = !FlyDefaults.isArchivedChatEnabled
            ChatManager.enableDisableArchivedSettings(FlyDefaults.isArchivedChatEnabled) { isSuccess, error, data in
                if !isSuccess {
                    FlyDefaults.isArchivedChatEnabled = !FlyDefaults.isArchivedChatEnabled
                }
            }
        }
    }
}
