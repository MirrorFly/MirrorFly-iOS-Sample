//  ChatViewController.swift
//  MirrorflyUIkit
//  Created by User on 28/08/21.


import UIKit
import Foundation
import FlyCore
import FlyCommon
import SDWebImage
import AVKit
import Contacts
import RxSwift
import FlyDatabase

class RecentChatViewController: UIViewController, UIGestureRecognizerDelegate {
   
    @IBOutlet weak var recentChatTableView: UITableView? {
        didSet {
            recentChatTableView?.register(UINib(nibName: Identifiers.ArchiveChatTableViewCell, bundle: nil), forCellReuseIdentifier: Identifiers.ArchiveChatTableViewCell)
        }
    }
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
    @IBOutlet weak var pinChatButton: UIButton!
    @IBOutlet weak var muteChatButton: UIButton!
    @IBOutlet weak var archiveChatButton: UIButton!
    @IBOutlet weak var headerBackButton: UIButton!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var searchView: UIView!
    @IBOutlet weak var createGroupButton: UIButton!

    var longPressCount = 0
    var isCellLongPressed: Bool? = false
    var getRecentChat: [RecentChat] = []
    var getAllRecentChat: [RecentChat] = []
    var filteredContactList =  [ProfileDetails]()
    var allContactsList =  [ProfileDetails]()
    var unreadMessageChatList: [RecentChat] = []
    var allUnreadMessageChatList: [RecentChat] = []
    var isSearchEnabled: Bool = false
    let chatManager = ChatManager.shared
    var currentIndex = -1
    private var contactViewModel : ContactViewModel?
    private var recentChatViewModel: RecentChatViewModel?
    private var selectionRecentChatList: [RecentChat] = []
    private var replyMessageObj: ChatMessage?
    private var replyJid: String?
    private var messageTxt: String?
    var tappedProfile : ProfileDetails? = nil
    var getArchiveChat: [RecentChat] = []
    var showArchivedChat = false
    
    var totalPages = 2
    var totalUsers = 0
    var nextPage = 1
    var searchTotalPages = 2
    var searchTotalUsers = 0
    var searchNextPage = 1
    var isLoadingInProgress = false
    var searchTerm = emptyString()
    let disposeBag = DisposeBag()
    let searchSubject = PublishSubject<String>()
    var internetObserver = PublishSubject<Bool>()
    var isFirstPageLoaded = false
    
    var fetchRecentChatParams : RecentChatListParams? = nil
    var recentChatListBuilder : RecentChatListBuilder? = nil
    var isRecentLoadingDone = false
    var isRecentLoadingInProgress = false
    let backgroundQueue = DispatchQueue(label: "recent")
    
    var availableFeatures = ChatManager.getAvailableFeatures()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        archiveChatButton.isHidden = true
        selectionCountLabel?.textColor = UIColor(named: "buttonColor")
        contactViewModel =  ContactViewModel()
        recentChatViewModel = RecentChatViewModel()
        fetchRecentChatParams = RecentChatListParams(limit: 50)
        recentChatListBuilder = RecentChatListBuilder(recentChatListParams: fetchRecentChatParams!)
        setupTableviewLongPressGesture()
        handleBackgroundAndForground()
        configTableView()
        NotificationCenter.default.addObserver(self, selector: #selector(self.contactSyncCompleted(notification:)), name: NSNotification.Name(FlyConstants.contactSyncState), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        searchSubject.throttle(.milliseconds(25), scheduler: MainScheduler.instance).distinctUntilChanged().subscribe { [weak self] term in
            self?.searchTerm = term
            self?.filteredContactList.removeAll()
            self?.recentChatTableView?.reloadData()
            self?.getUsersList(pageNo: 1, pageSize: 20, searchTerm: term)
        } onError: { error in } onCompleted: {} onDisposed: {}.disposed(by: disposeBag)
        internetObserver.throttle(.seconds(4), latest: false ,scheduler: MainScheduler.instance).subscribe { [weak self] event in
            switch event {
            case .next(let data):
                print("#contact next ")
                guard let self = self else{
                    return
                }
                if data {
                    self.resumeLoading()
                }
            case .error(let error):
                print("#contactSync error \(error.localizedDescription)")
            case .completed:
                print("#contactSync completed")
            }
            
        }.disposed(by: disposeBag)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            recentChatTableView?.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height + (recentChatTableView?.rowHeight ?? 0.0) + 30, right: 0)
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        recentChatTableView?.contentInset = .zero
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(networkChange(_:)),
                                               name: Notification.Name(NetStatus.networkNotificationObserver), object: nil)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        getRecentChatList()
        if ENABLE_CONTACT_SYNC{
            getContactList()
        }else{
            resetDataAndFetchUsersList()
        }
        
        availableFeatures = ChatManager.getAvailableFeatures()
        searchBar?.isHidden = !(availableFeatures.isRecentChatSearchEnabled) ? true : false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        chatManager.connectionDelegate = self
        ContactManager.shared.profileDelegate = self
        chatManager.messageEventsDelegate = self
        FlyMessenger.shared.messageEventsDelegate = self
        GroupManager.shared.groupDelegate = self
        ChatManager.shared.adminBlockDelegate = self
        ChatManager.shared.availableFeaturesDelegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        chatManager.connectionDelegate = nil
        ContactManager.shared.profileDelegate = nil
        chatManager.messageEventsDelegate = nil
        FlyMessenger.shared.messageEventsDelegate = nil
        GroupManager.shared.groupDelegate = nil
        ChatManager.shared.adminBlockDelegate = nil
        ChatManager.shared.availableFeaturesDelegate = nil
        NotificationCenter.default.removeObserver(self, name: Notification.Name(NetStatus.networkNotificationObserver), object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(FlyConstants.contactSyncState), object: nil)
    }
    
    override func willCometoForeground() {
        profilePopupContainer?.isHidden = true
        if !ENABLE_CONTACT_SYNC && isSearchEnabled{
            resetDataAndFetchUsersList()
        }
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
                    if let cell =  recentChatTableView?.cellForRow(at: indexPath) as? RecentChatTableViewCell {
                        if selectionRecentChatList.filter({$0.jid == (showArchivedChat ? getArchiveChat[indexPath.row].jid : getRecentChat[indexPath.row].jid) }).count == 0 {
                            cell.contentView.backgroundColor = Color.recentChatSelectionColor
                            isCellLongPressed = true
                            recentChatTableView?.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                            showHideDeleteButton()
                            if showArchivedChat {
                                getArchiveChat[indexPath.row].isSelected = !getArchiveChat[indexPath.row].isSelected
                                selectionRecentChatList.insert(getArchiveChat[indexPath.row], at: 0)
                            } else {
                                getRecentChat[indexPath.row].isSelected = !getRecentChat[indexPath.row].isSelected
                                selectionRecentChatList.insert(getRecentChat[indexPath.row], at: 0)
                            }
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
                updatePinIcon()
                updateMuteIcon()
                updateArchiveIcon()
            }
        }
    }

    @objc func imageButtonAction(_ sender:AnyObject){
        closeKeyboard()
        if let buttonTag = sender.tag {
            currentIndex = buttonTag
            if getRecentChat[currentIndex].isBlockedByAdmin && getRecentChat[currentIndex].isGroup {
                showGroupBlockedView()
            } else {
                UIView.transition(with: profilePopupContainer ?? UIView(), duration: 0.5, options: .transitionCrossDissolve, animations: { [weak self] in
                    if let weakSelf = self {
                        weakSelf.profilePopupContainer?.isHidden = false
                    }
                })
                setProfile()
            }
        }
      
    }
    
    private func showGroupBlockedView() {
        AppAlert.shared.showAlert(view: self, title: groupNoLongerAvailable, message: "", buttonTitle: okButton)
    }
    
    
    @objc func closeKeyboard() {
        self.view.endEditing(true)
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        UIView.transition(with: profilePopupContainer ?? UIView(), duration: 0.5, options: .transitionFlipFromLeft, animations: { [weak self] in
            if let weakSelf = self {
                weakSelf.profilePopupContainer?.isHidden = true
                weakSelf.currentIndex = -1
            }
        })
    }
    
    @IBAction func closeButtonTapped(_ sender: Any) {
       showHeaderView()
        longPressCount = 0
        isCellLongPressed = false
        selectionCountLabel?.text = String(longPressCount)
        clearSelectedColor()
        selectionRecentChatList = []
        getRecentChatList()
    }

    @IBAction func headerArchiveBackAction(_ sender: UIButton) {
        hideArchiveHeader()
        getRecentChatList()
    }
    
    @IBAction func viewContact(_ sender: Any) {
        navigateTo(identifier: Identifiers.contactViewController)
    }
    @IBAction func createGroup(_ sender: Any) {
        print("createGroup")
        let values : [String] = !(availableFeatures.isGroupChatEnabled) ? [CreateGroupOptions.web.rawValue] : CreateGroupOptions.allCases.map { $0.rawValue }
        var actions = [(String, UIAlertAction.Style)]()
        values.forEach { title in
            actions.append((title, UIAlertAction.Style.default))
        }
        AppActionSheet.shared.showActionSeet(title : "", message: "",actions: actions , sheetCallBack: { [weak self] didCancelTap, tappedTitle in
            if !didCancelTap {
                switch tappedTitle {
                case CreateGroupOptions.createGroup.rawValue:
                    let contactPermissionStatus = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
                    if contactPermissionStatus == .denied {
                        AppAlert.shared.contactAccess(view: self!,
                                                      title: contactAccessTitle,
                                                      message: contactAccessMessage,
                                                      settingstitle: settings,
                                                      cancelTitle: cancelUppercase)
                        FlyDefaults.isContactPermissionSkipped = false
                    } else {
                        self?.navigateTo(identifier: Identifiers.createNewGroup)
                    }
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
                AppPermissions.shared.presentSettingsForPermission(permission: .camera, instance: self as Any)
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
                    let selectedProfile = self?.selectionRecentChatList.first
                    let name = getUserName(jid: selectedProfile?.jid ?? "", name: selectedProfile?.profileName ?? "", nickName: selectedProfile?.nickName ?? "", contactType: selectedProfile?.isItSavedContact ?? false ? .live : .unknown)
                    let messages = "Delete chat with \"\(name)\"?"
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

    //Recent chat Pin/Unpin Action
    @IBAction func pinChatAction(_ sender: UIButton) {
        var pinChatList = [RecentChat]()
        let isPin = isPin()
        for chat in self.selectionRecentChatList {
            if isPin {
                if chat.isChatPinned == false {
                    pinChatList.append(chat)
                }
            } else {
                pinChatList.append(chat)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: { [weak self] in
            self?.dismiss(animated: true) {
                //FlyDefaults.maximumRecentChatPin
                if (ChatManager.recentChatPinnedCount() > 3 || pinChatList.count > 3 || (ChatManager.recentChatPinnedCount() + pinChatList.count) > 3) && isPin {
                    AppAlert.shared.showToast(message: "You can only pin upto 3 chats")
                } else {
                    pinChatList.forEach { pinRecentChat in
                        self?.recentChatViewModel?.getPinChat(jid: pinRecentChat.jid, isPin: isPin, completionHandler: { isSuccess in
                        })
                    }
                    AppAlert.shared.showToast(message: "Chat\(pinChatList.count > 1 ? "s" : "") \(isPin ? "pinned" : "unpinned")")
                }
                self?.longPressCount = 0
                self?.selectionCountLabel?.isHidden = true
                self?.showHeaderView()
                self?.isCellLongPressed = false
                self?.selectionRecentChatList = []
                self?.getRecentChatList()
                self?.recentChatTableView?.reloadData()
            }
        })
    }

    //Get status whether is Pin or Unpin
    func isPin() -> Bool {
        for chat in selectionRecentChatList {
            if chat.isChatPinned == false {
                return true
            }
        }
        return false
    }

    //Update Pin icon
    func updatePinIcon() {
        pinChatButton.setImage(isPin() ? UIImage(named: "push-pin")?.withHorizontallyFlippedOrientation() : UIImage(named: "push-unpin")?.withHorizontallyFlippedOrientation(), for: .normal)
    }

    @IBAction func muteChatAction(_ sender: UIButton) {
        let isMute = isMute()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: { [weak self] in
            self?.dismiss(animated: true) {
                self?.selectionRecentChatList.forEach { pinRecentChat in
                    self?.recentChatViewModel?.getMuteChat(jid: pinRecentChat.jid, isMute: isMute, completionHandler: { isSuccess in
                    })
                }
                self?.longPressCount = 0
                self?.selectionCountLabel?.isHidden = true
                self?.showHeaderView()
                self?.isCellLongPressed = false
                self?.selectionRecentChatList = []
                self?.getRecentChatList()
                self?.recentChatTableView?.reloadData()
            }
        })
    }

    //Get status whether is mute or Unmute
    func isMute() -> Bool {
        return selectionRecentChatList.filter {$0.isMuted == false }.count > 0 ? true : false
    }

    //Update mute icon
    func updateMuteIcon() {
        muteChatButton.setImage(isMute() ? UIImage(named: "mute") : UIImage(named: "unmute"), for: .normal)
    }

    //Archive chat Action
    @IBAction func ArchiveChatAction(_ sender: UIButton) {

        if !NetworkReachability.shared.isConnected {
            AppAlert.shared.showToast(message: ErrorMessage.checkYourInternet)
            return
        }

        let isArchive = isArchive()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: { [weak self] in
            self?.dismiss(animated: true) {

                self?.recentChatViewModel?.getArchiveChat(jids: self?.selectionRecentChatList.compactMap { $0.jid } ?? [], isArchive: isArchive, completionHandler: { isSuccess, error, data in
                    if isSuccess {
                        AppAlert.shared.showToast(message: (self?.selectionRecentChatList.count ?? 0) > 1 ? " \(self?.selectionRecentChatList.count ?? 0) chats are \(isArchive ? "archived" : "unarchived")" : "Chat has been \(isArchive ? "archived" : "unarchived")")
                    }
                })

                self?.longPressCount = 0
                self?.selectionCountLabel?.isHidden = true
                self?.showHeaderView()
                self?.isCellLongPressed = false
                self?.selectionRecentChatList = []
                self?.getRecentChatList()
                self?.recentChatTableView?.reloadData()
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
            if getRecentChat.count > 0 && filteredContactList.count > 0 {
                return 2
            } else {
                return 1
            }
        } else if getRecentChat.count > 0 && getArchiveChat.count > 0 && !showArchivedChat {
            return 2
        } else if getRecentChat.count > 0 || getArchiveChat.count > 0 || showArchivedChat {
            return 1
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch isSearchEnabled {
        case true:
                switch section {
                case 0:
                    return getRecentChat.count > 0 ? getRecentChat.count : (filteredContactList.count > 0) ? filteredContactList.count : 0
                case 1:
                    return filteredContactList.count > 0 ? filteredContactList.count : 0
                case 2:
                    return filteredContactList.count
                default:
                    break
                }
        case false:
            if getRecentChat.count > 0 && getArchiveChat.count > 0 && showArchivedChat == false {
                switch section {
                case FlyDefaults.isArchivedChatEnabled ? 0 : 1:
                    return 1
                case FlyDefaults.isArchivedChatEnabled ? 1 : 0:
                    return getRecentChat.count
                default:
                    break
                }
            } else if getArchiveChat.count > 0 && showArchivedChat == false {
                return 1
            } else if getArchiveChat.count > 0 && showArchivedChat == true {
                return getArchiveChat.count
            } else {
                return getRecentChat.count
            }
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView,heightForHeaderInSection section: Int) -> CGFloat {
        if isSearchEnabled == true {
            switch section {
            case 0:
                return getRecentChat.count > 0 ? 50 : (filteredContactList.count > 0) ? 50 : 0
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
                return getRecentChat.count > 0 ? chatTitle.appending(" (\(getRecentChat.count))") : (filteredContactList.count > 0) ? contactTitle.appending(" (\(filteredContactList.count))") : ""
            case 1:
                return filteredContactList.count > 0 ? contactTitle.appending(" (\( ENABLE_CONTACT_SYNC ? filteredContactList.count : searchTotalUsers ))") : ""
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
            if getRecentChat.count > 0 && getArchiveChat.count > 0 && showArchivedChat == false {
                switch indexPath.section {
                case FlyDefaults.isArchivedChatEnabled ? 0 : 1:
                    let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.ArchiveChatTableViewCell, for: indexPath) as! ArchiveChatTableViewCell
                    let count = getArchiveChat.reduce(0, {$0 + $1.unreadMessageCount})
                    cell.chatCountLabel.isHidden = count == 0 ? true : false
                    cell.chatCountLabel.text = String(count)
                    return cell
                case FlyDefaults.isArchivedChatEnabled ? 1 : 0:
                    cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.recentChatCell, for: indexPath) as? RecentChatTableViewCell
                    if getRecentChat.count > indexPath.row {
                        let recentChat = getRecentChat[indexPath.row]
                        let name = getUserName(jid: recentChat.jid, name: recentChat.profileName, nickName: recentChat.nickName, contactType: recentChat.isItSavedContact ? .live : .unknown)
                        let color = getColor(userName: name)
                        cell.setTextColorWhileSearch(searchText: searchBar?.text ?? "", recentChat: recentChat)
                        cell.setLastContentTextColor(searchText: searchBar?.text ?? "", recentChat: recentChat)
                        let chatMessage = getMessages(messageId: recentChat.lastMessageId)
                        let getGroupSenderName = ChatUtils.getGroupSenderName(messsage: chatMessage)
                        cell.setRecentChatMessage(recentChatMessage: recentChat, color: color, chatMessage: chatMessage, senderName: getGroupSenderName)
                        cell.archivedStatusLabel.isHidden = true
                        cell.profileImageButton?.tag = indexPath.row
                        cell.profileImageButton?.addTarget(self, action: #selector( imageButtonAction(_:)), for: .touchUpInside)
                        cell.setChatTimeTextColor(lastMessageTime: recentChat.lastMessageTime, unreadCount: recentChat.unreadMessageCount)
                        return cell
                    }
                default:
                    break
                }
            } else if getArchiveChat.count > 0 && showArchivedChat == false {
                let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.ArchiveChatTableViewCell, for: indexPath) as! ArchiveChatTableViewCell
                let count = getArchiveChat.reduce(0, {$0 + $1.unreadMessageCount})
                cell.chatCountLabel.isHidden = count == 0 ? true : false
                cell.chatCountLabel.text = String(count)
                return cell
            } else if getArchiveChat.count > 0 && showArchivedChat == true {
                cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.recentChatCell, for: indexPath) as? RecentChatTableViewCell
                if getArchiveChat.count > indexPath.row {
                    let recentChat = getArchiveChat[indexPath.row]
                    let name = getUserName(jid: recentChat.jid, name: recentChat.profileName, nickName: recentChat.nickName, contactType: recentChat.isItSavedContact ? .live : .unknown)
                    let color = getColor(userName: name)
                    cell.setTextColorWhileSearch(searchText: searchBar?.text ?? "", recentChat: recentChat)
                    cell.setLastContentTextColor(searchText: searchBar?.text ?? "", recentChat: recentChat)
                    let chatMessage = getMessages(messageId: recentChat.lastMessageId)
                    let getGroupSenderName = ChatUtils.getGroupSenderName(messsage: chatMessage)
                    cell.setRecentChatMessage(recentChatMessage: recentChat, color: color, chatMessage: chatMessage, senderName: getGroupSenderName)
                    cell.archivedStatusLabel.isHidden = true
                    cell.profileImageButton?.tag = indexPath.row
                    cell.profileImageButton?.addTarget(self, action: #selector( imageButtonAction(_:)), for: .touchUpInside)
                    cell.setChatTimeTextColor(lastMessageTime: recentChat.lastMessageTime, unreadCount: recentChat.unreadMessageCount)
                    return cell
                }
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.recentChatCell, for: indexPath) as? RecentChatTableViewCell
                if getRecentChat.count > indexPath.row {
                    let recentChat = getRecentChat[indexPath.row]
                    let name = getUserName(jid: recentChat.jid, name: recentChat.profileName, nickName: recentChat.nickName, contactType: recentChat.isItSavedContact ? .live : .unknown)
                    let color = getColor(userName: name)
                    cell.setTextColorWhileSearch(searchText: searchBar?.text ?? "", recentChat: recentChat)
                    cell.setLastContentTextColor(searchText: searchBar?.text ?? "", recentChat: recentChat)
                    let chatMessage = getMessages(messageId: recentChat.lastMessageId)
                    let getGroupSenderName = ChatUtils.getGroupSenderName(messsage: chatMessage)
                    cell.setRecentChatMessage(recentChatMessage: recentChat, color: color, chatMessage: chatMessage, senderName: getGroupSenderName)
                    cell.archivedStatusLabel.isHidden = true
                    cell.profileImageButton?.tag = indexPath.row
                    cell.profileImageButton?.addTarget(self, action: #selector( imageButtonAction(_:)), for: .touchUpInside)
                    cell.setChatTimeTextColor(lastMessageTime: recentChat.lastMessageTime, unreadCount: recentChat.unreadMessageCount)
                    return cell
                }
            }
        case true:
            switch indexPath.section {
            case 0:
                cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.recentChatCell, for: indexPath) as? RecentChatTableViewCell
                if getRecentChat.count > indexPath.row {
                    let recentChat = getRecentChat[indexPath.row]
                    let name = getUserName(jid: recentChat.jid, name: recentChat.profileName, nickName: recentChat.nickName, contactType: recentChat.isItSavedContact ? .live : .unknown)
                    let color = getColor(userName: name)
                    cell.setTextColorWhileSearch(searchText: searchBar?.text ?? "", recentChat: recentChat)
                    cell.setLastContentTextColor(searchText: searchBar?.text ?? "", recentChat: recentChat)
                    let chatMessage = getMessages(messageId: recentChat.lastMessageId)
                    let getGroupSenderName = ChatUtils.getGroupSenderName(messsage: chatMessage)
                    cell.setRecentChatMessage(recentChatMessage: recentChat, color: color, chatMessage: chatMessage, senderName: getGroupSenderName)
                    cell.archivedStatusLabel.isHidden = !recentChat.isChatArchived
                    cell.profileImageButton?.tag = indexPath.row
                    cell.profileImageButton?.addTarget(self, action: #selector( imageButtonAction(_:)), for: .touchUpInside)
                    cell.setChatTimeTextColor(lastMessageTime: recentChat.lastMessageTime, unreadCount: recentChat.unreadMessageCount)
                    return cell
                } else {
                    if filteredContactList.count > indexPath.row {
                        let profile = filteredContactList[indexPath.row]
                        let name = getUserName(jid: profile.jid,name: profile.name, nickName: profile.nickName, contactType: profile.contactType)
                        let recentChat =  RecentChat()
                        recentChat.profileName = profile.name
                        recentChat.nickName = profile.nickName
                        recentChat.lastMessageContent = profile.status
                        recentChat.isItSavedContact = profile.contactType == .live ? true : false
                        recentChat.jid = profile.jid
                        let color = getColor(userName: name)
                        cell.pinImageView.isHidden = true
                        cell.muteImageView.isHidden = true
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
                let name = getUserName(jid: recentChat.jid, name: recentChat.profileName, nickName: recentChat.nickName, contactType: recentChat.isItSavedContact ? .live : .unknown)
                let color = getColor(userName: name)
                cell.setTextColorWhileSearch(searchText: "", recentChat: recentChat)
                cell.setLastContentTextColor(searchText: searchBar?.text ?? "", recentChat: recentChat)
                let chatMessage = getMessages(messageId: recentChat.lastMessageId)
                let getGroupSenderName = ChatUtils.getGroupSenderName(messsage: chatMessage)
                cell.archivedStatusLabel.isHidden = true
                cell.setRecentChatMessage(recentChatMessage: recentChat, color: color, chatMessage: chatMessage, senderName: getGroupSenderName)
                cell.muteImageView.isHidden = true
                cell.pinImageView.isHidden = true
                cell.profileImageButton?.tag = indexPath.row
                cell.profileImageButton?.addTarget(self, action: #selector( imageButtonAction(_:)), for: .touchUpInside)
                cell.setChatTimeTextColor(lastMessageTime: recentChat.lastMessageTime, unreadCount: recentChat.unreadMessageCount)
                return cell
            } else {
                if filteredContactList.count > indexPath.row {
                    let profile = filteredContactList[indexPath.row]
                    let name = getUserName(jid: profile.jid, name: profile.name, nickName: profile.nickName, contactType: profile.contactType)
                    let recentChat =  RecentChat()
                    recentChat.profileName = profile.name
                    recentChat.nickName = profile.nickName
                    recentChat.profileImage = profile.image
                    recentChat.lastMessageContent = profile.status
                    recentChat.isItSavedContact = profile.contactType == .live ? true : false
                    recentChat.jid = profile.jid
                    recentChat.isDeletedUser = profile.contactType == .deleted
                    let color = getColor(userName: name)
                    cell.archivedStatusLabel.isHidden = true
                    cell.setTextColorWhileSearch(searchText: searchBar?.text ?? "", recentChat: recentChat)
                    cell.setLastContentTextColor(searchText: "", recentChat: recentChat)
                    cell.muteImageView.isHidden = true
                    cell.pinImageView.isHidden = true
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
                    let name = getUserName(jid: profile.jid, name: profile.name, nickName: profile.nickName, contactType: profile.contactType)
                    let recentChat =  RecentChat()
                    recentChat.profileName = profile.name
                    recentChat.nickName = profile.nickName
                    recentChat.lastMessageContent = profile.status
                    recentChat.isItSavedContact = profile.contactType == .live ? true : false
                    recentChat.jid = profile.jid
                    let color = getColor(userName: name)
                    cell.archivedStatusLabel.isHidden = true
                    cell.muteImageView.isHidden = true
                    cell.pinImageView.isHidden = true
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
        switch isSearchEnabled {
        case true:
            if indexPath.section == 1 || isSearchEnabled && indexPath.section == 2 {
                if filteredContactList.count >= indexPath.row{
                    ContactManager.shared.saveUser(profileDetails: filteredContactList[indexPath.row])
                    openContactChat(index: indexPath)
                }
            } else {
                didSelectRow(tableView: tableView, indexPath: indexPath)
            }
        case false:
            switch showArchivedChat {
            case true:
                didSelectRow(tableView: tableView, indexPath: indexPath)
            case false:
                if getRecentChat.count > 0 && getArchiveChat.count > 0 && showArchivedChat == false {
                    switch indexPath.section {
                    case FlyDefaults.isArchivedChatEnabled ? 0 : 1:
                        updateArchiveChatView()
                        recentChatTableView?.reloadData()
                    case FlyDefaults.isArchivedChatEnabled ? 1 : 0:
                        didSelectRow(tableView: tableView, indexPath: indexPath)
                    default:
                        break
                    }
                } else if getArchiveChat.count > 0 {
                    updateArchiveChatView()
                    recentChatTableView?.reloadData()
                } else {
                    didSelectRow(tableView: tableView, indexPath: indexPath)
                }
            }
        }
    }

    func didSelectRow(tableView: UITableView, indexPath: IndexPath) {
        if( isCellLongPressed ?? false) {
            if let cell = tableView.cellForRow(at: indexPath) as? RecentChatTableViewCell {
                if( longPressCount >= 1) {
                    if selectionRecentChatList.filter({$0.jid == (showArchivedChat ? getArchiveChat[indexPath.row].jid : getRecentChat[indexPath.row].jid) }).count == 0 {
                        cell.contentView.backgroundColor = Color.recentChatSelectionColor
                        longPressCount += 1
                        if showArchivedChat {
                            getArchiveChat[indexPath.row].isSelected = !getArchiveChat[indexPath.row].isSelected
                            selectionRecentChatList.insert(getArchiveChat[indexPath.row], at: 0)
                        } else {
                            getRecentChat[indexPath.row].isSelected = !getRecentChat[indexPath.row].isSelected
                            selectionRecentChatList.insert(getRecentChat[indexPath.row], at: 0)
                        }
                        selectionCountLabel?.text = String(longPressCount)
                        updatePinIcon()
                        updateMuteIcon()
                        updateArchiveIcon()
                    } else {
                        recentChatTableView?.delegate?.tableView!(tableView, didDeselectRowAt: indexPath)
                    }
                } else {
                    hideMultipleSelectionView()
                }
            }
        }
        if !(isCellLongPressed ?? false) {
            if showArchivedChat && (!getArchiveChat.isEmpty && getArchiveChat[indexPath.row].profileType == .groupChat && getArchiveChat[indexPath.row].isBlockedByAdmin) {
                showGroupBlockedView()
            } else if (!getRecentChat.isEmpty && getRecentChat[indexPath.row].profileType == .groupChat && getRecentChat[indexPath.row].isBlockedByAdmin) {
                showGroupBlockedView()
            } else if isSearchEnabled == true {
                if !ENABLE_CONTACT_SYNC {
                    if filteredContactList.count != 0 {
                        if filteredContactList.count >= indexPath.row{
                            ContactManager.shared.saveUser(profileDetails: filteredContactList[indexPath.row])
                        }
                    }
                }
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
                    let recentChatJid = showArchivedChat ? getArchiveChat[indexPath.row].jid : getRecentChat[indexPath.row].jid
                        if selectionRecentChatList.filter({$0.jid == recentChatJid}).count > 0 {
                            selectionRecentChatList.enumerated().forEach { (index,selectedRecentChat) in
                                if recentChatJid == selectedRecentChat.jid {
                                    cell.contentView.backgroundColor = .clear
                                    longPressCount -= 1
                                    if showArchivedChat {
                                        getArchiveChat[indexPath.row].isSelected = !getArchiveChat[indexPath.row].isSelected
                                        selectionRecentChatList.remove(at: index)
                                    } else {
                                        getRecentChat[indexPath.row].isSelected = !getRecentChat[indexPath.row].isSelected
                                        selectionRecentChatList.remove(at: index)
                                    }
                                    selectionCountLabel?.text = String(longPressCount)
                                    if selectionRecentChatList.count == 0 {
                                        hideMultipleSelectionView()
                                    }
                                    updatePinIcon()
                                    updateMuteIcon()
                                    updateArchiveIcon()
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
                getRecentChat[index].isSelected = false
                cell.contentView.backgroundColor = .clear
            }
        }
    }
    
    func openChat(index: Int) {
        let profile = showArchivedChat ? getArchiveChat[index] : getRecentChat[index]
        let vc = UIStoryboard.init(name: Storyboards.chat, bundle: Bundle.main).instantiateViewController(withIdentifier: Identifiers.chatViewParentController) as? ChatViewParentController
        let profileDetails = ProfileDetails(jid: profile.jid)
        profileDetails.name = profile.profileName
        profileDetails.nickName = profile.nickName
        profileDetails.image = profile.profileImage ?? ""
        profileDetails.profileChatType = profile.profileType
        if profile.isDeletedUser{
            profileDetails.contactType = .deleted
        }else{
            profileDetails.contactType = profile.isItSavedContact == true ? .live : .unknown
        }
        profileDetails.isBlockedByAdmin = profile.isBlockedByAdmin
        vc?.getProfileDetails = profileDetails
        let color = getColor(userName: profile.profileName)
        vc?.contactColor = color
        vc?.replyMessagesDelegate = self
        vc?.replyMessageObj = replyMessageObj
        vc?.replyJid = replyJid
        vc?.ismarkMessagesAsRead = true
        vc?.messageText = messageTxt
        vc?.navigationController?.modalPresentationStyle = .overFullScreen
        self.navigationController?.pushViewController(vc!, animated: true)
    }
    
    func openContactChat(index: IndexPath) {
        let vc = UIStoryboard.init(name: Storyboards.chat, bundle: Bundle.main).instantiateViewController(withIdentifier: Identifiers.chatViewParentController) as? ChatViewParentController
        switch index.section {
        case 0:
            if getRecentChat.count > index.row {
                let profile = getRecentChat[index.row]
                let profileDetails = ProfileDetails(jid: profile.jid)
                profileDetails.name = profile.profileName
                profileDetails.nickName = profile.nickName
                profileDetails.image = profile.profileImage ?? ""
                profileDetails.profileChatType = profile.profileType
                profileDetails.isBlockedByAdmin = profile.isBlockedByAdmin
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
                profileDetails.isBlockedByAdmin = profile.isBlockedByAdmin
                vc?.getProfileDetails = profileDetails
                let color = getColor(userName: profile.name)
                vc?.replyMessagesDelegate = self
                vc?.replyMessageObj = replyMessageObj
                vc?.replyJid = replyJid
                vc?.messageText = messageTxt
                vc?.contactColor = color
            }
        case 1:
            if unreadMessageChatList.count > index.row {
                let profile = unreadMessageChatList[index.row]
                let profileDetails = ProfileDetails(jid: profile.jid)
                profileDetails.name = profile.profileName
                profileDetails.nickName = profile.nickName
                profileDetails.isBlockedByAdmin = profile.isBlockedByAdmin
                profileDetails.profileChatType = profile.profileType
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
                profileDetails.isBlockedByAdmin = profile.isBlockedByAdmin
                profileDetails.image = profile.image
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
            profileDetails.isBlockedByAdmin = profile.isBlockedByAdmin
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
                    //weakSelf.filteredContactList.removeAll()
                    weakSelf.allContactsList = contactsList
                    weakSelf.allContactsList = weakSelf.allContactsList.sorted { getUserName(jid: $0.jid,name: $0.name, nickName: $0.nickName, contactType: $0.contactType)  < getUserName(jid: $1.jid,name: $1.name, nickName: $1.nickName, contactType: $1.contactType)  }
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
        
        
        recentChatListBuilder?.loadRecentChatList(completionHandler: {  [weak self] isSuccess, error, data in
            var result = data
            if  let weakSelf = self, let recentChatList = result.getData() as? [RecentChat], isSuccess{
                weakSelf.isRecentLoadingDone = false
                if weakSelf.isSearchEnabled == false {
                    weakSelf.clearChatList()
                    weakSelf.getRecentChat = recentChatList
                    weakSelf.getAllRecentChat = recentChatList
                    weakSelf.selectionRecentChatList.enumerated().forEach { (index,selectedRecentChat) in
                        weakSelf.getRecentChat.filter({$0.jid == selectedRecentChat.jid}).first?.isSelected = selectedRecentChat.isSelected
                    }
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

        ChatManager.getArchivedChatList { [weak self] isSuccess, error, data in
            if isSuccess {
                self?.getArchiveChat = data["data"] as? [RecentChat] ?? []
                self?.showHideEmptyMessage()
            }
        }
        
//        recentChatViewModel?.getRecentChatList(isBackground: true, completionHandler: { [weak self] recentChatList in
//            if let weakSelf = self {
//                if weakSelf.isSearchEnabled == false {
//                    weakSelf.clearChatList()
//                    weakSelf.getRecentChat = recentChatList ?? []
//                    weakSelf.getAllRecentChat = recentChatList ?? []
//                    weakSelf.selectionRecentChatList.enumerated().forEach { (index,selectedRecentChat) in
//                        weakSelf.getRecentChat.filter({$0.jid == selectedRecentChat.jid}).first?.isSelected = selectedRecentChat.isSelected
//                    }
//                  //weakSelf.getMessageForSearch()
//                }
//                DispatchQueue.main.async { [weak self] in
//                    if self?.isSearchEnabled == false {
//                        self?.recentChatTableView?.reloadData()
//                        self?.showHideEmptyMessage()
//                    }
//                    self?.getOverallUnreadCount()
//                }
//            }
//        })
    }
    
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
            scrollToTableViewTop()
            hideMultipleSelectionView()
            clearSelectedColor()
            getRecentChat = searchText.trim().isEmpty ? getAllRecentChat : getAllRecentChat.filter({ recentChat -> Bool in
                let name = getUserName(jid: recentChat.jid,name: recentChat.profileName, nickName: recentChat.nickName,contactType: recentChat.isItSavedContact ? .live : .unknown)
                return (name.range(of: searchText.trim(), options: [.caseInsensitive, .diacriticInsensitive]) != nil && recentChat.isDeletedUser == false)
            })
            if ENABLE_CONTACT_SYNC {
                filteredContactList = searchText.trim().isEmpty ? removeDuplicateFromContacts(contactList: allContactsList) : removeDuplicateFromContacts(contactList: allContactsList).filter({ contact -> Bool in
                    let name = getUserName(jid: contact.jid,name: contact.name, nickName: contact.nickName, contactType: contact.contactType)
                    return name.range(of: searchText.trim(), options: [.caseInsensitive, .diacriticInsensitive]) != nil
                })
            } else {
                let searchString = searchText.trim()
                if !searchString.isEmpty || self.searchTerm != searchString{
                    resetParams()
                    searchSubject.onNext(searchString.lowercased())
                }
            }
           
        } else {
            isSearchEnabled = false
            getRecentChatList()
            filteredContactList = []
            recentChatTableView?.tableFooterView = nil
        }
        
        recentChatTableView?.reloadData()
        if ENABLE_CONTACT_SYNC{
            showHideEmptyMessage()
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        refreshRecentChatMessages()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        scrollToTableViewTop()
        getRecentChatList()
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func scrollToTableViewTop() {
        self.recentChatTableView?.setContentOffset(.zero, animated: false)
    }
}

// UI Method
extension RecentChatViewController {
    func setProfile() {
        if currentIndex > -1{
            let profile = getRecentChat[currentIndex]
            let urlString = "\(FlyDefaults.baseURL)\(media)/\(profile.profileImage ?? "")?mf=\(FlyDefaults.authtoken)"
            let isDeletedUser = profile.isDeletedUser
            username?.text = getUserName(jid: profile.jid,name: profile.profileName, nickName: profile.nickName, contactType: isDeletedUser ? .deleted :  (profile.isItSavedContact ? .live : .unknown))
            let url = URL(string: urlString)
            let color = getColor(userName: getUserName(jid: profile.jid,name: profile.profileName, nickName: profile.nickName, contactType: profile.isItSavedContact ? .live : .unknown))
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
                userImage?.sd_setImage(with: url, placeholderImage: placeHolder)
            }else if isDeletedUser || getisBlockedMe(jid: profile.jid) || profile.isBlockedByAdmin {
                userImage?.backgroundColor =  Color.groupIconBackgroundGray
                userImage?.sd_setImage(with: nil, placeholderImage: UIImage(named: "ic_profile_placeholder") ?? UIImage())
            }else {
                placeHolder = getPlaceholder(name: getUserName(jid: profile.jid,name: profile.profileName, nickName: profile.nickName, contactType: profile.isItSavedContact ? .live : .unknown), color: color )
                userImage?.contentMode = .scaleAspectFill
                userImage?.sd_setImage(with: url, placeholderImage: placeHolder)
            }
        }
    }
    
    private func getBlocked(jid: String) -> Bool {
        return ChatManager.getContact(jid: jid)?.isBlocked ?? false
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
            emptyMessageView?.isHidden = (getRecentChat.count == 0 && getArchiveChat.count == 0 && filteredContactList.count == 0 && unreadMessageChatList.count == 0) ? false : true
            emptyImage?.isHidden = true
            noNewMsgText?.isHidden = false
            noNewMsgText?.text = noResultFound
            noNewMsgText?.textColor = .lightGray
            descriptionMessageText?.isHidden = true
        } else {
            emptyMessageView?.isHidden = (getRecentChat.count == 0 && getArchiveChat.count == 0) ? false : true
            emptyImage?.isHidden = false
            noNewMsgText?.isHidden = false
            noNewMsgText?.text = noNewMessage
            noNewMsgText?.textColor = .black
            descriptionMessageText?.isHidden = false
        }
    }
    
    private func getisBlockedMe(jid: String) -> Bool {
        return ChatManager.getContact(jid: jid)?.isBlockedMe ?? false
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
        recentChatTableView?.tableFooterView = nil
    }
}

extension RecentChatViewController : ConnectionEventDelegate {
    func onConnected() {
        if !Utility.getBoolFromPreference(key: "oneTimeSync") {
            ContactSyncManager.shared.syncContacts(){ isSuccess,_,_ in
                if isSuccess {
                    print("oneTimeSync", isSuccess)
                    Utility.saveInPreference(key: "oneTimeSync", value: true)
                }
            }
        }
    }
    
    func onDisconnected() {}
    
    func onConnectionNotAuthorized() {}
}

// MessageEventDelegate
extension RecentChatViewController : MessageEventsDelegate {
   
    func onMessageTranslated(message: ChatMessage, jid: String) {
        
    }
    
    func onMessageStatusUpdated(messageId: String, chatJid: String, status: MessageStatus) {
        print("onMessageStatusUpdated \(messageId) \(chatJid) \(status)")
        getRecentChatList()
    }
    
    func onMediaStatusUpdated(message: ChatMessage) {
        
    }
    
    func onMediaStatusFailed(error: String, messageId: String) {
        
    }
    
    func onMediaProgressChanged(message: ChatMessage, progressPercentage: Float) {
        
    }
    
    func onMessagesClearedOrDeleted(messageIds: Array<String>) {
        getRecentChatList()
    }
    
    func onMessagesDeletedforEveryone(messageIds: Array<String>) {
        getRecentChatList()
    }
    
    func showOrUpdateOrCancelNotification() {}
    
    func onMessagesCleared(toJid: String) {
        if let index = getRecentChat.firstIndex(where: { pd in pd.jid == toJid }) {
            if let recentChat = ChatManager.getRechtChat(jid: toJid) {
                getRecentChat[index] = recentChat
                let indexPath = IndexPath(item: index, section: 0)
                recentChatTableView?.reloadRows(at: [indexPath], with: .fade)
            }
        }
    }
    
    func setOrUpdateFavourite(messageId: String, favourite: Bool, removeAllFavourite: Bool) {}
    
    func onMessageReceived(message: ChatMessage, chatJid: String) {
        print("onMessageReceived \(message.messageId) \(chatJid)")
        unArchiveChatOnEvents(jids: [chatJid])
        if isSearchEnabled == false {
            refreshRecentChatMessages()
        }
    }
}

// Profile Event Delegate
extension RecentChatViewController : ProfileEventsDelegate {
    func userCameOnline(for jid: String) {}
    
    func userWentOffline(for jid: String) {}
    
    func userProfileFetched(for jid: String, profileDetails: ProfileDetails?) {
        
        if let index = getRecentChat.firstIndex(where: { pd in pd.jid == jid }) {
            getRecentChat[index].profileImage = profileDetails?.image
            getRecentChat[index].profileName = profileDetails?.name ?? ""
            print("userUpdatedTheirProfile currentIndex \(currentIndex)")
            let profile = ["jid": profileDetails?.jid, "name": profileDetails?.name, "image": profileDetails?.image, "status": profileDetails?.status]
            NotificationCenter.default.post(name: Notification.Name(Identifiers.ncProfileUpdate),
                                            object: nil,userInfo: profile as [AnyHashable: Any])
            NotificationCenter.default.post(name: Notification.Name(FlyConstants.contactSyncState),
                                            object: nil, userInfo: profile as [AnyHashable: Any])
            let indexPath = IndexPath(item: index, section: 0)
            recentChatTableView?.reloadRows(at: [indexPath], with: .fade)
        }
    }
    
    func myProfileUpdated() {}
    
    func usersProfilesFetched() {
        print("RecentChatViewController usersProfilesFetched")
        getRecentChatList()
        if ENABLE_CONTACT_SYNC{
            getContactList()
        }
        setProfile()
    }
    
    func blockedThisUser(jid: String) {}

    func unblockedThisUser(jid: String) {}

    func usersIBlockedListFetched(jidList: [String]) {}
    
    func usersBlockedMeListFetched(jidList: [String]) {}
    
    func userBlockedMe(jid: String) {
        if let recentChat = ChatManager.getRechtChat(jid: jid){
            if isSearchEnabled{
                if let indexofJid = getRecentChat.firstIndex(where: { pd in pd.jid == jid }){
                    getRecentChat[indexofJid] = recentChat
                    reloadRecentChatRow(index: indexofJid, section: 0)
                }else if let indexofJid = filteredContactList.firstIndex(where: { pd in pd.jid == jid }), let profileDetails = ChatManager.profileDetaisFor(jid: jid){
                    filteredContactList[indexofJid] = profileDetails
                    reloadRecentChatRow(index: indexofJid, section: 1)
                }
            }else if let indexofJid = getRecentChat.firstIndex(where: { pd in pd.jid == jid }) {
                getRecentChat[indexofJid] = recentChat
                reloadRecentChatRow(index: indexofJid, section: 0)
            }
        }
    }
    
    func userUnBlockedMe(jid: String) {
        if let recentChat = ChatManager.getRechtChat(jid: jid){
            if isSearchEnabled{
                if let indexofJid = getRecentChat.firstIndex(where: { pd in pd.jid == jid }){
                    getRecentChat[indexofJid] = recentChat
                    reloadRecentChatRow(index: indexofJid, section: 0)
                }else if let indexofJid = filteredContactList.firstIndex(where: { pd in pd.jid == jid }), let profileDetails = ChatManager.profileDetaisFor(jid: jid){
                    filteredContactList[indexofJid] = profileDetails
                    reloadRecentChatRow(index: indexofJid, section: 1)
                }
            }else if let indexofJid = getRecentChat.firstIndex(where: { pd in pd.jid == jid }) {
                getRecentChat[indexofJid] = recentChat
                reloadRecentChatRow(index: indexofJid, section: 0)
            }
        }
    }
    
    func hideUserLastSeen() {}
    
    func getUserLastSeen() {}
    
    func userUpdatedTheirProfile(for jid: String, profileDetails: ProfileDetails) {
        print("userUpdatedTheirProfile \(jid)")
        if let index = getRecentChat.firstIndex(where: { pd in pd.jid == jid }) {
            getRecentChat[index].profileImage = profileDetails.image
            getRecentChat[index].profileName = profileDetails.name
            print("userUpdatedTheirProfile currentIndex \(currentIndex)")
            let profile = ["jid": profileDetails.jid, "name": profileDetails.name, "image": profileDetails.image, "status": profileDetails.status]
            NotificationCenter.default.post(name: Notification.Name(Identifiers.ncProfileUpdate), object: nil,
                                            userInfo: profile as [AnyHashable : Any])
            NotificationCenter.default.post(name: Notification.Name(FlyConstants.contactSyncState), object: nil,
                                            userInfo: profile as [AnyHashable : Any])
            let indexPath = IndexPath(item: index, section: 0)
            recentChatTableView?.reloadRows(at: [indexPath], with: .fade)
            
            if profilePopupContainer?.isHidden == false  && currentIndex == index {
                setProfile()
            }
        }
    }
    
    func userDeletedTheirProfile(for jid : String, profileDetails:ProfileDetails){
        print("#userDeleted \(jid)  \(profileDetails.name) \(profileDetails.nickName)")
        if let index = getRecentChat.firstIndex(where: { pd in pd.jid == jid }) {
            getRecentChat[index].profileImage = profileDetails.image
            getRecentChat[index].profileName = profileDetails.name
            getRecentChat[index].nickName = profileDetails.nickName
            getRecentChat[index].isItSavedContact = false
            getRecentChat[index].isDeletedUser = true
        }
        if let index = getAllRecentChat.firstIndex(where: { pd in pd.jid == jid }) {
            getAllRecentChat[index].profileImage = profileDetails.image
            getAllRecentChat[index].profileName = profileDetails.name
            getAllRecentChat[index].nickName = profileDetails.nickName
            getAllRecentChat[index].isItSavedContact = false
            getAllRecentChat[index].isDeletedUser = true
        }
        if let index = allContactsList.firstIndex(where: { pd in pd.jid == jid }) {
            allContactsList.remove(at: index)
            
        }
        if let index = filteredContactList.firstIndex(where: { pd in pd.jid == jid }) {
            filteredContactList.remove(at: index)
        }
        recentChatTableView?.reloadData()
    }
    
    func reloadRecentChatRow(index : Int, section : Int){
        let indexPath = IndexPath(item: index, section: section)
        recentChatTableView?.reloadRows(at: [indexPath], with: .fade)
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
        DispatchQueue.main.async { [weak self] in
            self?.updateGroupInRecentChat(groupJid: groupJid)
        }
    }
    
    func didAddNewMemeberToGroup(groupJid: String, newMemberJid: String, addedByMemberJid: String) {
        DispatchQueue.main.async { [weak self] in
            self?.updateGroupInRecentChat(groupJid: groupJid)
        }
    }
    
    func didRemoveMemberFromGroup(groupJid: String, removedMemberJid: String, removedByMemberJid: String) {
        DispatchQueue.main.async { [weak self] in
            self?.updateGroupInRecentChat(groupJid: groupJid)
        }
    }
    
    func didMakeMemberAsAdmin(groupJid: String, newAdminMemberJid: String, madeByMemberJid: String) {
        DispatchQueue.main.async { [weak self] in
            self?.updateGroupInRecentChat(groupJid: groupJid)
        }
    }
    
    func didDeleteGroupLocally(groupJid: String) {
        DispatchQueue.main.async { [weak self] in
            self?.getRecentChat = self?.getRecentChat.filter({ $0.jid != groupJid}) ?? []
            self?.getAllRecentChat = self?.getAllRecentChat.filter({ $0.jid != groupJid}) ?? []
            self?.recentChatTableView?.reloadData()
        }
    }
    
    func didLeftFromGroup(groupJid: String, leftUserJid: String) {
        DispatchQueue.main.async { [weak self] in
            self?.updateGroupInRecentChat(groupJid: groupJid)
        }
    }
    
    func didCreateGroup(groupJid: String) {
        DispatchQueue.main.async { [weak self] in
            self?.updateGroupInRecentChat(groupJid: groupJid)
        }
    }
    
    func didFetchGroupMembers(groupJid: String) {
        
    }
    
    func didReceiveGroupNotificationMessage(message: ChatMessage) {
        
    }
    
    func didUpdateGroupProfile(groupJid: String) {
        DispatchQueue.main.async { [weak self] in
            if let index = self?.getRecentChat.firstIndex(where: { pd in pd.jid == groupJid }) {
                let group = self?.recentChatViewModel?.getGroupDetails(groupJid: groupJid)
                
                self?.getRecentChat[index].profileImage = group?.image
                self?.getRecentChat[index].profileName = group?.name ?? ""
                let groupProfile = ["jid": group?.jid, "name": group?.name, "image": group?.image, "status": group?.status]
                
                NotificationCenter.default.post(name: Notification.Name(Identifiers.ncProfileUpdate), object: nil,
                                                userInfo: groupProfile as [AnyHashable : Any])
                NotificationCenter.default.post(name: Notification.Name(FlyConstants.contactSyncState), object: nil,
                                                userInfo: groupProfile as [AnyHashable : Any])
                
                let indexPath = IndexPath(item: index, section: 0)
                self?.recentChatTableView?.reloadRows(at: [indexPath], with: .fade)
                
                if self?.profilePopupContainer?.isHidden == false  && self?.currentIndex == index {
                    self?.setProfile()
                }
            }
            self?.updateGroupInRecentChat(groupJid: groupJid)
        }
    }
    
    func didFetchGroups(groups: [ProfileDetails]) {
        print("RecentChatViewController didGetGroups \(groups.count)")
        getRecentChatList()
    }
    
    func didFetchGroupProfile(groupJid: String) {
    }
}

extension RecentChatViewController : ReplyMessagesDelegate {
    func replyMessageObj(message: ChatMessage?,jid: String,messageText: String) {
        replyMessageObj = message
        replyJid = jid
        messageTxt = messageText
    }
}

extension RecentChatViewController : AdminBlockDelegate {
    func didBlockOrUnblockContact(userJid: String, isBlocked: Bool) {
        updateAdminBlockedState(jid: userJid, isBlocked: isBlocked)
    }
    
    func didBlockOrUnblockSelf(userJid: String, isBlocked: Bool) {
        
    }
    
    func didBlockOrUnblockGroup(groupJid: String, isBlocked: Bool) {
        updateAdminBlockedState(jid: groupJid, isBlocked: isBlocked)
    }
}

// To hanlde User (group, single user, current user) Bloced events
extension RecentChatViewController {
    func updateAdminBlockedState(jid : String, isBlocked : Bool) {
        executeOnMainThread { [weak self] in
            if let recentChats = self?.getRecentChat {
                for (index, recent) in recentChats.enumerated() {
                    if recent.jid == jid {
                        self?.getRecentChat[index].isBlockedByAdmin = isBlocked
                        if self?.getRecentChat[index].isGroup ?? false && isBlocked {
                            self?.userImage?.image = UIImage(named: "ic_groupPlaceHolder")
                        } else {
                            self?.setProfile()
                        }
                        self?.recentChatTableView?.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                        break
                    }
                }
            }
        }
    }
}

// To hanlde Group Events
extension RecentChatViewController {
    
    func updateGroupInRecentChat(groupJid : String) {
        let groupAndRecent = getGroupAndRecent(groupJid: groupJid)
        if checkGroupExistInRecntChat(groupJid: groupJid) {
            executeOnMainThread { [weak self] in
                self?.getRecentChat.enumerated().forEach { (index, element) in
                    if element.jid == groupJid {
                        if let recent = groupAndRecent.recentChat {
                            self?.getRecentChat.remove(at: index)
                            self?.getRecentChat.insert(recent, at: element.isChatPinned ? index : ChatManager.recentChatPinnedCount())
                            print("\(self?.getRecentChat[index].nickName ?? "")")
                            self?.recentChatTableView?.reloadData()
                        }
                    }
                }
            }
        } else {
            if let recent = groupAndRecent.recentChat {
                executeOnMainThread { [weak self] in
                    self?.getRecentChat.insert(recent, at: ChatManager.recentChatPinnedCount())
                    self?.recentChatTableView?.reloadData()
                }
            }
        }
    }
    
    func getGroupAndRecent(groupJid : String) -> (groupProfile : ProfileDetails? , recentChat : RecentChat?) {
        let group = recentChatViewModel?.getGroupDetails(groupJid: groupJid)
        let recentChat = recentChatViewModel?.getRecentChat(jid: groupJid)
        return(group,recentChat)
    }
    
    func checkGroupExistInRecntChat(groupJid : String) -> Bool{
        return getRecentChat.filter ({$0.jid == groupJid}).first != nil
    }
}

extension RecentChatViewController : UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let position  = scrollView.contentOffset.y
        print("#scroll #load recentChatList loading done \(isSearchEnabled)")
        if !isSearchEnabled{
            
            if ((recentChatTableView!.contentSize.height-scrollView.frame.size.height) - position) < (2 * scrollView.frame.size.height){
                if isRecentLoadingDone{
                    print("#scroll #load recentChatList loading done")
                    return
                }
                
                if !isRecentLoadingInProgress{
                    isRecentLoadingInProgress = true
                    backgroundQueue.async {
                        self.loadNextSetOfData()
                    }
                }
            }
            
        }
        if ENABLE_CONTACT_SYNC{
            return
        }else{
            
            if position > (recentChatTableView?.contentSize.height ?? 300)-200 - scrollView.frame.size.height {
                if isPaginationCompleted(){
                    print("#fetch Pagination Done")
                    return
                }
                recentChatTableView?.tableFooterView = createTableFooterView()
                if !isLoadingInProgress{
                    isLoadingInProgress = true
                    getUsersList(pageNo: searchTerm.isEmpty ? nextPage : searchNextPage, pageSize: 20, searchTerm: searchTerm)
                }
            }
        }
    }
    
    func loadNextSetOfData()  {
        print("#scroll loadNextSetOfData")
        recentChatListBuilder?.nextSetOfData(completionHandler: {  [weak self] isSuccess, error, data in
            var result = data
            if  let weakSelf = self, let recentChatList = result.getData() as? [RecentChat], isSuccess{
                weakSelf.getAllRecentChat.append(contentsOf: recentChatList)
                weakSelf.getRecentChat.append(contentsOf: recentChatList)
                if !(weakSelf.recentChatListBuilder?.hasNextRecentChatData() ?? true){
                    weakSelf.isRecentLoadingDone = true
                }
            }
            DispatchQueue.main.async { [weak self] in
                self?.isRecentLoadingInProgress = false
                if self?.isSearchEnabled == false {
                    self?.recentChatTableView?.reloadData()
                }
                self?.getOverallUnreadCount()
            }
        })
    }
    
    public func getUsersList(pageNo : Int = 1, pageSize : Int =  40, searchTerm : String){
        print("#fetch request \(pageNo) \(pageSize) \(searchTerm) ")
        if pageNo == 1 {
            recentChatTableView?.tableFooterView = createTableFooterView()
            noNewMsgText?.isHidden = true
        }
        if !NetStatus.shared.isConnected{
            AppAlert.shared.showToast(message: ErrorMessage.noInternet)
            return
        }
        isLoadingInProgress = true
        ContactManager.shared.getUsersList(pageNo: pageNo, pageSize: pageSize, search: searchTerm) { [weak self] isSuccess, flyError, flyData in
            guard let self = self else {
                return
            }
            if isSuccess{
                var data = flyData
                var profilesCount = 0
                if pageNo == 1{
                    self.isFirstPageLoaded = true
                }
                if let profileArray = data.getData() as? [ProfileDetails]{
                    self.removeDuplicates(profileDetails: profileArray)
                    if pageNo == 1{
                        self.filteredContactList.removeAll()
                    }
                    self.filteredContactList.append(contentsOf: profileArray)
                    profilesCount = profileArray.count
                }
                if profilesCount >= pageSize{
                    self.searchNextPage += 1
                }
                self.searchTotalPages = data["totalPages"] as? Int ?? 1
                self.searchTotalUsers = data["totalRecords"] as? Int ?? 1
                print("#fetch response search total => \(self.searchTotalPages) nextPage => \(self.searchNextPage) searchTotoalUsers => \(self.searchTotalUsers) profilesCount => \(profilesCount) searchTerm => \(self.searchTerm)")
                self.recentChatTableView?.tableFooterView = nil
                self.recentChatTableView?.reloadData()
                self.showHideEmptyMessage()
            }else{
                if !NetworkReachability.shared.isConnected{
                    AppAlert.shared.showToast(message: ErrorMessage.noInternet)
                }else{
                    var data = flyData
                    if let message = data.getMessage() as? String{
                        print("#error \(message)")
                    }
                }
            }
            self.isLoadingInProgress = false
        }
    }
    
    public func isPaginationCompleted() -> Bool {
        if (searchTotalPages < searchNextPage) || filteredContactList.count == searchTotalUsers {
            return true
        }
        return false
    }
    
    public func resetDataAndFetchUsersList(){
        filteredContactList.removeAll()
        if !isSearchEnabled {
            return
        }
        resetParams()
        recentChatTableView?.reloadData()
        getUsersList(pageNo: 1, pageSize: 20, searchTerm: searchTerm)
    }
    
    public func resetParams(){
        totalPages = 2
        totalUsers = 1
        nextPage = 1
        searchTotalPages = 2
        searchTotalUsers = 1
        searchNextPage = 1
        isLoadingInProgress = false
        isFirstPageLoaded = false
    }
    
    public func createTableFooterView() -> UIView{
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 64))
        let spinner = UIActivityIndicatorView()
        spinner.center = footerView.center
        footerView.addSubview(spinner)
        spinner.startAnimating()
        return footerView
    }
    
    @objc func networkChange(_ notification: NSNotification) {
        DispatchQueue.main.async { [weak self] in
            let isNetworkAvailable = notification.userInfo?[NetStatus.isNetworkAvailable] as? Bool ?? false
            self?.internetObserver.on(.next(isNetworkAvailable))
        }
        
    }
    
    func  resumeLoading()  {
        if !ENABLE_CONTACT_SYNC{
            if isLoadingInProgress || !isPaginationCompleted() {
                print("#internet nextPage => \(self.nextPage)")
                self.getUsersList(pageNo: self.searchTerm.isEmpty ? self.nextPage : self.searchNextPage, pageSize: 20, searchTerm: self.searchTerm)
            }
        }
    }
    
    func removeDuplicates(profileDetails : [ProfileDetails])  {
        let userIds = profileDetails.compactMap{$0.jid}
        filteredContactList.removeAll { pd in
            userIds.contains(pd.jid)
        }
    }
    
    public func saveUserToDatabase(jid : String){
        if let index = filteredContactList.firstIndex { pd in pd.jid == jid}{
            ContactManager.shared.saveUser(profileDetails: filteredContactList[index], saveAs: .live)
        }
    }
}

//MARK: - Archive chat extension
extension RecentChatViewController {

    //Get status whether is archive or Unarchive
    func isArchive() -> Bool {
        return selectionRecentChatList.filter {$0.isChatArchived == false }.count > 0 ? true : false
    }

    //Update archive icon
    func updateArchiveIcon() {
        archiveChatButton.setImage(isArchive() ? UIImage(named: "archive") : UIImage(named: "unarchive"), for: .normal)
    }

    func hideArchiveHeader() {
        showArchivedChat = false
        headerBackButton.isHidden = true
        searchView.isHidden = false
        createGroupButton.isHidden = false
        pinChatButton.isHidden = false
        headerLabel.text = "Chats"
    }

    func updateArchiveChatView() {
        showArchivedChat = true
        headerBackButton.isHidden = false
        searchView.isHidden = true
        createGroupButton.isHidden = true
        pinChatButton.isHidden = true
        headerLabel.text = "Archive Chats"
    }

    func unArchiveChatOnEvents(jids: [String]) {
        if !FlyDefaults.isArchivedChatEnabled {
            recentChatViewModel?.getArchiveChat(jids: jids, isArchive: false, completionHandler: { isSuccess, error, data in
                print(data)
            })
        }
    }
}

extension RecentChatViewController : AvailableFeaturesDelegate {
    
    func didUpdateAvailableFeatures(features: AvailableFeaturesModel) {
        
        availableFeatures = features
        searchBar?.isHidden = !(availableFeatures.isRecentChatSearchEnabled) ? true : false
        
        if !(availableFeatures.isRecentChatSearchEnabled){
            refreshRecentChatMessages()
        }
        
        let tabCount =  MainTabBarController.tabBarDelegagte?.currentTabCount()
        
        if (!(availableFeatures.isGroupCallEnabled || availableFeatures.isOneToOneCallEnabled) && tabCount == 5) {
            MainTabBarController.tabBarDelegagte?.removeTabAt(index: 2)
        }else {
            
            if ((availableFeatures.isGroupCallEnabled || availableFeatures.isOneToOneCallEnabled) && tabCount ?? 0 < 5){
                MainTabBarController.tabBarDelegagte?.resetTabs()
            }
            
        }
    }
}
