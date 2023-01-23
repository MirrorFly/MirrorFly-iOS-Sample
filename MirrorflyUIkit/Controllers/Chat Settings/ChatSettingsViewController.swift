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
    case ArchiveSettings = "Archive Settings"
    case TranslateMessage = "Translate Message"
    case lastseen = "Last Seen"
    //case UserBusyStatus = "User Busy Status"
    //case autodownload = "Auto Download"
    //case chatBackup = "ChatBackup"
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
        self.chatSettingsTable.register(UINib(nibName: Identifiers.chatBackupTableViewCell, bundle: nil), forCellReuseIdentifier: Identifiers.chatBackupTableViewCell)
        self.chatSettingsTable.register(UINib(nibName: Identifiers.clearAllChatTableViewCell, bundle: nil), forCellReuseIdentifier: Identifiers.clearAllChatTableViewCell)
        self.chatSettingsTable.delegate = self
        self.chatSettingsTable.dataSource = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.chatSettingsTable.reloadData()
        self.navigationController?.isNavigationBarHidden = true
    }

    override func viewDidAppear(_ animated: Bool) {
        ChatManager.shared.archiveEventsDelegate = self
    }

    override func viewWillDisappear(_ animated: Bool) {
        ChatManager.shared.archiveEventsDelegate = nil
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
            switch self.chatSettingsArray[indexPath.row] {
            case .TranslateMessage:
                let cell : ChatSettingsTableViewCell = tableView.dequeueReusableCell(withIdentifier: Identifiers.chatSettingsTableViewCell, for: indexPath) as! ChatSettingsTableViewCell
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
                return cell

            case .lastseen:
                let cell : ChatSettingsTableViewCell = tableView.dequeueReusableCell(withIdentifier: Identifiers.chatSettingsTableViewCell, for: indexPath) as! ChatSettingsTableViewCell
                cell.lblTitle.text = self.chatSettingsArray[indexPath.row].rawValue
                cell.helpTextLabel.text = hidingLastSeenActivityToOtherusers
                cell.selectedImageView.image = FlyDefaults.hideLastSeen ? UIImage(named: ImageConstant.ic_selected) : UIImage(named: ImageConstant.Translate_Unselected)
                cell.separaterView.isHidden = true
                cell.setCell(isArchive: false)
                return cell

//            case .autodownload:
//                let cell : ChatSettingsTableViewCell = tableView.dequeueReusableCell(withIdentifier: Identifiers.chatSettingsTableViewCell, for: indexPath) as! ChatSettingsTableViewCell
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
//                return cell

            case .ArchiveSettings:
                let cell : ChatSettingsTableViewCell = tableView.dequeueReusableCell(withIdentifier: Identifiers.chatSettingsTableViewCell, for: indexPath) as! ChatSettingsTableViewCell
                cell.lblTitle.text = self.chatSettingsArray[indexPath.row].rawValue
                cell.helpTextLabel.text = ArchiveSettingsDescription
                cell.selectSwitch.isOn = FlyDefaults.isArchivedChatEnabled
                cell.selectSwitch.isUserInteractionEnabled = false
                //cell.selectSwitch.addTarget(self, action: #selector(handleSwitch), for: .touchUpInside)
                cell.setCell(isArchive: true)
                return cell
//            case .chatBackup:
//                let cell : ChatBackupTableViewCell = tableView.dequeueReusableCell(withIdentifier: Identifiers.chatBackupTableViewCell, for: indexPath) as! ChatBackupTableViewCell
//                return cell
//            case .clearAllConversation:
//                let cell = chatSettingsTable.dequeueReusableCell(withIdentifier: Identifiers.clearAllChatTableViewCell, for: indexPath) as! ClearAllChatTableViewCell
//                cell.clearAllChat.text = self.chatSettingsArray[indexPath.row].rawValue
//                cell.clearAllChat.font = AppFont.Medium.size(14)
//                cell.clearAllChat.textColor = Color.clearAllConversation
//                return cell
//            case .UserBusyStatus:
//
//
//                let cell : ChatSettingsTableViewCell = tableView.dequeueReusableCell(withIdentifier: Identifiers.chatSettingsTableViewCell, for: indexPath) as! ChatSettingsTableViewCell
//                cell.lblTitle.text = self.chatSettingsArray[indexPath.row].rawValue
//                cell.helpTextLabel.text = setBusyStatusDescription
//                cell.selectedImageView.image = ChatManager.shared.isBusyStatusEnabled() ? UIImage(named: ImageConstant.ic_selected) : UIImage(named: ImageConstant.Translate_Unselected)
//                cell.defaultLanguageLabel.isHidden = true
//                cell.ChooseLangugaeLabel.text = editBusyStatus
//                cell.doubleTapLabel.text = ChatManager.shared.getMyBusyStatus().status
//                cell.separaterView.isHidden = ChatManager.shared.isBusyStatusEnabled() ? false : true
//                cell.defaultLanguageHeight.constant = 0
//                cell.doubleTapHeight.constant = 5
//                let tap = UITapGestureRecognizer(target: self, action: #selector(self.busyStatusHandle(_:)))
//                let formaImageViewTap = UITapGestureRecognizer(target: self, action: #selector(self.busyStatusHandle(_:)))
//                cell.helpTextView.addGestureRecognizer(tap)
//                cell.formaImageView.isUserInteractionEnabled = true
//                cell.formaImageView.addGestureRecognizer(formaImageViewTap)
//                cell.setCell(isArchive: false)
//                return cell
            }
            return UITableViewCell()
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

        case .ArchiveSettings:
            return unselectedCellHeight
//        case .chatBackup:
//            return 60
//        case .UserBusyStatus:
//            return ChatManager.shared.isBusyStatusEnabled() ? (selectedCellHeight - 22) : unselectedCellHeight
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let isInternetConnected = NetworkReachability.shared.isConnected

        switch chatSettingsArray[indexPath.row]{
        case .TranslateMessage:
            let cell:ChatSettingsTableViewCell = tableView.cellForRow(at: indexPath) as! ChatSettingsTableViewCell
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
//                            }
//                        }
//                    }else {
//                    }
//                }
//            }
//
//        case.autodownload:
//            FlyDefaults.autoDownloadEnable = !FlyDefaults.autoDownloadEnable
//            FlyDefaults.autoDownloadLastEnabledTime = FlyDefaults.autoDownloadEnable ? FlyUtils.getTimeInMillis() : 0

        case .ArchiveSettings:
            if isInternetConnected {
                FlyDefaults.isArchivedChatEnabled = !FlyDefaults.isArchivedChatEnabled
                ChatManager.enableDisableArchivedSettings(FlyDefaults.isArchivedChatEnabled) { isSuccess, error, data in
                    if !isSuccess {
                        FlyDefaults.isArchivedChatEnabled = !FlyDefaults.isArchivedChatEnabled
                    }
                }
            }

//        case .chatBackup:
//            //             let vc = BackupViewController(nibName: "BackupViewController", bundle: nil)
//            if let vc = UIStoryboard.init(name: Storyboards.backupRestore, bundle: Bundle.main).instantiateViewController(withIdentifier: Identifiers.backupViewController) as? BackupViewController {
//                self.navigationController?.pushViewController(vc, animated: true)
//            }
//
//
//        case .UserBusyStatus:
//            ChatManager.shared.enableDisableBusyStatus(!FlyDefaults.isUserBusyStatusEnabled)
        }
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

    @objc func busyStatusHandle(_ sender: UITapGestureRecognizer? = nil) {
        let storyboard = UIStoryboard(name: Storyboards.profile, bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "EditStatusViewController") as? EditStatusViewController {
            vc.isUserBusyStatus = true
            self.navigationController?.pushViewController(vc, animated: true)
        }
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

extension ChatSettingsViewController: ArchiveEventsDelegate {
    func updateArchiveUnArchiveChats(toUser: String, archiveStatus: Bool) {

    }

    func updateArchivedSettings(archivedSettingsStatus: Bool) {
        executeOnMainThread { [weak self] in
            self?.chatSettingsTable.reloadData()
        }
    }


}
