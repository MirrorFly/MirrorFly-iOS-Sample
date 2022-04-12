//  ChatViewController.swift
//  MirrorflyUIkit
//  Created by User on 28/08/21.


import UIKit
import FlyCore
import FlyCommon
import SDWebImage
import AVKit

class RecentChatViewController: UIViewController, UIGestureRecognizerDelegate {
   
    @IBOutlet weak var recentChatTableView: UITableView?
    @IBOutlet weak var searchBar: UISearchBar?
    @IBOutlet weak var emptyMessageView: UIView?
    @IBOutlet weak var descriptionMessageText: UILabel?
    @IBOutlet weak var noNewMsgText: UILabel?
    @IBOutlet weak var emptyImage: UIImageView?
    @IBOutlet weak var profilePopupContainer: UIView?
    @IBOutlet weak var username: UILabel?
    @IBOutlet weak var userImage: UIImageView?
    @IBOutlet weak var chatTabBarItem: UITabBarItem?
    @IBOutlet weak var selectionCountLabel: UILabel?
    @IBOutlet weak var multipleSelectionView: UIView?
    @IBOutlet weak var headerView: UIView?
    @IBOutlet weak var deleteChatButton: UIButton?
    @IBOutlet weak var stackView: UIStackView?
    
    var longPressCount = 0
    var isCellLongPressed: Bool? = false
    var getRecentChat: [RecentChat] = []
    var getAllRecentChat: [RecentChat] = []
    var filteredContactList =  [ProfileDetails]()
    var allContactsList =  [ProfileDetails]()
    var unreadMessageChatList: [RecentChat] = []
    var allUnreadMessageChatList: [RecentChat] = []
    var isSearchEnabled: Bool = false
   // var randomColors = [UIColor?]()
    let chatManager = ChatManager.shared
    var currentIndex = 0
    private var contactViewModel : ContactViewModel?
    private var recentChatViewModel: RecentChatViewModel?
    private var selectionRecentChatList: [RecentChat] = []
    private var replyMessageObj: ChatMessage?
    private var replyJid: String?
    private var messageTxt: String?
    var tappedProfile : ProfileDetails? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        contactViewModel =  ContactViewModel()
        recentChatViewModel = RecentChatViewModel()
        if FlyDefaults.isTrialLicense{
            ProfileViewModel().contactSync()
        }
        setupTableviewLongPressGesture()
        handleBackgroundAndForground()
        configTableView()
        NotificationCenter.default.addObserver(self, selector: #selector(self.contactSyncCompleted(notification:)), name: NSNotification.Name(FlyConstants.contactSyncState), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureDefaults()
        getRecentChatList()
        getContactList()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(FlyConstants.contactSyncState), object: nil)
        ContactManager.shared.profileDelegate = nil
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func configureDefaults() {
        FlyMessenger.shared.messageEventsDelegate = self
        chatManager.messageEventsDelegate = self
        chatManager.connectionDelegate = self
        GroupManager.shared.groupDelegate = self
        ContactManager.shared.profileDelegate = self
    }
    
    private func configTableView() {
        searchBar?.delegate = self
        recentChatTableView?.estimatedRowHeight = 65.0
        UITableViewHeaderFooterView.appearance().tintColor = Color.recentChatHeaderSectionColor
        profilePopupContainer?.isHidden = true
        recentChatTableView?.delegate = self
        recentChatTableView?.dataSource = self
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        profilePopupContainer?.addGestureRecognizer(tap)
    }
    
    func setupTableviewLongPressGesture() {
        let longPressGesture:UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector( handleCellLongPress))
        longPressGesture.delegate = self
        recentChatTableView?.addGestureRecognizer(longPressGesture)
    }

    @objc func contactSyncCompleted(notification: Notification){
        if let contactSyncState = notification.userInfo?[FlyConstants.contactSyncState] as? String {
            switch ContactSyncState(rawValue: contactSyncState) {
            case .inprogress:
                break
            case .success:
                getRecentChatList()
            case .failed:
                print("contact sync failed")
            case .none:
                print("contact sync failed")
            }
        }
    }
    
    @objc func handleCellLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began && isSearchEnabled == false {
            let touchPoint = gestureRecognizer.location(in:  recentChatTableView)
            if let indexPath =  recentChatTableView?.indexPathForRow(at: touchPoint) {
                if getRecentChat[indexPath.row].profileType == .singleChat {
                    if let cell =  recentChatTableView?.cellForRow(at: indexPath) as? RecentChatTableViewCell {
                        if selectionRecentChatList.filter({$0.jid == getRecentChat[indexPath.row].jid}).count == 0 {
                            cell.contentView.backgroundColor = Color.recentChatSelectionColor
                            isCellLongPressed = true
                            recentChatTableView?.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                            showHideDeleteButton()
                            getRecentChat[indexPath.row].isSelected = !getRecentChat[indexPath.row].isSelected
                            selectionRecentChatList.insert(getRecentChat[indexPath.row], at: 0)
                            longPressCount += 1
                            hideHeaderView()
                            selectionCountLabel?.isHidden = false
                        }
                    }
                    if(longPressCount >= 1) {
                        selectionCountLabel?.text =  String( longPressCount)
                    }
                    showHideDeleteButton()
                    recentChatTableView?.allowsMultipleSelection = true
                }
            }
        }
    }

    @objc func imageButtonAction(_ sender:AnyObject){
        closeKeyboard()
        UIView.transition(with: profilePopupContainer ?? UIView(), duration: 0.5, options: .transitionCrossDissolve, animations: { [weak self] in
            if let weakSelf = self {
                weakSelf.profilePopupContainer?.isHidden = false
            }
        })
        if  let buttonTag = sender.tag {
            currentIndex = buttonTag
            setProfile()
        }
    }
    
    @objc func closeKeyboard() {
        self.view.endEditing(true)
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        UIView.transition(with: profilePopupContainer ?? UIView(), duration: 0.5, options: .transitionFlipFromLeft, animations: { [weak self] in
            if let weakSelf = self {
                weakSelf.profilePopupContainer?.isHidden = true
            }
        })
    }
    
    @IBAction func closeButtonTapped(_ sender: Any) {
       showHeaderView()
        longPressCount = 0
        isCellLongPressed = false
        selectionCountLabel?.text = String(longPressCount)
        selectionRecentChatList.enumerated().forEach { (index, element) in
        if let cell =  recentChatTableView?.cellForRow(at: IndexPath(row: index, section: 0)) as? RecentChatTableViewCell {
            cell.contentView.backgroundColor = .clear
            }
        }
        clearSelectedColor()
        selectionRecentChatList = []
    }
    
    @IBAction func viewContact(_ sender: Any) {
        navigateTo(identifier: Identifiers.contactViewController)
    }
    @IBAction func createGroup(_ sender: Any) {
        print("createGroup")
        let values : [String] = CreateGroupOptions.allCases.map { $0.rawValue }
        var actions = [(String, UIAlertAction.Style)]()
        values.forEach { title in
            actions.append((title, UIAlertAction.Style.default))
        }
        AppActionSheet.shared.showActionSeet(title : "", message: "",actions: actions , sheetCallBack: { [weak self] didCancelTap, tappedTitle in
            if !didCancelTap {
                switch tappedTitle {
                case CreateGroupOptions.createGroup.rawValue:
                    self?.navigateTo(identifier: Identifiers.createNewGroup)
//                case CreateGroupOptions.broadCastList.rawValue:
//                        print(" \(tappedTitle)")
                case CreateGroupOptions.web.rawValue:
                    self?.checkCameraPermission()
                    default:
                        print(" \(tappedTitle)")
                }
            } else {
                print("createGroup Cancel")
            }
        })
    }
    
    func checkCameraPermission() {
        AppPermissions.shared.checkCameraPermissionAccess(permissionCallBack: { [weak self] authorizationStatus in
            switch authorizationStatus {
            case .denied:
                AppPermissions.shared.presentCameraSettings(instance: self as Any)
                break
            case .restricted:
                break
            case .authorized:
                executeOnMainThread {
                    self?.navigateTo(identifier: Identifiers.qrCodeScaner)
                }
                break
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    if granted {
                        executeOnMainThread {
                            self?.navigateTo(identifier: Identifiers.qrCodeScaner)
                        }
                    } else {
                        print("Denied access to")
                    }
                }
                break
            @unknown default:
                print("Permission failed")
            }
        })
        
    }
    
    
    func navigateTo(identifier : String) {
        let storyboard = UIStoryboard.init(name: Storyboards.main, bundle: nil)
        if identifier == Identifiers.contactViewController {
            if navigationController?.viewControllers[0] is ContactViewController {
                return
            } else {
                guard let mainTabBarController = storyboard.instantiateViewController(withIdentifier: identifier) as? ContactViewController else { return }
                mainTabBarController.hideNavigationbar = true
                mainTabBarController.replyMessageObj = replyMessageObj
                mainTabBarController.replyJid = replyJid
                mainTabBarController.messageTxt = messageTxt
                mainTabBarController.replyTagDelegate = self
                self.navigationController?.pushViewController(mainTabBarController, animated: true)
            }
        } else if identifier == Identifiers.createNewGroup {
            guard let mainTabBarController = storyboard.instantiateViewController(withIdentifier: identifier) as? NewGroupViewController else { return }
            mainTabBarController.groupCreationDeletgate = self
            self.navigationController?.pushViewController(mainTabBarController, animated: true)
        } else if identifier == Identifiers.qrCodeScaner {
            guard let qrCodeScanner = storyboard.instantiateViewController(withIdentifier: identifier) as? QRCodeScanner else { return }
            self.navigationController?.pushViewController(qrCodeScanner, animated: true)
        } 
    }
    
    @IBAction func deleteRecentChatButtonTapped(_ sender: Any) {
        let storyboard = UIStoryboard.init(name: Storyboards.main, bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: Identifiers.deleteChatAlert) as? DeleteAlertViewController
        controller?.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        let current = UIApplication.shared.keyWindow?.getTopViewController()
        if let deleteAlertViewController = controller {
            current?.present(deleteAlertViewController, animated: false, completion: { [weak self] in
                if self?.selectionRecentChatList.count == 1 {
                    let messages = "Delete chat with \"\(self?.selectionRecentChatList.first?.profileName ?? "")\"?"
                    controller?.deleteDecriptionLabel?.text = messages
                } else {
                    controller?.deleteDecriptionLabel?.text = "Delete \(self?.selectionRecentChatList.count ?? 0) selected chats?"
                }
                controller?.cancelButton?.addTarget(self, action: #selector(self?.cancelAction(_:)), for: .touchUpInside)
                controller?.deleteButton?.addTarget(self, action: #selector(self?.deleteAction(_:)), for: .touchUpInside)
                controller?.contentStackView?.layer.cornerRadius = 10.0
            })
        }
    }
    
    @objc func deleteAction(_ sender: UIButton) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: { [weak self] in
            self?.dismiss(animated: true) {
                self?.selectionRecentChatList.forEach { deleteRecentChat in
                    self?.recentChatViewModel?.getDeleteChat(jid: deleteRecentChat.jid, completionHandler: { isSuccess in
                        if isSuccess == true {
                            self?.getRecentChat.enumerated().forEach({ (index,recentChat) in
                                if recentChat.jid == deleteRecentChat.jid {
                                    self?.getRecentChat.remove(at: index)
                                    self?.recentChatTableView?.reloadData()
                                }
                            })
                        }
                    })
                }
                self?.clearSelectedColor()
                self?.showHideEmptyMessage()
                self?.longPressCount = 0
                self?.selectionCountLabel?.isHidden = true
                self?.showHeaderView()
                self?.isCellLongPressed = false
                self?.recentChatTableView?.reloadData()
                self?.selectionRecentChatList = []
            }
        })
}
    
    @objc func cancelAction(_ sender: UIButton) {
        self.dismiss(animated: false, completion: nil)
    }
}

extension RecentChatViewController : UITableViewDataSource ,UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if isSearchEnabled == true {
            return unreadMessageChatList.count > 0  ? 3 : 2
        } else if getRecentChat.count > 0 {
            return 1
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch isSearchEnabled {
        case true:
            if unreadMessageChatList.count == 0 {
                return section == 0 ? getRecentChat.count : filteredContactList.count
            } else {
                switch section {
                case 0:
                    return getRecentChat.filter({$0.unreadMessageCount == 0}).count
                case 1:
                    return unreadMessageChatList.count > 0 ? unreadMessageChatList.count : filteredContactList.count
                case 2:
                    return filteredContactList.count
                default:
                    break
                }
            }
        case false:
            return getRecentChat.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView,heightForHeaderInSection section: Int) -> CGFloat {
        if isSearchEnabled == true {
            switch section {
            case 0:
                return getRecentChat.filter({$0.unreadMessageCount == 0}).count > 0 ? 50 : 0
            case 1:
                return (unreadMessageChatList.count > 0 || filteredContactList.count > 0) ? 50 : 0
            case 2:
                return filteredContactList.count > 0 ? 50 : 0
            default:
                break
            }
        } else {
            return 0
        }
        return 0
    }
    
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if isSearchEnabled == true {
            switch section {
            case 0:
                return chatTitle.appending(" (\(getRecentChat.count))")
            case 1:
                return unreadMessageChatList.count > 0 ?messageTitle.appending(" (\(unreadMessageChatList.count))") : contactTitle.appending(" (\(filteredContactList.count))")
            case 2:
                return contactTitle.appending(" (\(filteredContactList.count))")
            default:
                break
            }
        } else {
            return section == 0 ? chatTitle.appending(" (\(getRecentChat.count))") : contactTitle.appending(" (\(filteredContactList.count))")
        }
        return ""
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: RecentChatTableViewCell!
        switch isSearchEnabled {
        case false:
            cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.recentChatCell, for: indexPath) as? RecentChatTableViewCell
            if getRecentChat.count > indexPath.row {
                let recentChat = getRecentChat[indexPath.row]
                let name = getUserName(name: recentChat.profileName, nickName: recentChat.nickName)
                let color = getColor(userName: name)
                cell.setTextColorWhileSearch(searchText: searchBar?.text ?? "", recentChat: recentChat)
                cell.setLastContentTextColor(searchText: searchBar?.text ?? "", recentChat: recentChat)
                let chatMessage = getMessages(messageId: recentChat.lastMessageId)
                let getGroupSenderName = ChatUtils.getGroupSenderName(messsage: chatMessage)
                cell.setRecentChatMessage(recentChatMessage: recentChat, color: color, chatMessage: chatMessage, senderName: getGroupSenderName)
                cell.profileImageButton?.tag = indexPath.row
                cell.profileImageButton?.addTarget(self, action: #selector( imageButtonAction(_:)), for: .touchUpInside)
                cell.setChatTimeTextColor(lastMessageTime: recentChat.lastMessageTime, unreadCount: recentChat.unreadMessageCount)
                return cell
            }
        case true:
            switch indexPath.section {
            case 0:
                cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.recentChatCell, for: indexPath) as? RecentChatTableViewCell
                if getRecentChat.filter({$0.unreadMessageCount == 0}).count > indexPath.row {
                    let recentChat = getRecentChat.filter({$0.unreadMessageCount == 0})[indexPath.row]
                    let name = getUserName(name: recentChat.profileName, nickName: recentChat.nickName)
                    let color = getColor(userName: name)
                    cell.setTextColorWhileSearch(searchText: searchBar?.text ?? "", recentChat: recentChat)
                    cell.setLastContentTextColor(searchText: searchBar?.text ?? "", recentChat: recentChat)
                    let chatMessage = getMessages(messageId: recentChat.lastMessageId)
                    let getGroupSenderName = ChatUtils.getGroupSenderName(messsage: chatMessage)
                    cell.setRecentChatMessage(recentChatMessage: recentChat, color: color, chatMessage: chatMessage, senderName: getGroupSenderName)
                    cell.profileImageButton?.tag = indexPath.row
                    cell.profileImageButton?.addTarget(self, action: #selector( imageButtonAction(_:)), for: .touchUpInside)
                    cell.setChatTimeTextColor(lastMessageTime: recentChat.lastMessageTime, unreadCount: recentChat.unreadMessageCount)
                    return cell
                } else {
                    if filteredContactList.count > indexPath.row {
                        let profile = filteredContactList[indexPath.row]
                        let name = getUserName(name: profile.name, nickName: profile.nickName)
                        let recentChat =  RecentChat()
                        recentChat.profileName = profile.name
                        recentChat.nickName = profile.nickName
                        recentChat.lastMessageContent = profile.status
                        let color = getColor(userName: name)
                        cell.setTextColorWhileSearch(searchText: searchBar?.text ?? "", recentChat: recentChat)
                        cell.setLastContentTextColor(searchText: "", recentChat: recentChat)
                        cell.profileImageButton?.tag = indexPath.row
                        cell.profileImageButton?.addTarget(self, action: #selector( imageButtonAction(_:)), for: .touchUpInside)
                        cell.setContactInfo(recentChat: recentChat, color: color)
                        return cell ?? UITableViewCell()
                    }
                }
            case 1:
                cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.recentChatCell, for: indexPath) as? RecentChatTableViewCell
            if unreadMessageChatList.count > indexPath.row {
                let recentChat = unreadMessageChatList[indexPath.row]
                let name = getUserName(name: recentChat.profileName, nickName: recentChat.nickName)
                let color = getColor(userName: name)
                cell.setTextColorWhileSearch(searchText: "", recentChat: recentChat)
                cell.setLastContentTextColor(searchText: searchBar?.text ?? "", recentChat: recentChat)
                let chatMessage = getMessages(messageId: recentChat.lastMessageId)
                let getGroupSenderName = ChatUtils.getGroupSenderName(messsage: chatMessage)
                cell.setRecentChatMessage(recentChatMessage: recentChat, color: color, chatMessage: chatMessage, senderName: getGroupSenderName)
                cell.profileImageButton?.tag = indexPath.row
                cell.profileImageButton?.addTarget(self, action: #selector( imageButtonAction(_:)), for: .touchUpInside)
                cell.setChatTimeTextColor(lastMessageTime: recentChat.lastMessageTime, unreadCount: recentChat.unreadMessageCount)
                return cell
            } else {
                if filteredContactList.count > indexPath.row {
                    let profile = filteredContactList[indexPath.row]
                    let name = getUserName(name: profile.name, nickName: profile.nickName)
                    let recentChat =  RecentChat()
                    recentChat.profileName = profile.name
                    recentChat.nickName = profile.nickName
                    recentChat.profileImage = profile.image
                    recentChat.lastMessageContent = profile.status
                    let color = getColor(userName: name)
                    cell.setTextColorWhileSearch(searchText: searchBar?.text ?? "", recentChat: recentChat)
                    cell.setLastContentTextColor(searchText: "", recentChat: recentChat)
                    cell.profileImageButton?.tag = indexPath.row
                    cell.profileImageButton?.addTarget(self, action: #selector( imageButtonAction(_:)), for: .touchUpInside)
                    cell.setContactInfo(recentChat: recentChat, color: color)
                    return cell ?? UITableViewCell()
                }
            }
            case 2:
                cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.recentChatCell, for: indexPath) as? RecentChatTableViewCell
                if filteredContactList.count > indexPath.row {
                    let profile = filteredContactList[indexPath.row]
                    let name = getUserName(name: profile.name, nickName: profile.nickName)
                    let recentChat =  RecentChat()
                    recentChat.profileName = profile.name
                    recentChat.nickName = profile.nickName
                    recentChat.lastMessageContent = profile.status
                    let color = getColor(userName: name)
                    cell.setTextColorWhileSearch(searchText: searchBar?.text ?? "", recentChat: recentChat)
                    cell.setLastContentTextColor(searchText: "", recentChat: recentChat)
                    cell.profileImageButton?.tag = indexPath.row
                    cell.profileImageButton?.addTarget(self, action: #selector( imageButtonAction(_:)), for: .touchUpInside)
                    cell.setContactInfo(recentChat: recentChat, color: color)
                    return cell ?? UITableViewCell()
                }
            default:
                break
            }
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if( isCellLongPressed ?? false) {
            if let cell = tableView.cellForRow(at: indexPath) as? RecentChatTableViewCell {
                if( longPressCount >= 1) {
                    if selectionRecentChatList.filter({$0.jid == getRecentChat[indexPath.row].jid}).count == 0 {
                        cell.contentView.backgroundColor = Color.recentChatSelectionColor
                        longPressCount += 1
                        getRecentChat[indexPath.row].isSelected = !getRecentChat[indexPath.row].isSelected
                        selectionRecentChatList.insert(getRecentChat[indexPath.row], at: 0)
                        selectionCountLabel?.text = String(longPressCount)
                    } else {
                            recentChatTableView?.delegate?.tableView!(tableView, didDeselectRowAt: indexPath)
                    }
                } else {
                    hideMultipleSelectionView()
                }
            }
        }
        if !(isCellLongPressed ?? false) {
            if isSearchEnabled == true {
                openContactChat(index: indexPath)
            } else {
                openChat(index: indexPath.row)
            }
        }
        if selectionRecentChatList.count == 0 {
            hideMultipleSelectionView()
        }
        showHideDeleteButton()
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if( isCellLongPressed ?? false) {
            if let cell = tableView.cellForRow(at: indexPath) as? RecentChatTableViewCell {
                if( longPressCount >= 1) {
                        let recentChatJid = getRecentChat[indexPath.row].jid
                        if selectionRecentChatList.filter({$0.jid == recentChatJid}).count > 0 {
                            selectionRecentChatList.enumerated().forEach { (index,selectedRecentChat) in
                                if recentChatJid == selectedRecentChat.jid {
                                    cell.contentView.backgroundColor = .clear
                                    longPressCount -= 1
                                    getRecentChat[indexPath.row].isSelected = !getRecentChat[indexPath.row].isSelected
                                    selectionRecentChatList.remove(at: index)
                                    selectionCountLabel?.text = String(longPressCount)
                                    if selectionRecentChatList.count == 0 {
                                        hideMultipleSelectionView()
                                    }
                                    return
                                }
                            }
                        }
                } else {
                    hideMultipleSelectionView()
                }
            }
        }
        if selectionRecentChatList.count == 0 {
          clearSelectedColor()
        }
        showHideDeleteButton()
    }
    
    private func hideMultipleSelectionView() {
        longPressCount = 0
        selectionCountLabel?.text = String(longPressCount)
        selectionCountLabel?.isHidden = true
       showHeaderView()
        isCellLongPressed = false
        selectionRecentChatList = []
    }
    
    private func hideHeaderView() {
        multipleSelectionView?.isHidden = false
        headerView?.isHidden = true
    }
    
    private func showHeaderView() {
        multipleSelectionView?.isHidden = true
        headerView?.isHidden = false
    }
    
    private func clearSelectedColor() {
        getRecentChat.enumerated().forEach { (index, element) in
            if let cell =  recentChatTableView?.cellForRow(at: IndexPath(row: index, section: 0)) as? RecentChatTableViewCell {
                cell.contentView.backgroundColor = .clear
            }
        }
    }
    
    func openChat(index: Int) {
        let profile = getRecentChat[index]
        let vc = UIStoryboard.init(name: Storyboards.chat, bundle: Bundle.main).instantiateViewController(withIdentifier: Identifiers.chatViewParentController) as? ChatViewParentController
        let profileDetails = ProfileDetails(jid: profile.jid)
        profileDetails.name = profile.profileName
        profileDetails.nickName = profile.nickName
        profileDetails.image = profile.profileImage ?? ""
        profileDetails.profileChatType = profile.profileType
        vc?.getProfileDetails = profileDetails
        let color = getColor(userName:  profile.profileName)
        vc?.contactColor = color
        vc?.replyMessagesDelegate = self
        vc?.replyMessageObj = replyMessageObj
        vc?.replyJid = replyJid
        vc?.messageText = messageTxt
        vc?.navigationController?.modalPresentationStyle = .overFullScreen
        self.navigationController?.pushViewController(vc!, animated: true)
    }
    
    func openContactChat(index: IndexPath) {
        let vc = UIStoryboard.init(name: Storyboards.chat, bundle: Bundle.main).instantiateViewController(withIdentifier: Identifiers.chatViewParentController) as? ChatViewParentController
        switch index.section {
        case 0:
            let profile = getRecentChat.filter({$0.unreadMessageCount == 0})[index.row]
            let profileDetails = ProfileDetails(jid: profile.jid)
            profileDetails.name = profile.profileName
            profileDetails.nickName = profile.nickName
            profileDetails.image = profile.profileImage ?? ""
            profileDetails.profileChatType = profile.profileType
            vc?.getProfileDetails = profileDetails
            vc?.replyMessagesDelegate = self
            vc?.replyMessageObj = replyMessageObj
            vc?.replyJid = replyJid
            vc?.messageText = messageTxt
            let color = getColor(userName: profile.profileName)
            vc?.contactColor = color
        case 1:
            if unreadMessageChatList.count > index.row {
                let profile = unreadMessageChatList[index.row]
                let profileDetails = ProfileDetails(jid: profile.jid)
                profileDetails.name = profile.profileName
                profileDetails.nickName = profile.nickName
                vc?.getProfileDetails = profileDetails
                vc?.replyMessagesDelegate = self
                vc?.replyMessageObj = replyMessageObj
                vc?.replyJid = replyJid
                vc?.messageText = messageTxt
                let color = getColor(userName: profile.profileName)
                vc?.contactColor = color
            } else {
                let profile = filteredContactList[index.row]
                let profileDetails = ProfileDetails(jid: profile.jid)
                profileDetails.name = profile.name
                profileDetails.nickName = profile.nickName
                vc?.getProfileDetails = profileDetails
                let color = getColor(userName: profile.name)
                vc?.replyMessagesDelegate = self
                vc?.replyMessageObj = replyMessageObj
                vc?.replyJid = replyJid
                vc?.messageText = messageTxt
                vc?.contactColor = color
            }
        case 2:
            let profile = filteredContactList[index.row]
            let profileDetails = ProfileDetails(jid: profile.jid)
            profileDetails.name = profile.name
            profileDetails.nickName = profile.nickName
            vc?.getProfileDetails = profileDetails
            let color = getColor(userName: profile.name)
            vc?.contactColor = color
            vc?.replyMessagesDelegate = self
            vc?.replyMessageObj = replyMessageObj
            vc?.replyJid = replyJid
            vc?.messageText = messageTxt
        default:
            break
        }
        navigationController?.modalPresentationStyle = .overFullScreen
        navigationController?.pushViewController(vc!, animated: true)
    }
}

// getChatList Method
extension RecentChatViewController {
    
    private func getColor(userName : String) -> UIColor {
        return ChatUtils.getColorForUser(userName: userName)
    }
    
    private func getContactList() {
        contactViewModel?.getContacts(fromServer: false) { [weak self] (contacts, error)  in
                if error != nil {
                    return
                }
            if let weakSelf = self {
                if  let  contactsList = contacts {
                    weakSelf.allContactsList.removeAll()
                    weakSelf.filteredContactList.removeAll()
                    weakSelf.allContactsList = contactsList
                    weakSelf.allContactsList = weakSelf.allContactsList.sorted { getUserName(name: $0.name, nickName: $0.nickName)  < getUserName(name: $1.name, nickName: $1.nickName)  }
                    weakSelf.recentChatTableView?.reloadData()
                }
            }
        }
    }
    
    private func deleteRecentChat(jid: String) {
        recentChatViewModel?.getDeleteChat(jid: jid, completionHandler: { [weak self] isSuccess in
            if isSuccess ?? false {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute:  { [weak self] in
                    self?.getRecentChat = []
                    self?.refreshRecentChatMessages()
                })
                self?.hideMultipleSelectionView()
            }
        })
 }
    
    func getRecentChatList() {
        recentChatViewModel?.getRecentChatList(isBackground: true, completionHandler: { [weak self] recentChatList in
            if let weakSelf = self {
                if weakSelf.isSearchEnabled == false {
                    weakSelf.clearChatList()
                    weakSelf.getRecentChat = recentChatList ?? []
                    weakSelf.selectionRecentChatList.enumerated().forEach { (index,selectedRecentChat) in
                        weakSelf.getRecentChat.filter({$0.jid == selectedRecentChat.jid}).first?.isSelected = selectedRecentChat.isSelected
                    }
                  //weakSelf.getMessageForSearch()
                }
                DispatchQueue.main.async { [weak self] in
                    if self?.isSearchEnabled == false {
                        self?.recentChatTableView?.reloadData()
                        self?.showHideEmptyMessage()
                    }
                    self?.getOverallUnreadCount()
                }
            }
        })
    }
    
//    func getMessageForSearch(){
//        DispatchQueue.main.async { [weak self] in
//            if let weakSelf = self {
//                weakSelf.getRecentChat.forEach { recentChat in
//                    let chatMessage = FlyMessenger.getMessagesOf(jid: recentChat.jid)
//                    chatMessage.forEach { chatMessage in
//                        let recentChatObj = RecentChat()
//                        recentChatObj.lastMessageContent = chatMessage.messageTextContent
//                        recentChatObj.lastMessageId = chatMessage.messageId
//                        recentChatObj.profileName = chatMessage.senderUserName
//                        recentChatObj.lastMessageTime = chatMessage.messageSentTime
//                        recentChatObj.lastMessageStatus = chatMessage.messageStatus
//                        recentChatObj.jid = chatMessage.chatUserJid
//                        DispatchQueue.main.async {
//                            weakSelf.unreadMessageChatList.insert(recentChatObj, at: 0)
//                        }
//                    }
//                }
//                weakSelf.getAllRecentChat = weakSelf.getRecentChat
//                weakSelf.allUnreadMessageChatList = weakSelf.unreadMessageChatList
//            }
//
//        }
//    }
    
    func getLastMesssage() -> [ChatMessage]? {
        var chatMessage: [ChatMessage] = []
        let filteredObj = getRecentChat.filter({$0.lastMessageType == .video || $0.lastMessageType == .image})
        if filteredObj.count > 0 {
            filteredObj.forEach { (element) in
                chatMessage.append(getMessages(messageId: element.lastMessageId))
            }
        }
        return chatMessage
    }
    
    func getMessages(messageId: String) -> ChatMessage {
        var lastChatMessage : ChatMessage?
        recentChatViewModel?.getMessageOfId(messageId: messageId, completionHandler: { chatMessage in
            lastChatMessage = chatMessage
        })
        return lastChatMessage ?? ChatMessage()
    }
}

// SearchBar Delegate Method
extension RecentChatViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String){
        if searchText.trim().count > 0 {
            isSearchEnabled = true
            hideMultipleSelectionView()
            clearSelectedColor()
            getRecentChat = searchText.isEmpty ? getRecentChat : getAllRecentChat.filter({ recentChat -> Bool in
                let name = getUserName(name: recentChat.profileName, nickName: recentChat.nickName)
                return name.range(of: searchText.trim(), options: [.caseInsensitive, .diacriticInsensitive]) != nil ||
                recentChat.lastMessageContent.capitalized.range(of: searchText.trim().capitalized, options: [.caseInsensitive, .diacriticInsensitive]) != nil
            })
            filteredContactList = searchText.isEmpty ? removeDuplicateFromContacts(contactList: allContactsList) : removeDuplicateFromContacts(contactList: allContactsList).filter({ contact -> Bool in
                let name = getUserName(name: contact.name , nickName: contact.nickName)
                return name.range(of: searchText, options: [.caseInsensitive, .diacriticInsensitive]) != nil
            })
            unreadMessageChatList = searchText.isEmpty ? unreadMessageChatList : allUnreadMessageChatList.filter({ recentChat -> Bool in
                return recentChat.lastMessageContent.capitalized.range(of: searchText.trim().capitalized, options: [.caseInsensitive, .diacriticInsensitive]) != nil
            })
        } else {
            isSearchEnabled = false
            getRecentChatList()
            filteredContactList = []
        }
        
        recentChatTableView?.reloadData()
        showHideEmptyMessage()
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        refreshRecentChatMessages()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        getRecentChatList()
        searchBar.setShowsCancelButton(true, animated: true)
    }
}

// UI Method
extension RecentChatViewController {
    func setProfile() {
        let profile = getRecentChat[currentIndex]
        let urlString = "\(FlyDefaults.baseURL)\(media)/\(profile.profileImage ?? "")?mf=\(FlyDefaults.authtoken)"
        username?.text = getUserName(name: profile.profileName, nickName: profile.nickName)
        let url = URL(string: urlString)
        let color = getColor(userName: getUserName(name: profile.profileName, nickName: profile.nickName))
        userImage?.sd_imageIndicator = SDWebImageActivityIndicator.gray
        var placeHolder = UIImage()
        if profile.profileType == .groupChat {
            placeHolder = UIImage(named: ImageConstant.ic_group_placeholder)!
            let isImageEmpty = profile.profileImage?.isEmpty ?? false
            print("setProfile \(isImageEmpty)")
            if isImageEmpty {
                userImage?.backgroundColor = Color.groupIconBackgroundGray
                userImage?.contentMode = .center
            } else {
                userImage?.contentMode = .scaleAspectFill
            }
        }else {
            placeHolder = getPlaceholder(name: getUserName(name: profile.profileName, nickName: profile.nickName), color: color )
            userImage?.contentMode = .scaleAspectFill
        }
        userImage?.sd_setImage(with: url, placeholderImage: placeHolder)
    }
    
    func getOverallUnreadCount() {
        let overallUnreadCount = getRecentChat.filter({$0.unreadMessageCount > 0}).count
        if overallUnreadCount > 0 {
            chatTabBarItem?.badgeValue =  "\(overallUnreadCount)"
        } else {
            chatTabBarItem?.badgeValue = nil
        }
    }
    
    
    
    private func showHideDeleteButton() {
        if selectionRecentChatList.filter({$0.profileType == .groupChat}).count == 0  {
            deleteChatButton?.isHidden = false
        } else {
            deleteChatButton?.isHidden = true
        }
    }
    
    func getPlaceholder(name: String, color: UIColor)->UIImage {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let ipimage = IPImage(text: trimmedName, radius: Double(userImage?.frame.size.height ?? 0.0), font: UIFont.font84px_appBold(), textColor: nil, color: color)
        let placeholder = ipimage.generateInitialSqareImage()
        return placeholder ?? #imageLiteral(resourceName: "ic_profile_placeholder")
    }
    
    private func removeDuplicateFromContacts(contactList: [ProfileDetails]) -> [ProfileDetails] {
        var removeDuplicateList = contactList
            removeDuplicateList.enumerated().forEach({  (index, element) in
                if getRecentChat.filter({$0.jid == element.jid}).count > 0 {
                    if removeDuplicateList.count <= index {
                        removeDuplicateList.remove(at: index)
                        }
                    }
            })
        return removeDuplicateList
    }
    
    private func showHideEmptyMessage() {
        if isSearchEnabled == true {
            emptyMessageView?.isHidden = (getRecentChat.count == 0 && filteredContactList.count == 0 && unreadMessageChatList.count == 0) ? false : true
            emptyImage?.isHidden = true
            noNewMsgText?.isHidden = false
            noNewMsgText?.text = noResultFound
            noNewMsgText?.textColor = .lightGray
            descriptionMessageText?.isHidden = true
        } else {
            emptyMessageView?.isHidden = getRecentChat.count == 0 ? false : true
            emptyImage?.isHidden = false
            noNewMsgText?.isHidden = false
            noNewMsgText?.text = noNewMessage
            noNewMsgText?.textColor = .black
            descriptionMessageText?.isHidden = false
        }
    }
    
    private func clearChatList() {
        getRecentChat.removeAll()
        getAllRecentChat.removeAll()
        unreadMessageChatList.removeAll()
        allUnreadMessageChatList.removeAll()
    }
    
    private func refreshRecentChatMessages() {
        isSearchEnabled = false
        searchBar?.resignFirstResponder()
        searchBar?.setShowsCancelButton(false, animated: true)
        searchBar?.text = ""
        getRecentChatList()
    }
}

extension RecentChatViewController : ConnectionEventDelegate {
    func onConnected() {}
    
    func onDisconnected() {}
    
    func onConnectionNotAuthorized() {}
}

// MessageEventDelegate
extension RecentChatViewController : MessageEventsDelegate {
    func onMessageStatusUpdated(messageId: String, chatJid: String, status: MessageStatus) {
        getRecentChatList()
    }
    
    func onMediaStatusUpdated(message: ChatMessage) {
        
    }
    
    func onMediaStatusFailed(error: String, messageId: String) {
        
    }
    
    func onMediaProgressChanged(message: ChatMessage, progressPercentage: Float) {
        
    }
    
    func onMessagesClearedOrDeleted(messageIds: Array<String>) {}
    
    func onMessagesDeletedforEveryone(messageIds: Array<String>) {}
    
    func showOrUpdateOrCancelNotification() {}
    
    func onMessagesCleared(toJid: String) {}
    
    func setOrUpdateFavourite(messageId: String, favourite: Bool, removeAllFavourite: Bool) {}
    
    func onMessageReceived(message: ChatMessage, chatJid: String) {
        print("onMessageReceived \(message.messageId) \(chatJid)")
        if isSearchEnabled == false {
            refreshRecentChatMessages()
        }
    }
}

// Profile Event Delegate
extension RecentChatViewController : ProfileEventsDelegate {
    func userCameOnline(for jid: String) {}
    
    func userWentOffline(for jid: String) {}
    
    func userProfileFetched(for jid: String, profileDetails: ProfileDetails?) {}
    
    func myProfileUpdated() {}
    
    func usersProfilesFetched() {}
    
    func blockedThisUser(jid: String) {}
    
    func unblockedThisUser(jid: String) {}
    
    func usersIBlockedListFetched(jidList: [String]) {}
    
    func usersBlockedMeListFetched(jidList: [String]) {}
    
    func userBlockedMe(jid: String) {}
    
    func userUnBlockedMe(jid: String) {}
    
    func hideUserLastSeen() {}
    
    func getUserLastSeen() {}
    
    func userUpdatedTheirProfile(for jid: String, profileDetails: ProfileDetails) {
        print("userUpdatedTheirProfile \(jid)")
        if  let index = getRecentChat.firstIndex(where: { pd in pd.jid == jid }) {
            getRecentChat[index].profileImage = profileDetails.image
            getRecentChat[index].profileName = profileDetails.name
            print("userUpdatedTheirProfile currentIndex \(currentIndex)")
            let profile = ["jid": profileDetails.jid, "name": profileDetails.name, "image": profileDetails.image, "status": profileDetails.status]
            NotificationCenter.default.post(name: Notification.Name(Identifiers.ncProfileUpdate), object: nil, userInfo: profile as [AnyHashable : Any])
            NotificationCenter.default.post(name: Notification.Name(FlyConstants.contactSyncState), object: nil, userInfo: profile as [AnyHashable : Any])
            let indexPath = IndexPath(item: index, section: 0)
            recentChatTableView?.reloadRows(at: [indexPath], with: .fade)
        }
    }
}

extension RecentChatViewController : GroupCreationDelegate {
    func onGroupCreated() {
        print("RecentChatViewController onGroupCreated")
        getRecentChatList()
    }
}

extension RecentChatViewController : GroupEventsDelegate {
    func didRemoveMemberFromAdmin(groupJid: String, removedAdminMemberJid: String, removedByMemberJid: String) {

    }
    
    func didAddNewMemeberToGroup(groupJid: String, newMemberJid: String, addedByMemberJid: String) {
        
    }
    
    func didRemoveMemberFromGroup(groupJid: String, removedMemberJid: String, removedByMemberJid: String) {
        
    }
    
    func didMakeMemberAsAdmin(groupJid: String, newAdminMemberJid: String, madeByMemberJid: String) {
        
    }
    
    func didDeleteGroupLocally(groupJid: String) {
        
    }
    
    func didLeftFromGroup(groupJid: String, leftUserJid: String) {
        
    }
    
    func didCreateGroup(groupJid: String) {
        
    }
    
    func didFetchGroupMembers(groupJid: String) {
        
    }
    
    func didReceiveGroupNotificationMessage(message: ChatMessage) {
        getRecentChatList()
    }
    
    func didUpdateGroupProfile(groupJid: String) {
        print("RecentChatViewController didGroupInfoUpdatedMessage \(groupJid)")
      
        let group = GroupManager.shared.getAGroupFromLocal(groupJid: groupJid)
      
        DispatchQueue.main.async { [weak self] in
            self?.getRecentChat.enumerated().forEach { (index, element) in
                if element.jid == groupJid {
                   
                    self?.getRecentChat[index].profileName = (group?.name ?? group?.nickName) ?? ""
                    self?.getRecentChat[index].profileImage = group?.image
                    print("\(self?.getRecentChat[index].nickName) \(self?.recentChatTableView)")
                    self?.recentChatTableView?.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                }
            }
        }
    }
    
    func didFetchGroups(groups: [ProfileDetails]) {
        print("RecentChatViewController didGetGroups \(groups.count)")
        getRecentChatList()
    }
    
    func didFetchGroupProfile(groupJid: String) {
        print("RecentChatViewController didGroupProfileFetch \(groupJid)")
        getRecentChatList()
    }
}

extension RecentChatViewController : ReplyMessagesDelegate {
    func replyMessageObj(message: ChatMessage?,jid: String,messageText: String) {
        replyMessageObj = message
        replyJid = jid
        messageTxt = messageText
    }
}
