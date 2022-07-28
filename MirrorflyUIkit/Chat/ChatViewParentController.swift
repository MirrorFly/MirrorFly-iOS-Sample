
//  ChatViewParentController.swift
//  MirrorflyUIkit
//  Created by User on 19/08/21.

import Foundation
import UIKit
import GrowingTextViewHandler_Swift
import IQKeyboardManagerSwift
import FlyCore
import FlyCommon
import FlyNetwork
import BSImagePicker
import Photos
import AVFoundation
import Contacts
import ContactsUI
import SDWebImage
import MapKit
import MobileCoreServices
import AVKit
import PhotosUI
import FlyCall
import XMPPFramework
import MarqueeLabel
import MenuItemKit
import Floaty
import Tatsi
import QCropper
import NicoProgress
import SwiftUI

import FlyTranslate


import RxSwift


protocol TableViewCellDelegate {
    func openBottomView(indexPath: IndexPath)
}

protocol ReplyMessagesDelegate {
    func replyMessageObj(message: ChatMessage?,jid: String,messageText: String)
}

class ChatViewParentController: UIViewController,UITextViewDelegate,
                                UIGestureRecognizerDelegate, UINavigationControllerDelegate,CNContactViewControllerDelegate {
    
    //MARK : Header Design
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var multiSelectionView: UIView!
    @IBOutlet weak var longPressCountLabel: UILabel!
    @IBOutlet weak var replyButton: UIButton!
    @IBOutlet weak var copyButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var lastSeenLabel: UILabel!
    @IBOutlet weak var userInfoStack: UIStackView!
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var videoButton: UIButton!
    @IBOutlet weak var audioButton: UIButton!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var chatTableView: UITableView!
    @IBOutlet weak var chatTableViewBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var groupMemberLable: MarqueeLabel!
    
    //MARK : Bottom Text Design
    @IBOutlet weak var textToolBarView: UIView?
    @IBOutlet weak var textToolBarViewHeight: NSLayoutConstraint?
    @IBOutlet weak var chatTextView: UIView?
    @IBOutlet weak var messageTextView: UITextView?
    @IBOutlet weak var messageTextViewHeight: NSLayoutConstraint?
    @IBOutlet weak var sendButton: UIButton?
    
    //MARK : ReplyView Bottom Text Design
    @IBOutlet weak var replyView: UIView!
    @IBOutlet weak var containerBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableViewBottomConstraint: NSLayoutConstraint?
    
    //audio outlets
    @IBOutlet weak var audioImage: UIImageView!
    @IBOutlet weak var audioView: UIView!
    @IBOutlet weak var audioTimerLabel: UILabel!
    
    @IBOutlet weak var forwardBottomView: UIView?
    @IBOutlet weak var cancelButton: UIButton?
    @IBOutlet weak var forwardButton: UIButton?
    
    // Forward Local Variable
    var isShowForwardView: Bool = false
    
    var chatTextViewXib:ChatTextView?
    var growingTextViewHandler:GrowingTextViewHandler?
    var messages : [ChatMessage]  = []
    var getAllMessages : [ChatMessage]  = []
    var contactNumber: [String] = []
    var contactStatus: [String] = []
    var contactLabel: [String] = []
    let chatManager = ChatManager.shared
    var imagePicker: UIImagePickerController!
    var isSelectOn = false
    var selectedIndexs = [IndexPath]()
    var chatMessages: [[ChatMessage]] = [[ChatMessage]]()
    var forwardMessages: [SelectedForwardMessage]? = []
    var getProfileDetails: ProfileDetails!
    var alertController : UIAlertController?
    var isPopToRootVC: Bool? = false
    var sendMediaMessages: [ChatMessage]? = []
    var receivedMediaMessages: [ChatMessage]? = []
    var uploadingMediaObjects: [ChatMessage]? = []
    var isShowAudioLoadingIcon: Bool? = false
    var callDurationTimer : Timer?
    var lastSelectedCollection: PHAssetCollection?
    var replyMessagesDelegate: ReplyMessagesDelegate?
    var isImagePicked: Bool = false
    var replyMessageObj: ChatMessage?
    var replyJid: String?
    var messageText: String?
    var replyCloseButtonTapped: Bool? = false
    var ismarkMessagesAsRead: Bool? = false
    var mediaMessagesToSend : [ImageData]?
    
    
    private var uploadMediaQueue: [ChatMessage]?
    private var timer: Timer?
    private var uploading = false
    
    // If the rememberCollectioSwitch is turned on we return the last known collection, if available.
     var firstView: TatsiConfig.StartView {
        if let lastCollection = self.lastSelectedCollection {
            return .album(lastCollection)
        } else {
            return .userLibrary
        }
    }
    
    //audio
    var audioViewXib: AudioView?
    var audioRecorder:AVAudioRecorder?
    var audioPlayer:AVAudioPlayer?
    var audioTimer:Timer!
    var updater : CADisplayLink! = nil
    var isAudioRecordingGranted = false
    let contactManager = ContactManager.shared
    let toolTipController = UIMenuController.shared
    var contactDetails: [ContactDetails] = []
    var isReplyViewOpen: Bool = false
    var replyMessageId = ""
    var longPressCount: Int = 0
    var isCellLongPressed: Bool = false
    var previousIndexPath : IndexPath = IndexPath()
    var currenAudioIndexPath : IndexPath? = IndexPath(row: 0, section: 0)
    var previousAudioIndexPath : IndexPath? = IndexPath(row: -1, section: -1)
    var currentPreviewIndexPath : IndexPath? = IndexPath(row: 0, section: 0)
    var currentIndexPath: IndexPath = IndexPath()
    private var selectedAssets = [PHAsset]()
    var isNetworkConnected: Bool = true
    var mLatitude : Double = 0.0
    var mLongitude : Double = 0.0
    var toViewLocation = false
    var groupMembers = [GroupParticipantDetail]()
    
    //contact
    var contactColor = UIColor()
    
    var isFromGroupInfo: Bool = false
    
    //Mark: Translate Message
    var targetLanguageCode: String?
    
    var selectedChatMessage : ChatMessage? = nil
 
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
        configureDefaults()
        callDurationTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateCallDuration), userInfo: nil, repeats: true)
        //get Message from DB
        getMessages()
        chatTableView.dataSource = self
        chatTableView.delegate = self
        chatTableView.transform = CGAffineTransform(rotationAngle: -.pi)
        chatTableView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right:  chatTableView.bounds.size.width - CGFloat(constraintsConstant))
        chatTableView.rowHeight = UITableView.automaticDimension
        chatTableView.estimatedRowHeight = UITableView.automaticDimension
        tableViewBottomConstraint?.constant = CGFloat(chatBottomConstant)
        containerView.bringSubviewToFront(chatTableView)
        loadAudioView()
        handleSendButton()
        audioButton.imageEdgeInsets = UIEdgeInsets(top: 6, left: 8, bottom: 6, right: 8)
        videoButton.imageEdgeInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        print("MYJId \(FlyDefaults.myJid)")
        print("username : \(FlyDefaults.myXmppUsername)")
        checkGalleryPermission()
        chatTextViewXib?.cannotSendMessageView?.isHidden = true
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            let matchingNotifications = notifications.filter({ $0.request.content.threadIdentifier == self.getProfileDetails.jid })
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: matchingNotifications.map({ $0.request.identifier }))
        }
        NotificationCenter.default.addObserver(self, selector: #selector(self.contactSyncCompleted(notification:)), name: NSNotification.Name(FlyConstants.contactSyncState), object: nil)
        
        //MARK: Function call for the Message Translation

       // translateIncomingMessage()
        
        uploadMediaQueue = [];
        startUploadMediaTimer();
        checkForUserBlocked()

    }
    
    deinit {
        //stopUploadMediaTimer();
    }
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let value = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let newHeight: CGFloat
                if #available(iOS 11.0, *) {
                    newHeight = value.height - view.safeAreaInsets.bottom
                } else {
                    newHeight = value.height
                }
            self.containerBottomConstraint.constant = newHeight//
        }
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        //chatTableView.contentInset = .zero
        //self.tableViewBottomConstraint.constant = CGFloat(chatBottomConstant)
        self.containerBottomConstraint.constant = 0.0
    }
    
    func checkGalleryPermission() {
        let status = PHPhotoLibrary.authorizationStatus()
        if status != .authorized {
            AppPermissions.shared.checkGalleryPermission { phAuthorizationStatus in
                
            }
        }
    }

    @objc func updateCallDuration() {
        if !NetworkReachability.shared.isConnected {
            if isNetworkConnected == true {
                AppAlert.shared.showToast(message: ErrorMessage.noInternet)
                isNetworkConnected = false
            }
        } else {
            isNetworkConnected = true
        }
    }
    
    @objc override func didMoveToBackground() {
        print("ChatViewParentController moved to background")
        view.endEditing(true)
        stopPlayer(isBecomeBackGround: true)
        
        if UIApplication.shared.isKeyboardPresented {
            print("Keyboard presented")
            self.messageTextView?.becomeFirstResponder()
        } else {
            print("Keyboard is not presented")
        }
    }
    
    @objc override func willCometoForeground() {
        print("ChatViewParentController ABC appComestoForeground")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            if self?.isReplyViewOpen == true {
                self?.view.endEditing(true)
            }
            
            if (self?.chatMessages.count ?? 0) > 0 {
                self?.handleSendButton()
            }
            
            if self?.replyMessageObj != nil && self?.replyJid == self?.getProfileDetails.jid {
                self?.chatMessages.enumerated().forEach { (section,chatMessage) in
                    chatMessage.enumerated().forEach { (row,message) in
                        if message.messageId == self?.replyMessageObj?.messageId {
                            self?.replyMessage(indexPath: IndexPath(row: row, section: section))
                        }
                    }
                }
            }
            
            FlyMessenger.resetFailedMediaMessages(chatUserJid: self?.getProfileDetails.jid ?? "")
            self?.configureDefaults()
            self?.ismarkMessagesAsRead = false
            self?.getMessages()
        }
    }
    
    func getMessages() {
        if !getAllMessages.isEmpty {
            getAllMessages.removeAll()
        }
        if chatMessages.count > 0 {
            chatMessages.removeAll()
        }
        getAllMessages = FlyMessenger.getMessagesOf(jid: getProfileDetails.jid)
        if(getAllMessages.count > 0) {
            getAllMessages = getAllMessages.filter({$0.messageType != MessageType.document}) // This line to be removed after document message implementation
            groupPreviousMessages(messages: getAllMessages)
           
        }
    }
    
    /**
     * to configure delegates
     * to initialize
     */
    func configureDefaults() {
        audioRecorder?.delegate = self
        audioPlayer?.delegate = self
        networkMonitor()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ChatManager.setOnGoingChatUser(jid: getProfileDetails.jid)
        print("ChatViewParentController ABC viewWillAppear")
        handleBackgroundAndForground()
        getLastSeen()
        markMessagessAsRead()
        headerView.isHidden = false
        navigationController?.setNavigationBarHidden(false, animated: animated)
        setUpHeaderView()
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        IQKeyboardManager.shared.enableAutoToolbar = false
        navigationController?.navigationBar.isHidden = false
        navigationController?.navigationBar.barTintColor = .white
        NotificationCenter.default.addObserver(self, selector: #selector(self.profileNotification(notification:)), name: Notification.Name(Identifiers.ncProfileUpdate), object: nil)
        audioButton.tag = 101
        videoButton.tag = 102
        audioButton.addTarget(self, action: #selector(makeCall(_:)), for: .touchUpInside)
        videoButton.addTarget(self, action: #selector(makeCall(_:)), for: .touchUpInside)
        menuButton.addTarget(self, action: #selector(didTapMenu(_:)), for: .touchUpInside)
        
        if getProfileDetails.profileChatType == .groupChat {
            getParticipants()
            getGroupMember()
            checkMemberOfGroup()
        }
        forwardBottomView?.isHidden = isShowForwardView == true ? false : true
        lastSeenLabel.isHidden = (getProfileDetails.profileChatType == .groupChat)
        groupMemberLable.isHidden = (getProfileDetails.profileChatType == .singleChat)
        messageTextView?.text = (messageText?.isNotEmpty ?? true) ? messageText : ""
        if replyMessageObj != nil && replyJid == getProfileDetails.jid {
            chatMessages.enumerated().forEach { (section,chatMessage) in
                chatMessage.enumerated().forEach { (row,message) in
                    if message.messageId == replyMessageObj?.messageId {
                        replyMessage(indexPath: IndexPath(row: row, section: section))
                    }
                }
            }
        } 
        view.backgroundColor = .white
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        getUserForAdminBlock()
    }
    
    private func getUserForAdminBlock() -> Bool{
        let profile = ChatManager.profileDetaisFor(jid: getProfileDetails.jid)
        guard let isBlockedByAdmin = profile?.isBlockedByAdmin else { return false }
        executeOnMainThread { [weak self] in
            self?.checkUserForBlocking(jid: self?.getProfileDetails.jid ?? "", isBlocked: isBlockedByAdmin)
        }
        return isBlockedByAdmin
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        ContactManager.shared.profileDelegate = self
        GroupManager.shared.groupDelegate = self
        ChatManager.shared.adminBlockDelegate = self
        chatManager.messageEventsDelegate = self
        FlyMessenger.shared.messageEventsDelegate = self
        chatManager.connectionDelegate = self
        chatManager.typingStatusDelegate = self
        ChatManager.setOnGoingChatUser(jid: getProfileDetails.jid)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        headerView.isHidden = true
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        IQKeyboardManager.shared.enableAutoToolbar = true
        NotificationCenter.default.removeObserver(self)
        audioPlayer?.stop()
        selectedAssets = []
        callDurationTimer = nil
        ContactManager.shared.profileDelegate = nil
        GroupManager.shared.groupDelegate = nil
        ChatManager.shared.adminBlockDelegate = nil
        ChatManager.shared.messageEventsDelegate = nil
        FlyMessenger.shared.messageEventsDelegate = nil
        chatManager.connectionDelegate = nil
        chatManager.typingStatusDelegate = nil
    }
    
    @IBAction func cancelButtonTapped(_ sender: UIButton) {
        isShowForwardView = false
        textToolBarView?.isHidden = false
        forwardBottomView?.isHidden = true
        forwardMessages?.removeAll()
        chatTableView.reloadData()
    }
    
    @IBAction func forwardButtonTapped(_ sender: UIButton) {
        //showConfirmationAlert
        alertController = UIAlertController.init(title: "Message" , message: "Do you want to forward selected message?", preferredStyle: .alert)
        let forwardAction = UIAlertAction(title: "Forward", style: .default) { [weak self] (action) in
            self?.navicateToSelectForwardList(forwardMessages: self?.forwardMessages ?? [], dismissClosure: self?.showForwardBottomView)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] (action) in
            self?.dismiss(animated: true,completion: nil)
        }
        forwardAction.setValue(Color.primaryAppColor!, forKey: "titleTextColor")
        cancelAction.setValue(Color.primaryAppColor!, forKey: "titleTextColor")
        alertController?.addAction(cancelAction)
        alertController?.addAction(forwardAction)
        //  let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        DispatchQueue.main.async { [weak self] in
            if let alert = self?.alertController {
                self?.present(alert, animated: true, completion : {
                })
            }
        }
    }
    
    func showForwardBottomView() {
        forwardBottomView?.isHidden = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(FlyConstants.contactSyncState), object: nil)
        ChatManager.setOnGoingChatUser(jid: "")
        toolTipController.isMenuVisible = false
    }
    
    //MARK: - Adding TapGesture for ReplyView
    @objc func replyViewTapGesture(_ sender: UITapGestureRecognizer? = nil) {
        
        guard let gesture = sender else {return }
        let indexPath = self.getIndexpathOfCellFromGesture(gesture)
        currentIndexPath = indexPath

        let message = chatMessages[indexPath.section][indexPath.row]
        if chatMessages[indexPath.section][indexPath.row].replyParentChatMessage != nil {
    
            chatMessages.enumerated().forEach { (section,chatMessage) in
                chatMessage.enumerated().forEach { (index,element) in
                    if chatMessage[index].messageId == chatMessages[indexPath.section][indexPath.row].replyParentChatMessage?.messageId {
                        let scrollToRow = IndexPath(row: index, section: section)
                        chatTableView.scrollToRow(at: scrollToRow, at: .none, animated: true)
                        if !previousIndexPath.isEmpty {
                            if let cell = self.chatTableView.cellForRow(at: previousIndexPath) {
                                cell.contentView.backgroundColor = .clear
                            }
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                        
                            if let cell = self?.chatTableView.cellForRow(at: scrollToRow) {
                                    cell.contentView.backgroundColor = Color.cellSelectionColor
                                    self?.previousIndexPath = scrollToRow
                                    self?.updateSelectionColor(indexPath: scrollToRow)
                                }
                            
                        }
                    }
                }
            }
        }
        if let cell = self.chatTableView.cellForRow(at: indexPath) {
            cell.contentView.backgroundColor = .clear
            isCellLongPressed = false
        }
        
        
    }
}

//MARK - Chat Grouping Logic
extension ChatViewParentController {
    private func addNewGroupedMessage(messages:  [ChatMessage]) {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            if messages.isEmpty {
            }else{ strongSelf.chatTableView?.restore() }
        }
        let groupedMessages = Dictionary(grouping: messages) { (element) -> Date in
            let messageDate = DateFormatterUtility.shared.convertMillisecondsToDateTime(milliSeconds: element.messageSentTime)
            return messageDate.reduceToMonthDayYear()
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        let sortedKeys = groupedMessages.keys.sorted()
        sortedKeys.forEach { (key) in
            let values = groupedMessages[key]
            chatMessages.append(values ?? [])
                chatTableView?.beginUpdates()
                chatTableView?.insertSections([0], with: .top)
                let lastSection = chatTableView?.numberOfSections
                chatTableView?.insertRows(at: [IndexPath.init(row: 0, section: 0)], with: .automatic)
                chatTableView?.endUpdates()
                let indexPath = IndexPath(row: 0, section: 0)
                chatTableView?.scrollToRow(at: indexPath, at: .top, animated: true)
                messageTextView?.text = ""
            }
        }
    
    
    //This method groups the  previous messages as per timestamp.
    private func groupPreviousMessages(messages: [ChatMessage]){
        let groupedMessages = Dictionary(grouping: messages) { (element) -> Date in
            let date : Date
            if element.messageChatType == .singleChat {
                 date = DateFormatterUtility.shared.convertMillisecondsToDateTime(milliSeconds: element.messageSentTime)
            } else {
                 date = DateFormatterUtility.shared.convertGroupMillisecondsToDateTime(milliSeconds: element.messageSentTime)
            }
            return date.reduceToMonthDayYear()
        }
        let sortedKeys = groupedMessages.keys.sorted()
        sortedKeys.forEach { (key) in
            var values = groupedMessages[key]
            values = values?.reversed()
            chatMessages.insert(values ?? [], at: 0)
            DispatchQueue.main.async { [weak self] in
                self?.chatTableView?.reloadData()
            }
        }
    }
    
    // This method append new message on UI when new message is received.
    private func appendNewMessage(message: ChatMessage) {
        if isMessageExist(messageId: message.messageId) {
            return
        }
        var lastSection = 0
        DispatchQueue.main.async{
            if  self.chatMessages.count == 0 {
                lastSection = ( self.chatTableView?.numberOfSections ?? 0)
            }else {
                lastSection = ( self.chatTableView?.numberOfSections ?? 0) - 1
            }
        }
        if chatMessages.count == 0 {
            addNewGroupedMessage(messages: [message])
        }else {
                chatMessages[0].insert(message, at: 0)
                print("appendNewMessage \(lastSection)")
                chatTableView?.insertRows(at: [IndexPath.init(row: 0, section: 0)], with: .right)
                let indexPath = IndexPath(row: 0, section: 0)
                chatTableView?.scrollToRow(at: indexPath, at: .top, animated: true)
        }
    }
}

// MARK - Base setup
extension ChatViewParentController {
    func setUpUI() {
        getProfileDetails = ChatManager.profileDetaisFor(jid: getProfileDetails.jid)
        setupTableviewLongPressGesture()
        setProfile()
        chatTableView.dataSource = self
        chatTableView.delegate = self
        chatTableView.transform = CGAffineTransform(rotationAngle: -.pi)
        chatTableView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: chatTableView.bounds.size.width - CGFloat(constraintsConstant))
        registerNibs()
        loadBottomView()
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(goToInfoScreen(sender:)))
        userImage.isUserInteractionEnabled = true
        userImage.addGestureRecognizer(gestureRecognizer)
        userInfoStack.isUserInteractionEnabled = true
        userInfoStack.addGestureRecognizer(gestureRecognizer)
    }
    
    @objc func goToInfoScreen(sender: Any){
        if getProfileDetails.profileChatType == .singleChat {
            performSegue(withIdentifier: Identifiers.contactInfoViewController, sender: nil)
        } else if getProfileDetails.profileChatType == .groupChat {
            performSegue(withIdentifier: Identifiers.groupInfoViewController, sender: nil)
        }
    }
    
    func setProfile() {
        if getProfileDetails != nil {
            userNameLabel.text = getUserName(jid : getProfileDetails.jid ,name: getProfileDetails.name, nickName: getProfileDetails.nickName, contactType: getProfileDetails.contactType)
            let imageUrl = getProfileDetails?.image  ?? ""
            let urlString = FlyDefaults.baseURL + "media/" + imageUrl + "?mf=" + FlyDefaults.authtoken
            print("setProfile \(urlString)")
            var url = URL(string: urlString)
            var placeholder = UIImage()
            if getProfileDetails.profileChatType == .groupChat {
                placeholder = UIImage(named: ImageConstant.ic_group_small_placeholder) ?? UIImage()
            }else if getProfileDetails.contactType == .deleted || getProfileDetails.isBlockedByAdmin{
                placeholder = UIImage(named: "ic_profile_placeholder") ?? UIImage()
                url = URL(string: "")
            }else {
                placeholder = getPlaceholder(name: getUserName(jid : getProfileDetails.jid ,name: getProfileDetails.name, nickName: getProfileDetails.nickName, contactType: getProfileDetails.contactType), color: contactColor)
            }
            userImage.sd_setImage(with: url, placeholderImage: placeholder)
        }
    }
    func setUpHeaderView() {
        navigationController?.isNavigationBarHidden = true
        multiSelectionView.isHidden = true
        headerView.isHidden = false
        longPressCountLabel.isHidden = true
        longPressCountLabel.text = String(longPressCount)
        setUpStatusBar()
        chatTableView.dataSource = self
        chatTableView.delegate = self
        chatTableView.transform = CGAffineTransform(rotationAngle: -.pi)
        registerNibs()
    }
    
    func loadAudioView() {
        audioViewXib = Bundle.main.loadNibNamed(Identifiers.audioView, owner: self, options: nil)?[0] as? AudioView
        audioViewXib?.frame =  UIScreen.main.bounds
        audioViewXib?.layoutIfNeeded()
        //view.addSubview(audioViewXib!)
        audioViewXib?.isHidden = true
        view.bringSubviewToFront(audioViewXib!)
        let window = UIApplication.shared.keyWindow
        audioViewXib?.frame = window?.bounds ?? CGRect()
        window?.addSubview(audioViewXib ?? UIView())
    }

    func getPlaceholder(name: String , color: UIColor)->UIImage {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let ipimage = IPImage(text: trimmedName, radius: Double(userImage.frame.size.height), font: UIFont.font32px_appBold(), textColor: nil, color: color)
        let placeholder = ipimage.generateInitialImage()
        return placeholder ?? #imageLiteral(resourceName: "ic_profile_placeholder")
    }
    
    func setupTableviewLongPressGesture() {
        let longPressGesture:UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector( handleCellLongPress))
        longPressGesture.delegate = self
        chatTableView.addGestureRecognizer(longPressGesture)
    }
    
    func onMultiSelectionHideAndShow() {
        if(longPressCount > 1) {
            copyButton.isHidden = true
            replyButton.isHidden = true
        }
        else {
            copyButton.isHidden = false
            replyButton.isHidden = false
        }
    }
    
    func showToolTipBar(cell: UITableViewCell) {
        if #available(iOS 13.0, *) {
            toolTipController.isMenuVisible = true
            toolTipController.showMenu(from: cell.contentView, rect: self.view.bounds)
        } else {
            toolTipController.setTargetRect(self.view.bounds, in: cell.contentView)
            toolTipController.setMenuVisible(true, animated: true)
        }
    }
    
    func navicateToSelectForwardList(forwardMessages: [SelectedForwardMessage],dismissClosure:(()->())?) {
        let destination = ForwardViewController(nibName: Identifiers.forwardVC, bundle: nil)
        destination.pageDismissClosure = dismissClosure
        destination.forwardMessages = forwardMessages
        destination.selectedUserDelegate = self
        destination.refreshProfileDelegate = self
        destination.fromJid = getProfileDetails.jid
        presentViewController(source: self, destination: destination)
    }
    
    fileprivate func presentViewController(source: UIViewController, destination: UIViewController) {
        destination.modalPresentationStyle = .fullScreen
        source.navigationController?.pushViewController(destination, animated: true)
    }
    
    @objc func handleCellLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if isShowForwardView == false {
            var replyItem: UIMenuItem!
            var forwardItem: UIMenuItem!
            var reportItem: UIMenuItem!
        if( longPressCount == 0 && chatMessages.count > 0) {
            if gestureRecognizer.state == .began {
                isCellLongPressed = true
                let touchPoint = gestureRecognizer.location(in:  chatTableView)
                if let indexPath =  chatTableView.indexPathForRow(at: touchPoint) {
                    previousIndexPath = indexPath
                    selectedChatMessage = chatMessages[indexPath.section ][indexPath.row]
                    let messageStatus =  chatMessages[indexPath.section ][indexPath.row].messageStatus
                    if  (messageStatus == .delivered || messageStatus == .received || messageStatus == .seen || messageStatus == .acknowledged) && !getBlockedByAdmin() {
                        chatTableView.allowsMultipleSelection = false
                        let replyImage = UIImage(named: "replyIcon")
                        replyItem = UIMenuItem(title: "Reply", image: replyImage) { [weak self] _ in
                            if let cell = self?.chatTableView.cellForRow(at: indexPath) {
                                cell.contentView.backgroundColor = .clear
                                self?.replyMessage(indexPath: indexPath)
                            }
                        }
                    }
                    
                    var flag : Bool = false
                    
                    if (messageStatus == .delivered || messageStatus == .sent || messageStatus == .received || messageStatus == .seen || messageStatus == .acknowledged)  {
                        if ((chatMessages[indexPath.section ][indexPath.row].mediaChatMessage != nil) && chatMessages[indexPath.section ][indexPath.row].mediaChatMessage?.mediaUploadStatus == .uploaded || chatMessages[indexPath.section ][indexPath.row].mediaChatMessage?.mediaDownloadStatus == .downloaded) {
                            flag = true
                        }
                    }
                    if (messageStatus == .delivered || messageStatus == .received || messageStatus == .seen || messageStatus == .acknowledged)  {
                        if chatMessages[indexPath.section ][indexPath.row].mediaChatMessage == nil {
                            flag = true
                        }
                    }
                    
                    if flag {
                        forwardItem = UIMenuItem(title: "Forward") { [weak self] _ in
                            self?.isShowForwardView = true
                            self?.currentIndexPath = indexPath
                            self?.refreshBubbleImageView(indexPath: indexPath, isSelected: true)
                            self?.chatTableView.reloadData()
                        }
                        
                        if let tmepMessage = selectedChatMessage, !tmepMessage.isMessageSentByMe && !getBlockedByAdmin(){
                            reportItem = UIMenuItem(title: report) { [weak self] _ in
                                
                                if self?.getProfileDetails.contactType == .deleted {
                                    AppAlert.shared.showToast(message: unableToReportDeletedUserMessage)
                                    return
                                }
                                
                                self?.reportFromMessage(chatMessage: tmepMessage)
                            }
                        }
                    }
                    
                    
                    if getProfileDetails.profileChatType == .groupChat {
                        if !isParticipantExist().doesExist {
                            replyItem = nil
                            forwardItem = nil
                        }
                    }
                    
                    switch true {
                    case replyItem == nil && forwardItem == nil && reportItem == nil:
                        toolTipController.menuItems = []
                    case replyItem != nil && forwardItem != nil && reportItem != nil:
                        toolTipController.menuItems = [replyItem,forwardItem, reportItem]
                    case replyItem != nil && forwardItem != nil:
                        toolTipController.menuItems = [replyItem,forwardItem]
                    case replyItem != nil:
                        toolTipController.menuItems = [replyItem]
                    case forwardItem != nil:
                        toolTipController.menuItems = [forwardItem]
                    case reportItem != nil:
                        toolTipController.menuItems = [reportItem]
                    default:
                        toolTipController.menuItems = [replyItem,forwardItem]
                    }
    
                        let chatMessage = chatMessages[indexPath.section][indexPath.row]
                        switch chatMessage.messageType {
                        case .audio:
                            switch chatMessage.isMessageSentByMe {
                            case true:
                                if let cell = chatTableView.cellForRow(at: indexPath) as? AudioSender {
                                    showToolTipBar(cell: cell)
                                }
                            case false:
                                if let cell = chatTableView.cellForRow(at: indexPath) as? AudioReceiver {
                                    showToolTipBar(cell: cell)
                                }
                            }
                        case .video:
                            switch chatMessage.isMessageSentByMe {
                            case true:
                                if let cell = chatTableView.cellForRow(at: indexPath) as? ChatViewVideoOutgoingCell {
                                    showToolTipBar(cell: cell)
                                }
                            case false:
                                if let cell = chatTableView.cellForRow(at: indexPath) as? ChatViewVideoIncomingCell {
                                    showToolTipBar(cell: cell)
                                }
                            }
                        case .image:
                            switch chatMessage.isMessageSentByMe {
                            case true:
                                if let cell = chatTableView.cellForRow(at: indexPath) as? SenderImageCell {
                                    showToolTipBar(cell: cell)
                                }
                            case false:
                                if let cell = chatTableView.cellForRow(at: indexPath) as? ReceiverImageCell {
                                    showToolTipBar(cell: cell)
                                }
                            }
                        default:
                            if let cell = chatTableView.cellForRow(at: indexPath) as? ChatViewParentMessageCell {
                                showToolTipBar(cell: cell)
                            }
                        }
                }
            }
        }
    }
}
    
    func registerNibs() {
        chatTableView.register(UINib(nibName: Identifiers.chatViewTextOutgoingCell , bundle: .main), forCellReuseIdentifier: Identifiers.chatViewTextOutgoingCell)
        chatTableView.register(UINib(nibName: Identifiers.chatViewTextIncomingCell , bundle: .main), forCellReuseIdentifier: Identifiers.chatViewTextIncomingCell)
        chatTableView.register(UINib(nibName: Identifiers.chatViewLocationIncomingCell , bundle: .main), forCellReuseIdentifier: Identifiers.chatViewLocationIncomingCell)
        chatTableView.register(UINib(nibName: Identifiers.chatViewLocationOutgoingCell , bundle: .main), forCellReuseIdentifier: Identifiers.chatViewLocationOutgoingCell)
        chatTableView.register(UINib(nibName: Identifiers.chatViewContactIncomingCell , bundle: .main), forCellReuseIdentifier: Identifiers.chatViewContactIncomingCell)
        chatTableView.register(UINib(nibName: Identifiers.chatViewContactOutgoingCell , bundle: .main), forCellReuseIdentifier: Identifiers.chatViewContactOutgoingCell)
        chatTableView.register(UINib(nibName: Identifiers.audioSender , bundle: .main), forCellReuseIdentifier: Identifiers.audioSender)
        chatTableView.register(UINib(nibName: Identifiers.audioReceiver , bundle: .main), forCellReuseIdentifier: Identifiers.audioReceiver)
        chatTableView.register(UINib(nibName: Identifiers.imageSender , bundle: .main), forCellReuseIdentifier: Identifiers.imageSender)
        chatTableView.register(UINib(nibName: Identifiers.imageReceiverCell , bundle: .main), forCellReuseIdentifier: Identifiers.imageReceiverCell)
        chatTableView.register(UINib(nibName: Identifiers.videoIncomingCell , bundle: .main), forCellReuseIdentifier: Identifiers.videoIncomingCell)
        chatTableView.register(UINib(nibName: Identifiers.videoOutgoingCell , bundle: .main), forCellReuseIdentifier: Identifiers.videoOutgoingCell)
        chatTableView.register(UINib(nibName: Identifiers.notificationCell , bundle: .main), forCellReuseIdentifier: Identifiers.notificationCell)
    }
    
    func loadBottomView() {
        chatTextViewXib = Bundle.main.loadNibNamed(Identifiers.chatTextView, owner: self, options: nil)?[0] as? ChatTextView
        chatTextViewXib?.frame =  containerView.bounds
        chatTextViewXib?.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        chatTextView?.layer.borderWidth = CGFloat(borderWidth)
        chatTextView?.layer.borderColor = Color.borderColor?.cgColor
        chatTextView?.layer.cornerRadius = CGFloat(cornerRadius)
        messageTextView?.delegate = self
        messageTextView?.text = (messageText?.isNotEmpty == true && replyJid == getProfileDetails.jid) ? messageText : startTyping.localized
        messageTextView?.textColor = UIColor.lightGray
        growingTextViewHandler = GrowingTextViewHandler(textView: messageTextView ?? UITextView(), heightConstraint: messageTextViewHeight ?? NSLayoutConstraint())
        growingTextViewHandler?.minimumNumberOfLines = chatTextMinimumLines
        growingTextViewHandler?.maximumNumberOfLines = chatTextMaximumLines
        containerView.addSubview(chatTextViewXib!)
//        chatTextViewXib?.translatesAutoresizingMaskIntoConstraints = true
//        let guide = self.view.safeAreaLayoutGuide
//        chatTextViewXib?.bottomAnchor.constraint(equalTo: guide.bottomAnchor).isActive = true
//        chatTextViewXib?.leadingAnchor.constraint(equalTo: guide.leadingAnchor).isActive = true
//        chatTextViewXib?.trailingAnchor.constraint(equalTo: guide.trailingAnchor).isActive = true
//        chatTextViewXib?.layoutIfNeeded()
    }
    
    func getLastSeen() {
        if getProfileDetails.contactType == .deleted || getProfileDetails.isBlockedByAdmin {
            lastSeenLabel.text = emptyString()
            lastSeenLabel.isHidden = true
            return
        }
        ChatManager.getUserLastSeen(for: getProfileDetails.jid) { [self] isSuccess, flyError, flyData in
            var data  = flyData
            if isSuccess {
                
                guard let lastSeenTime = data.getData() as? String else{
                    return
                }
                lastSeenLabel.isHidden = false
                if (Int(lastSeenTime) == 0) {
                   lastSeenLabel.text = online.localized
                }
                else {
                    self.setLastSeen(lastSeenTime: lastSeenTime)
                }
            } else{
                print(data.getMessage() as! String )
            }
        }
    }
    
    func setLastSeen(lastSeenTime : String){
        if getProfileDetails.contactType == .deleted || getProfileDetails.isBlockedByAdmin {
            lastSeenLabel.text = emptyString()
            lastSeenLabel.isHidden = true
            return
        }
        let dateFormat = DateFormatter()
        dateFormat.timeStyle = .short
        dateFormat.dateStyle = .short
        dateFormat.doesRelativeDateFormatting = true
        let dateString = dateFormat.string(from: Date(timeIntervalSinceNow: TimeInterval(-(Int(lastSeenTime) ?? 0))))
        
        let timeDifference = "\(NSLocalizedString(lastSeen.localized, comment: "")) \(dateString)"
        let lastSeen = timeDifference.lowercased()
        
        lastSeenLabel.text = lastSeen
    }
    
    @objc func profileNotification(notification: Notification) {
        if  let jid = notification.userInfo?["jid"] {
            if jid as? String == getProfileDetails.jid {
                if  let image =  notification.userInfo?["image"] as? String  {
                    getProfileDetails.image = image
                }
                if  let name =  notification.userInfo?["name"] as? String  {
                    getProfileDetails.name = name
                }
                if  let status =  notification.userInfo?["status"] as? String  {
                    getProfileDetails.status = status
                }
                setProfile()
            }
        }
    }
}

// MARK - Text Delegate
extension ChatViewParentController {
    
    func textViewDidChange(_ textView: UITextView) {
        self.growingTextViewHandler?.resizeTextView(true)
        handleSendButton()
        self.resizeMessageTextView()
        if let isNotEmpty =  messageTextView?.text.isNotEmpty,  isNotEmpty {
            ChatManager.sendTypingStatus(to: getProfileDetails.jid, chatType: getProfileDetails.profileChatType)
        }
    }
    
    func resizeMessageTextView() {
        if isReplyViewOpen == true {
            textToolBarViewHeight?.constant = messageTextViewHeight!.constant + 5
            chatTextView?.frame.size.height = messageTextViewHeight!.constant
            tableViewBottomConstraint?.constant = textToolBarViewHeight!.constant + 5 + 80
        } else {
            textToolBarViewHeight?.constant = messageTextViewHeight!.constant + 5
            chatTextView?.frame.size.height = messageTextViewHeight!.constant
            tableViewBottomConstraint?.constant = textToolBarViewHeight!.constant + 5
        }
    }
    
    func resetMessageTextView() {
        messageTextViewHeight?.constant = 40
        textToolBarViewHeight?.constant = messageTextViewHeight!.constant
        chatTextView?.frame.size.height = messageTextViewHeight!.constant
    }
    
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        toolTipController.menuItems = []
        if  messageTextView?.textColor == UIColor.lightGray {
            messageTextView?.textColor = UIColor.black
            chatTextView?.translatesAutoresizingMaskIntoConstraints = true
            chatTextView?.sizeToFit()
        }
        if let isNotEmpty =  messageTextView?.text.isNotEmpty,  isNotEmpty{
            ChatManager.sendTypingStatus(to: getProfileDetails.jid, chatType: getProfileDetails.profileChatType)
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        print("textViewDidEndEditing")
        toolTipController.menuItems = []
        ChatManager.sendTypingGoneStatus(to: getProfileDetails.jid, chatType: getProfileDetails.profileChatType)
        if isReplyViewOpen == false {
           // textToolBarViewHeight?.constant = CGFloat(chatBottomConstant)
           // tableViewBottomConstraint?.constant = CGFloat(chatBottomConstant)
            tableViewBottomConstraint?.constant = textToolBarViewHeight!.constant + 5
            guard let indexPath = chatTableView.indexPath(for: chatTableView), chatMessages[indexPath.section][indexPath.row].replyParentChatMessage != nil else { return }
            chatTableView.delegate?.tableView?(chatTableView, didSelectRowAt: indexPath)
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        print("shouldChangeTextIn \(range) text \(text) textCount \(text.count)" )
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.getHintsFromTextField), object: textView)
        self.perform(#selector(self.getHintsFromTextField), with: textView, afterDelay: 0.5)
        
        if range.length >= 1024 && text.isEmpty {
            return false
        }
        
        let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
        let numberOfChars = newText.count
        return numberOfChars <= 1024
    }
    
    @objc func getHintsFromTextField(textField: UITextView) {
        print("Hints for textField: \(textField.text ?? "")")
        ChatManager.sendTypingGoneStatus(to: getProfileDetails.jid, chatType: getProfileDetails.profileChatType)
    }
}

// MARK: - Audio functions
extension ChatViewParentController {
    
    func recordAudio() {
        stopPlayer(isBecomeBackGround: false)
        if let recorder = audioRecorder {
            if !recorder.isRecording {
                let audioSession = AVAudioSession.sharedInstance()
                
                do {
                    try audioSession.setActive(true)
                } catch _ {
                }
                
                // Start recording
                recorder.record()
                audioImage.image = UIImage(named: ImageConstant.ic_audio_recording)
                startTimer()
            } else {
                recorder.stop()
            }
        }
    }
    
    func startTimer()
    {
        audioTimer = Timer.scheduledTimer(timeInterval: 0.1, target:self, selector:#selector( updateAudioMeter(timer:)), userInfo:nil, repeats:true)
    }
    
    func stopTimer () {
        audioTimer.invalidate()
    }
    
    @objc func updateAudioMeter(timer: Timer)
    {
        if let recorder = audioRecorder
        {
            let min = Int(recorder.currentTime / 60)
            let sec = Int(recorder.currentTime.truncatingRemainder(dividingBy: 60))
            let totalTimeString = String(format: "%02d:%02d", min, sec)
            audioTimerLabel.text = totalTimeString
            print(totalTimeString)
            recorder.updateMeters()
        }
    }
    
    func checkMicrophoneAccess(isOpenAudioFile: Bool) {
        // Check Microphone Authorization
        switch AVAudioSession.sharedInstance().recordPermission {
            
        case AVAudioSession.RecordPermission.granted:
            print(#function, " Microphone Permission Granted")
            isAudioRecordingGranted = isOpenAudioFile == true ? false : true
            startRecord(isOpenAudioFile: isOpenAudioFile)
            break
        case AVAudioSession.RecordPermission.denied:
            // Dismiss Keyboard (on UIView level, without reference to a specific text field)
            isAudioRecordingGranted = false
            
            return
            
        case AVAudioSession.RecordPermission.undetermined:
            print("Request permission here")
            DispatchQueue.main.async { [weak self] in
                
                // Dismiss Keyboard (on UIView level, without reference to a specific text field)
                UIApplication.shared.sendAction(#selector(UIView.endEditing(_:)), to:nil, from:nil, for:nil)
                
                AVAudioSession.sharedInstance().requestRecordPermission({ (granted) in
                    // Handle granted
                    if granted {
                        self?.startRecord(isOpenAudioFile: isOpenAudioFile)
                        print(#function, " Now Granted")
                    } else {
                        print("Pemission Not Granted")
                        
                    } // end else
                })
            }
            @unknown default:
                print("ERROR! Unknown Default. Check!")
            } // end switch
    }
    
    func audioSetup() {
        // Set the audio file
        let directoryURL = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in:
                                                        FileManager.SearchPathDomainMask.userDomainMask).first
        
        let audioFileName = UUID().uuidString + ".m4a"
        let audioFileURL = directoryURL!.appendingPathComponent(audioFileName)
        // Setup audio session
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch _ {
        }
        
        // Define the recorder setting
        let recorderSetting = [AVFormatIDKey: NSNumber(value: kAudioFormatMPEG4AAC as UInt32),
                               AVSampleRateKey: 44100.0,
                               AVNumberOfChannelsKey: 2 ]
        
        audioRecorder = try? AVAudioRecorder(url: audioFileURL, settings: recorderSetting)
        audioRecorder?.delegate = self
        audioRecorder?.isMeteringEnabled = true
        audioRecorder?.prepareToRecord()
        DispatchQueue.main.async { [weak self] in
            if let weakSelf = self {
                weakSelf.navigationController?.navigationBar.setValue(true, forKey: "hidesShadow")
            }
        }
    }
    
    func stopRecording() {
        if let recorder = audioRecorder {
            if recorder.isRecording {
                audioRecorder?.stop()
                stopTimer()
                let audioSession = AVAudioSession.sharedInstance()
                do {
                    try audioSession.setActive(false)
                } catch _ {
                }
            }
        }
        
        // Stop the audio player if playing
        stopPlayer(isBecomeBackGround: false)
    }
    
    func stopPlayer(isBecomeBackGround: Bool) {
        stopDisplayLink()
        if let player = audioPlayer {
            if let path = currenAudioIndexPath {
                if let cell = chatTableView.cellForRow(at: path) as? AudioSender {
                    cell.playIcon?.image = UIImage(named: ImageConstant.ic_play)
                    if previousAudioIndexPath == currenAudioIndexPath {
                        chatMessages[currenAudioIndexPath?.section ?? 0][currenAudioIndexPath?.row ?? 0].audioTrackTime = Float(audioPlayer?.currentTime ?? 0.0)
                    } else {
                        chatMessages[currenAudioIndexPath?.section ?? 0][currenAudioIndexPath?.row ?? 0].audioTrackTime = 0.0
                    }
                }
                else if let cell = chatTableView.cellForRow(at: path) as? AudioReceiver {
                    cell.playImage?.image = UIImage(named: ImageConstant.ic_play_dark)
                    if previousAudioIndexPath == currenAudioIndexPath {
                        chatMessages[currenAudioIndexPath?.section ?? 0][currenAudioIndexPath?.row ?? 0].audioTrackTime = Float(audioPlayer?.currentTime ?? 0.0)
                    } else {
                        chatMessages[currenAudioIndexPath?.section ?? 0][currenAudioIndexPath?.row ?? 0].audioTrackTime = 0.0
                    }
                }
            
                if player.isPlaying {
                    player.stop()
                }
               
            }
        }
    }
    
    func stopDisplayLink() {
        updater?.invalidate()
        updater = nil
     }
    
    func audioPermission() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch _ {
        }
    }
    
    func playAudio(audioUrl: String) {
        audioPermission()
        stopPlayer(isBecomeBackGround: false)
        let directoryURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folderPath: URL = directoryURL.appendingPathComponent("FlyMedia/Audio", isDirectory: true)
        let fileURL: URL = folderPath.appendingPathComponent(audioUrl)
        if FileManager.default.fileExists(atPath: fileURL.relativePath) {
            do {
                let data = try Data(contentsOf: fileURL)
                audioPlayer = try? AVAudioPlayer(data: data as Data)
            } catch {
                fatalError()
            }
            audioPlayer?.delegate = self
            updater = CADisplayLink(target: self, selector: #selector( trackAudio))
            updater.frameInterval = 1
            updater.add(to: RunLoop.current, forMode: RunLoop.Mode.common)
            print("currentIndexPath:",currenAudioIndexPath)
            print("previousAudioIndexPath:",previousAudioIndexPath)
            if previousAudioIndexPath != currenAudioIndexPath {
                if chatMessages.count > 0 && previousAudioIndexPath?.section != -1 {
                    if chatMessages[previousAudioIndexPath?.section ?? 0].count > previousAudioIndexPath?.row ?? 0 {
                        chatMessages[previousAudioIndexPath?.section ?? 0][previousAudioIndexPath?.row ?? 0].audioTrackTime = 0.0
                        chatTableView.reloadRows(at: [previousAudioIndexPath ?? IndexPath(row: 0, section: 0)], with: .none)
                    }
                }
            }
            audioPlayer?.currentTime = TimeInterval(chatMessages[currenAudioIndexPath?.section ?? 0][currenAudioIndexPath?.row ?? 0].audioTrackTime ?? 0.0)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            previousAudioIndexPath = currenAudioIndexPath ?? IndexPath()
            if let path = currenAudioIndexPath {
                if let cell = chatTableView.cellForRow(at: path) as? AudioSender {
                    cell.playIcon?.image = UIImage(named: ImageConstant.ic_audio_pause)
                    cell.audioPlaySlider?.maximumValue = Float(audioPlayer?.duration ?? 0.0)
                } else if let cell = chatTableView.cellForRow(at: path) as? AudioReceiver {
                    cell.playImage?.image = UIImage(named: ImageConstant.ic_audio_pause_gray)
                    cell.slider?.maximumValue = Float(audioPlayer?.duration ?? 0.0)
                }
            }
        }
    }
    
    func startRecord(isOpenAudioFile: Bool) {
        if isOpenAudioFile == false {
                audioSetup()
            if let recorder = audioRecorder {
                if !recorder.isRecording {
                    recordAudio()
                }else{
                    stopRecording()
                }
            }
        } else {
            audioPermission()
            openAudioFiles()
        }
    }
    
    func openAudioFiles() {
        DispatchQueue.main.async { [weak self] in
            if let weakSelf = self {
                let pickerViewController = UIDocumentPickerViewController(documentTypes: [(kUTTypeAudio as String)], in: .import)
                pickerViewController.delegate = self
                pickerViewController.allowsMultipleSelection = false
                weakSelf.present(
                    pickerViewController,
                    animated: true,
                    completion: nil
                )
            }
        }
    }
    
    @objc func trackAudio() {
        if let curnTime = audioPlayer?.currentTime {
            if let duration = audioPlayer?.duration {
                let normalizedTime = Float(curnTime * 100.0 / duration)
                print(normalizedTime)
                print(curnTime)
                print(duration)
                let min = Int(curnTime / 60)
                let sec = Int(curnTime.truncatingRemainder(dividingBy: 60))
                let totalTimeString = String(format: "%02d:%02d", min, sec)
                print(totalTimeString)
                if let path = currenAudioIndexPath {
                if let cell = chatTableView.cellForRow(at: path) as? AudioSender {
                    cell.audioPlaySlider?.value = Float(audioPlayer?.currentTime ?? 0.0)
                    chatMessages[currenAudioIndexPath?.section ?? 0][currenAudioIndexPath?.row ?? 0].audioTrackTime = Float(audioPlayer?.currentTime ?? 0.0)
                    cell.autioDuration?.text = totalTimeString
                } else if let cell = chatTableView.cellForRow(at: path) as? AudioReceiver {
                    cell.slider?.value = Float(audioPlayer?.currentTime ?? 0.0)
                    chatMessages[currenAudioIndexPath?.section ?? 0][currenAudioIndexPath?.row ?? 0].audioTrackTime = Float(audioPlayer?.currentTime ?? 0.0)
                    cell.audioDuration?.text = totalTimeString
                }
                }
            }
        }
    }

    func disableSendButton()  {
        sendButton?.isEnabled = false
    }
    
    func enableSendButton()  {
        sendButton?.isEnabled = true
    }
    
    func handleSendButton() {
        if ((messageTextView?.text.isBlank ?? false) || messageTextView?.text == startTyping.localized) {
            disableSendButton()
        } else {
            enableSendButton()
        }
    }
    
}

// MARK - Text Delegate
extension ChatViewParentController {
    @IBAction func cancelButton(_ sender: Any) {
        audioImage.image = UIImage(named: ImageConstant.ic_audio_record)
        stopRecording()
        audioViewXib?.isHidden = true
    }
    
    @IBAction func audioSendButton(_ sender: Any) {
        audioViewXib?.isHidden = true
        if let recorder = audioRecorder {
            if recorder.isRecording {
                stopRecording()
                sendAudio(audioUrl: recorder.url)
            }
        }
    }
    
    func sendAudio(fileUrl: URL) {
        let duration = FlyUtils.getMediaDuration(url: fileUrl) ?? 0
        if fileUrl.pathExtension == "mp3" || fileUrl.pathExtension == "aac" || fileUrl.pathExtension == "wav" {
            FlyMessenger.sendAudioMessage(toJid:  getProfileDetails.jid, audioFile: fileUrl, audioDuration: duration,replyMessageId: replyMessageId) { [weak self] isSuccess,error,message in
                if let chatMessage = message {
                    chatMessage.mediaChatMessage?.mediaUploadStatus = .not_uploaded
                    self?.reloadList(message: chatMessage)
                    self?.replyMessageId = ""
                    self?.tableViewBottomConstraint?.constant = CGFloat(chatBottomConstant)
                    if self?.replyJid == self?.getProfileDetails.jid {
                        self?.replyMessageObj = nil
                        self?.isReplyViewOpen = false
                    }
                }
            }
        } else {
            AppAlert.shared.showToast(message: unsupportedFile)
        }
    }
    
    func sendAudio(audioUrl: URL) {
        let fileUrl = audioUrl.absoluteString
        let audioUrl = URL(fileURLWithPath: fileUrl)
        guard let audioData = try? Data(contentsOf: audioUrl) else{
            return
        }
        let audioName  = FlyConstants.audio + FlyUtils.generateUniqueId() + MessageExtension.audio.rawValue
        if let audioLocalPath  = FlyUtils.saveInDirectory(with: audioData, fileName: audioName, messageType: .audio)?.0  {
            let duration = FlyUtils.getMediaDuration(url: audioUrl) ?? 0
            if audioUrl.pathExtension == "mp3" || audioUrl.pathExtension == "aac" || audioUrl.pathExtension == "wav" {
                FlyMessenger.sendAudioMessage(toJid: getProfileDetails.jid, audioFileSize: Double(audioData.count), audioFileUrl: fileUrl, audioFileLocalPath: audioLocalPath, audioFileName: audioName, audioDuration: duration, replyMessageId: replyMessageId){ isSuccess,error,message in
                        if let chatMessage = message {
                            chatMessage.mediaChatMessage?.mediaUploadStatus = .not_uploaded
                            DispatchQueue.main.async {  [weak self] in
                                self?.reloadList(message: chatMessage)
                                self?.replyMessageId = ""
                                self?.tableViewBottomConstraint?.constant = CGFloat(chatBottomConstant)
                            }
                        }
                    }
            } else {
                AppAlert.shared.showToast(message: unsupportedFile)
            }
        }
    }
    
    func startAudioRecord() {
        audioViewXib?.isHidden = false
        if isAudioRecordingGranted
        {
            startRecord(isOpenAudioFile: false)
        }else {
            checkMicrophoneAccess(isOpenAudioFile: false)
        }
    }
}

// MARK: - Audio Delegates

extension ChatViewParentController:  UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        
        if getUserForAdminBlock() {
            return
        }
        
        guard let audioData = try? Data(contentsOf: url) else {
            return
        }
        let byteCountFormatter = ByteCountFormatter()
        let displaySize = byteCountFormatter.string(fromByteCount: Int64(audioData.count))
        byteCountFormatter.countStyle = .file
        byteCountFormatter.allowedUnits = [.useMB]
        print("File Size: \(displaySize)")
        let convertBytesIntoMB = Float(displaySize.components(separatedBy: " ").first ?? "") ?? 0.0
        var audioFileInMbFormat : Float = convertBytesIntoMB
        
        // restrict MB format to convert again
        if displaySize.components(separatedBy: " ")[1] != "MB" {
            audioFileInMbFormat = (convertBytesIntoMB / 1024 / 1024)
        }
        
        // allow file only below 30MB
        if audioFileInMbFormat <= Float(30) {
            if currenAudioIndexPath == nil {
                currenAudioIndexPath = previousAudioIndexPath != nil ? previousAudioIndexPath : nil
            }
            if audioPlayer?.isPlaying == true {
                if currenAudioIndexPath != nil {
                    if currenAudioIndexPath == IndexPath(row: 0, section: 0) {
                        previousAudioIndexPath = IndexPath(row: 1, section: 0)
                    }
                }
            }
            if currenAudioIndexPath != nil {
                let nextRow = (currenAudioIndexPath?.row ?? 0) + 1
                let indexPath = IndexPath(row: nextRow, section: currenAudioIndexPath?.section ?? 0)
                currenAudioIndexPath = indexPath
            }
          
            isShowAudioLoadingIcon = true
            sendAudio(fileUrl: url)
        } else {
            AppAlert.shared.showToast(message: ErrorMessage.fileSizeLarge)
        }
    }
    
    func markMessagessAsRead() {
        ChatManager.markConversationAsRead(for: [getProfileDetails.jid])
    }
}

extension ChatViewParentController:  AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool)
    {
        
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool)
    {
        stopPlayer(isBecomeBackGround: false)
        if let path = currenAudioIndexPath {
        if let cell = chatTableView.cellForRow(at: path) as? AudioSender {
            cell.playIcon?.image = UIImage(named: ImageConstant.ic_play)
            cell.audioPlaySlider?.value = 0
        }
       else if let cell = chatTableView.cellForRow(at: path) as? AudioReceiver {
        cell.slider?.value = 0
        cell.playImage?.image = UIImage(named: ImageConstant.ic_play_dark)
        }
        }
    }
}

//MARK: - Actions
extension ChatViewParentController {
    @IBAction func onBackButton(_ sender: Any) {
        navigate()
    }
    
    private func navigate() {
        /// Need to check
        if isFromGroupInfo == true {
            navigationController?.popToRootViewController(animated: true)
        } else {
            if let navController = navigationController {
                if chatMessages.count > 0 && currentPreviewIndexPath != nil {
                    if chatMessages[currentPreviewIndexPath?.section ?? 0].count > 0 {
                        if replyCloseButtonTapped == false && replyMessageObj != nil {
                            if replyJid == getProfileDetails.jid  {
                                replyMessagesDelegate?.replyMessageObj(message: chatMessages[currentPreviewIndexPath?.section ?? 0][currentPreviewIndexPath?.row ?? 0], jid: getProfileDetails.jid,messageText: messageTextView?.text ?? "")
                            }
                        } else {
                            replyMessagesDelegate?.replyMessageObj(message: nil, jid: "",messageText: messageTextView?.text ?? "")
                        }
                    }
                }
                if isPopToRootVC == true && navController.viewControllers[0]  is MainTabBarController {
                    navController.popToRootViewController(animated: true)
                } else {
                    navController.popViewController(animated: true)
                }
            }
        }
    }
    
    func checkFromGroup() {
        if isFromGroupInfo == true {
            navigationController?.navigationBar.isHidden = true
            navigationController?.popViewController(animated: true)
        } else {
            navigationController?.navigationBar.isHidden = false
            navigationController?.popViewController(animated: true)
        }
    }
    
    func showOptions() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(title: camera, style: .default, handler: { [weak self] _ in
            self?.checkCameraPermissionAccess(sourceType: .camera)
        })
        cameraAction.setValue(Color.primaryAppColor!, forKey: "titleTextColor")
        alert.addAction(cameraAction)
        let photAction = UIAlertAction(title: gallery, style: .default, handler: { [weak self] _ in
            self?.checkForPhotoPermission()
        })
        photAction.setValue(Color.primaryAppColor!, forKey: "titleTextColor")
        alert.addAction(photAction)
        let audioAction = UIAlertAction(title: audio, style: .default, handler: {  [weak self] _ in
            self?.checkMicrophoneAccess(isOpenAudioFile: true)
        })
        audioAction.setValue(Color.primaryAppColor!, forKey: "titleTextColor")
        alert.addAction(audioAction)
        let contactAction = UIAlertAction(title: contact, style: .default, handler: { [weak self] _ in
            self?.onContact()
        })
        
        contactAction.setValue(Color.primaryAppColor!, forKey: "titleTextColor")
        alert.addAction(contactAction)
        
        let locationAction = UIAlertAction(title: location, style: .default, handler: { [weak self] _ in
            self?.goToMap()
        })
        
        locationAction.setValue(Color.primaryAppColor!, forKey: "titleTextColor")
        alert.addAction(locationAction)
        
        let cancelAction = UIAlertAction(title: cancel, style: .cancel, handler: { (_) in
            
        })
        cancelAction.setValue(Color.primaryAppColor!, forKey: "titleTextColor")
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    
    func goToMap() {
        if NetworkReachability.shared.isConnected {
            performSegue(withIdentifier: Identifiers.chatScreenToLocation, sender: nil)
        }
        else {
            AppAlert.shared.showToast(message: ErrorMessage.noInternet)
        }
    }
    
    func starMessages(isStar: Bool) {
        let rows = selectedIndexs
        for index in rows {
            let message = messages[index.row]
            ChatManager.updateFavouriteStatus(messageId: message.messageId, chatUserId: message.chatUserJid, isFavourite: isStar) { (isSuccess, flyError, resDict) in
                message.isMessageStarred = isStar
                DispatchQueue.main.async {  [weak self] in
                    self?.messages[index.row] = message
                    self?.chatTableView.reloadRows(at: [index], with: .automatic)
                }
            }
        }
        isSelectOn = false
        selectedIndexs.removeAll()
    }
    
    func checkPhotosPermissionForCamera() {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized:
            //handle authorized status
            openCamera()
            break
        case .denied, .restricted :
            presentPhotosSettings()
            break
        case .notDetermined:
            // ask for permissions
            AppPermissions.shared.checkGalleryPermission {  [weak self] status in
                switch status {
                case .authorized:
                    self?.openCamera()
                    break
                    // as above
                case .denied, .restricted:
                    self?.presentPhotosSettings()
                    break
                    // as above
                case .notDetermined: break
                    // won't happen but still
                    
                    
                case .limited: break
                    
                @unknown default: break
                    
                }
            }

            
        case .limited: break
            
        @unknown default: break
            
        }
    }
    
    func openCamera() {
        DispatchQueue.main.async { [self] in
            self.imagePicker =  UIImagePickerController()
            self.imagePicker.delegate = self
            self.imagePicker.sourceType = .camera
            self.imagePicker.videoMaximumDuration = TimeInterval(300)
            self.imagePicker.mediaTypes = ["public.image", "public.movie"]
            present(self.imagePicker, animated: true, completion: nil)
        }
    }
    
    /**
     *  This function used to check camera Permission
     */
    func checkCameraPermissionAccess(sourceType: UIImagePickerController.SourceType) {
        let authorizationStatus =  AVCaptureDevice.authorizationStatus(for: .video)
        switch authorizationStatus {
        case .denied:
            presentCameraSettings()
            break
        case .restricted:
            break
        case .authorized:
          checkPhotosPermissionForCamera()
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    print("Granted access to ")
                    self?.checkPhotosPermissionForCamera()
                } else {
                    print("Denied access to")
                    self?.presentCameraSettings()
                }
            }
            break
        @unknown default:
            print("Permission failed")
        }
    }
    
    func presentCameraSettings() {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "",
                message: cameraAccessDenied.localized,
                preferredStyle: UIAlertController.Style.alert
            )
            
            alert.addAction(UIAlertAction(title: cancel.localized, style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: settings.localized, style: .default, handler: { (alert) -> Void in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url, options: [:], completionHandler: { _ in
                    })
                    
                }
            }))
            
            self.present(alert, animated: false, completion: nil)
        }
    }
    
    func checkForPhotoPermission(sender: UIButton? = nil) {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized:
                openGallery()
            break
        case .denied, .restricted :
            presentPhotosSettings()
            break
        case .notDetermined:
            // ask for permissions
            AppPermissions.shared.checkGalleryPermission {  [weak self] status in
                switch status {
                case .authorized:
                        self?.openGallery()
                    break
                    // as above
                case .denied, .restricted: break
                    // as above
                case .notDetermined: break
                    // won't happen but still
                    
                    
                case .limited: break
                    
                @unknown default: break
                    
                }
            }

            
        case .limited: break
            
        @unknown default: break
            
        }
    }
    func presentPhotosSettings() {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "",
                message: libraryAccessDenied.localized,
                preferredStyle: UIAlertController.Style.alert
            )
            
            alert.addAction(UIAlertAction(title: cancel.localized, style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: settings.localized, style: .default, handler: { (alert) -> Void in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url, options: [:], completionHandler: { _ in
                    })
                }
            }))
            
            self.present(alert, animated: false, completion: nil)
        }
    }
    
    func getImageSize(asset : PHAsset) -> Float {
        var imageSize : Float = 0.0
            let manager = PHImageManager.default()
            let options = PHImageRequestOptions()
            options.version = .original
            options.isSynchronous = true
            manager.requestImageData(for: asset, options: options) { data, _, _, _ in
                print("getAssetThumbnail \(asset.mediaType)")
                imageSize = Float(data?.count ?? 0)
            }
        return imageSize
    }
    
    func openGallery() {
        let imagePicker = ImagePickerController(selectedAssets: selectedAssets)
        imagePicker.settings.theme.selectionStyle = .numbered
        imagePicker.settings.fetch.assets.supportedMediaTypes = [.image,.video]
        imagePicker.settings.selection.max = 5
        imagePicker.settings.preview.enabled = true
        let options = imagePicker.settings.fetch.album.options
        imagePicker.settings.fetch.album.fetchResults = [
            PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: options),
            PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: options),
        ]
        presentImagePicker(imagePicker, select: { [weak self] (asset) in
            if let strongSelf = self {
            // User selected an asset. Do something with it. Perhaps begin processing/upload?
            if  let assetName = asset.value(forKey: "filename") as? String {
                let fileExtension = URL(fileURLWithPath: assetName).pathExtension
                if ChatUtils.checkImageFileFormat(format: fileExtension) {
                    var imageSize = strongSelf.getImageSize(asset: asset)
                    imageSize = imageSize/(1024*1024)
                    print("image size: ",imageSize)
                    if imageSize >= Float(10) {
                        AppAlert.shared.showToast(message: ErrorMessage.fileSizeLarge)
                    } else {
                        strongSelf.selectedAssets.append(asset)
                    }
                } else if asset.mediaType == PHAssetMediaType.video {
                    strongSelf.selectedAssets.append(asset)
                } else {
                    AppAlert.shared.showToast(message: fileformat_NotSupport)
                }
            }
            if imagePicker.selectedAssets.count > 4 {
                AppAlert.shared.showToast(message: ErrorMessage.restrictedMoreImages)
            }
            }
        }, deselect: { [weak self] (asset) in
            if let strongSelf = self {
                // User deselected an asset. Cancel whatever you did when asset was selected.
                strongSelf.selectedAssets.enumerated().forEach { index , element in
                    if element == asset {
                        strongSelf.selectedAssets.remove(at: index)
                    }
                }
            }
        }, cancel: { [weak self] (assets) in
            // User canceled selection.
            if let strongSelf = self {
                strongSelf.selectedAssets.removeAll()
            }
        }, finish: { [weak self] (assets) in
            // User finished selection assets.
            if let strongSelf = self {
                let (imgagesAry, isSuccess) = strongSelf.getAssetThumbnail(assets: strongSelf.selectedAssets)
                if isSuccess {
                    if imgagesAry.count > 0 {
                        strongSelf.moveToImageEdit(images: imgagesAry, isPushVc: true)
                    } else {
                        strongSelf.dismiss(animated: true, completion: nil)
                    }
                }
            }
        })
    }
    
    func getAssetThumbnail(assets: [PHAsset]) -> ([ImageData], Bool) {
        var arrayOfImages :[ImageData] = [ImageData]()
        var isSuccess = true
        if assets.count > 0 {
            for asset in assets {
                if isSuccess {
                    if  let assetName = asset.value(forKey: "filename") as? String {
                        let fileExtension = URL(fileURLWithPath: assetName).pathExtension
                        let manager = PHImageManager.default()
                        let options = PHImageRequestOptions()
                        options.version = .original
                        options.isSynchronous = true
                        manager.requestImageData(for: asset, options: options) { data, _, _, _ in
                            print("getAssetThumbnail \(asset.mediaType)")
                            if let data = data {
                                if asset.mediaType == PHAssetMediaType.image {
                                    var imageSize = Float(data.count)
                                    imageSize = imageSize/(1024*1024)
                                    print(imageSize)
                                    if imageSize >= 9 {
                                        AppAlert.shared.showAlert(view: self, title: warning, message: fileSize, buttonTitle: okayButton)
                                        isSuccess = false
                                    }

                                    if  let  image = UIImage(data: data) {
                                        var imageDetail: ImageData? = ImageData(image: image, caption: nil, isVideo: false, isSlowMotion: false)
                                        if ChatUtils.checkImageFileFormat(format: fileExtension){
                                            arrayOfImages.append(imageDetail ?? ImageData(image: nil, caption: "", isVideo: false, videoUrl: nil, isSlowMotion: false))
                                        } else {
                                            imageDetail = nil
                                        }
                                    }
                                } else if asset.mediaType == PHAssetMediaType.video {
                                    if  let  image = UIImage(data: data) {
                                        let imageDetail: ImageData = ImageData(image: image, caption: nil, isVideo: true, videoUrl: asset, isSlowMotion: false)
                                        arrayOfImages.append(imageDetail)
                                    }
                                }
                            }
                        }
                    }
                }else {
                    arrayOfImages.removeAll()
                    break
                }
            }
        }
        return (arrayOfImages, isSuccess)
    }
    
    @IBAction func onReplyClear(_ sender: Any) {
        replyView.isHidden = true
        isReplyViewOpen = false
    }
        
    @IBAction func onSendButton(_ sender: Any) {
        if((messageTextView?.text.isBlank ?? false) || messageTextView?.text == startTyping.localized) {
            AppAlert.shared.showToast(message: emptyChatMessage.localized)
        }
        else {
            sendTextMessage(message: messageTextView?.text.trimmingCharacters(in: .whitespacesAndNewlines) ?? "", jid: getProfileDetails.jid)
            self.resetMessageTextView()
        }
    }
    
    func sendImageMessage(imageInfo: ImageData, jid: String?,  completionHandler :  @escaping (ChatMessage) -> Void) {
        selectedIndexs.removeAll()
        guard let image = imageInfo.image else { return }
        let compressedImage = image.compressImage(image: image)
        guard let imageData = compressedImage else {
            return
        }
        view.endEditing(true)
        let imageName  = FlyConstants.image + FlyUtils.generateUniqueId() + MessageExtension.image.rawValue
        if let (localPath,imageKey)  = FlyUtils.saveInDirectory(with: imageData , fileName: imageName, messageType: .image), let imageLocalPath = localPath, let key = imageKey {
            let imageUrl = URL(fileURLWithPath: imageLocalPath)
            let thumbail = UIImage(data: imageData)
            let resizedImage = ChatUtils.resize(thumbail ?? UIImage())
            let base64 = FlyUtils.convertImageToBase64(img: resizedImage)
            FlyMessenger.sendImageMessage(toJid: getProfileDetails.jid , imageFileName: imageName, imageFileSize: Double(imageData.count), imageFileUrl: imageUrl, imageFileLocalPath: imageLocalPath, base64Thumbnail: base64 , caption: imageInfo.caption?.trim(), replyMessageId: replyMessageId, imageFileKey: key) { [weak self] isSuccess, error, sendMessage in
                if let chatMessage = sendMessage {
                    chatMessage.mediaChatMessage?.mediaThumbImage = base64
                    chatMessage.mediaChatMessage?.mediaUploadStatus = .not_uploaded
                    if NetworkReachability.shared.isConnected {
                        if self?.sendMediaMessages?.filter({$0.messageId == chatMessage.messageId}).count == 0 {
                            self?.sendMediaMessages?.append(chatMessage)
                        }
                    }
                    guard let msg = sendMessage else { return }
                    self?.reloadList(message: msg)
                    self?.tableViewBottomConstraint?.constant = CGFloat(chatBottomConstant)
                    if self?.replyJid == self?.getProfileDetails.jid {
                        self?.replyMessageObj = nil
                        self?.isReplyViewOpen = false
                    }
                  //  FlyMessenger.uploadFile(chatMessage: chatMessage)
                    self?.uploadMediaQueue?.append(chatMessage);
                
                }
                DispatchQueue.main.async {
                    self?.chatTableView.reloadData()
                    
                }
               
                completionHandler(sendMessage!)
            }
        }
    }

    
//    func uploadFileMessage(uploadFileMessage: ChatMessage) {
//        FlyMessenger.uploadFile(chatMessage: uploadFileMessage)
//    }
    
    func reloadList(message: ChatMessage) {
        if chatMessages.count == 0 {
           addNewGroupedMessage(messages: [message])
        } else {
            chatMessages[0].insert(message, at: 0)
            chatTableView?.insertRows(at: [IndexPath(row: 0, section: 0)], with: .right)
            let indexPath = IndexPath(row: 0, section: 0)
            DispatchQueue.main.async { [weak self] in
                self?.chatTableView?.scrollToRow(at: indexPath, at: .top, animated: true)
            }
            chatTableView.reloadData()
            
//            if let cell = chatTableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? AudioSender {
//                cell.nicoProgressBar?.transition(to: .indeterminate)
//                cell.uploadCancel?.isHidden = false
//                cell.updateCancelButton?.isHidden = false
//                cell.playButton?.isHidden = true
//                cell.playIcon?.isHidden = true
//            }
            
            if let cell = chatTableView.cellForRow(at: indexPath) as? SenderImageCell {
                if NetworkReachability.shared.isConnected {
                    cell.setImageCell(message)
                }
            }
            if !NetworkReachability.shared.isConnected {
                AppAlert.shared.showToast(message: ErrorMessage.noInternet)
            }
        }
    }

    func moveToImageEdit(images: [ImageData],isPushVc: Bool) {
        
        if getUserForAdminBlock() {
            return
        }
        
        let storyboard = UIStoryboard.init(name: Storyboards.main, bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: Identifiers.imageEditController) as! ImageEditController
        controller.imageAray = images
        controller.iscamera = false
        controller.delegate = self
        controller.captionText = (messageTextView?.text != placeHolder) ? messageTextView?.text : ""
        controller.selectedAssets = self.selectedAssets
        controller.profileName = getProfileDetails.name
        navigationController?.navigationBar.isHidden = true
        navigationController?.pushViewController(controller, animated: false)
    }
    
    @objc func quickForwardAction(sender: UIButton) {
        if isShowForwardView == false {
            let buttonPosition = sender.convert(CGPoint.zero, to: chatTableView)
            if let indexPath = chatTableView.indexPathForRow(at:buttonPosition) {
                if forwardMessages?.filter({$0.chatMessage.messageId == chatMessages[indexPath.section][indexPath.row].messageId}).count == 0 {
                    var selectForwardMessage = SelectedForwardMessage()
                    selectForwardMessage.isSelected = true
                    selectForwardMessage.chatMessage = chatMessages[indexPath.section][indexPath.row]
                    forwardMessages?.append(selectForwardMessage)
                }
                navicateToSelectForwardList(forwardMessages: forwardMessages ?? [], dismissClosure: dismissKeyboard)
            }
        }
    }
    
    override func dismissKeyboard() {
        containerBottomConstraint.constant = 0.0
        self.messageTextView?.resignFirstResponder()
    }
    
    @objc func forwardAction(sender: UIButton) {
        if isShowForwardView == true {
            let row = sender.tag % 1000
            let section = sender.tag / 1000
                refreshBubbleImageView(indexPath: IndexPath(row: row, section: section) , isSelected: !(forwardMessages?.filter({$0.chatMessage.messageId == chatMessages[section][row].messageId}).first?.isSelected ?? false))
                chatTableView.reloadRows(at: [IndexPath(row: row, section: section)], with: .none)
            }
        }
    
    @objc func imageGestureAction(_ sender:AnyObject){
        let buttonPostion = sender.view.convert(CGPoint.zero, to: chatTableView)
        if let indexPath = chatTableView.indexPathForRow(at: buttonPostion) {
            let message = chatMessages[indexPath.section][indexPath.row]
            if message.mediaChatMessage?.mediaUploadStatus == .uploaded || message.mediaChatMessage?.mediaDownloadStatus == .downloaded {
                view.endEditing(true)
                let storyboard = UIStoryboard.init(name: Storyboards.main, bundle: nil)
                let controller = storyboard.instantiateViewController(withIdentifier: Identifiers.imagePreview) as! ImagePreview
                controller.jid = message.chatUserJid
                controller.messageId = message.messageId
                controller.navigationController?.isNavigationBarHidden = false
                navigationController?.pushViewController(controller, animated: true)
            }
        }
    }
    @objc func audioAction(sender: UIButton){
        let buttonPostion =  sender.convert(CGPoint.zero, to: chatTableView)
        if let indexPath = chatTableView.indexPathForRow(at: buttonPostion) {
            if let player = audioPlayer {
                if player.isPlaying {
                    stopPlayer(isBecomeBackGround: false)
                }
            }
            let message = chatMessages[indexPath.section][indexPath.row]
            if  let audioUrl = message.mediaChatMessage?.mediaFileName {
                if message.isMessageSentByMe {
                    if let cell = chatTableView.cellForRow(at: indexPath) as? AudioSender {
                        switch message.mediaChatMessage?.mediaUploadStatus {
                        case .not_uploaded:
                            if !NetworkReachability.shared.isConnected {
                                AppAlert.shared.showToast(message: ErrorMessage.checkYourInternet)
                                return
                            }
                            cell.playButton?.tag = indexPath.row
                            cell.playButton?.addTarget(self, action: #selector(audioUpload(sender:)), for: .touchUpInside)
                        case .uploaded:
                            cell.playIcon?.isHidden = false
                            cell.playButton?.isHidden = false
                            cell.nicoProgressBar?.transition(to: .indeterminate)
                            audioPlayerSetup(indexPath: indexPath, audioUrl: audioUrl)
                        case .uploading:
                            message.mediaChatMessage?.mediaUploadStatus = .not_uploaded
                            FlyMessenger.cancelMediaUploadOrDownload(message: message) { isSuccess in
                                cell.playIcon?.isHidden = true
                                cell.playButton?.isHidden = true
                                cell.uploadCancel?.isHidden = false
                                cell.updateCancelButton?.isHidden = false
                                cell.uploadCancel?.image = UIImage(named: ImageConstant.ic_upload)
                                cell.updateCancelButton?.tag = indexPath.row
                                cell.nicoProgressBar?.isHidden = true
                            }
                        default:
                            break
                        }
                    }
                } else {
                    if let cell = chatTableView.cellForRow(at: indexPath) as? AudioReceiver {
                        switch message.mediaChatMessage?.mediaDownloadStatus {
                        case .downloaded:
                            audioPlayerSetup(indexPath: indexPath, audioUrl: audioUrl)
                            cell.nicoProgressBar?.transition(to: .indeterminate)
                            cell.nicoProgressBar?.isHidden = true
                        case .not_downloaded:
                            cell.download?.isHidden = false
                            uploadCancelaudioAction(sender: sender)
                        case .downloading:
                            cell.downloadButton?.isHidden = false
                            cell.playBtn?.isHidden = true
                            uploadCancelaudioAction(sender: sender)
                        default:
                            break
                        }
                    }
                }
            }
        }
    }
    
    func audioPlayerSetup(indexPath: IndexPath, audioUrl: String) {
        if let path = currenAudioIndexPath, indexPath == path {
            stopPlayer(isBecomeBackGround: false)
            previousAudioIndexPath = currenAudioIndexPath
            currenAudioIndexPath = nil
            print("test")
        }else {
            currenAudioIndexPath = indexPath
            playAudio(audioUrl: audioUrl)
        }
    }
    
    @objc func longPressGesture(sender: UIGestureRecognizer) {
        isSelectOn = true
        print("longpressed")
        if chatTableView.isEditing {
            return
        }
        if sender.state == .began {
            print("UIGestureRecognizerStateBegan.")
            let touchPoint = sender.location(in: chatTableView)
            if let indexPath = chatTableView.indexPathForRow(at: touchPoint) {
                selectedIndexs.append(indexPath)
                chatTableView.selectRow(at: indexPath, animated: true, scrollPosition: .bottom)
                didLongPressActionForIndexPath(index: indexPath, gestureView: sender)
            }
        }
    }
    
    func didLongPressActionForIndexPath(index: IndexPath, gestureView:UIGestureRecognizer) {
        print(index)
        guard gestureView.state == .began,
              let senderView = gestureView.view,
              let _ = gestureView.view?.superview
        else { return }
        
        senderView.becomeFirstResponder()
    }
    @IBAction func onAttachButton(_ sender: Any) {
        showOptions()
    }
    
    @IBAction func onReplyButton(_ sender: Any) {
        replyMessage(indexPath: previousIndexPath)
    }
    
    
    
    @IBAction func onCopyButton(_ sender: Any) {
        let getMessage = chatMessages[previousIndexPath.section][previousIndexPath.row]
        let board = UIPasteboard.general
        board.string = getMessage.messageTextContent
        AppAlert.shared.showToast(message: "\(getMessage.messageTextContent) \(copyAlert.localized)")
    }
    
    @IBAction func onLongPressCloseButton(_ sender: Any) {
        multiSelectionView.isHidden = true
        headerView.isHidden = false
        longPressCount = 0
        isCellLongPressed = false
    }
    
    @IBAction func onDeleteButton(_ sender: Any) {
    }
    @IBAction func recordAudio(_ sender: Any) {
        startAudioRecord()
    }
}

//MARK - segue
extension ChatViewParentController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Identifiers.chatScreenToLocation {
            let locationView = segue.destination as! LocationViewController
            if toViewLocation {
                locationView.latitude = mLatitude
                locationView.longitude = mLongitude
                locationView.isForView = toViewLocation
                toViewLocation = false
            }
            locationView.locationDelegate = self
        }
        else if segue.identifier == Identifiers.chatScreenToContact {
            let contactView = segue.destination as! ChatContactViewController
            contactView.contactDelegate = self
            contactView.getContactDetails =  contactDetails
        } else if segue.identifier == Identifiers.contactInfoViewController {
            let contcatInfo =  segue.destination as! ContactInfoViewController
            contcatInfo.contactJid = getProfileDetails.jid
            contcatInfo.delegate = self
            view.endEditing(true)
        } else if segue.identifier == Identifiers.groupInfoViewController {
            let contcatInfo =  segue.destination as! GroupInfoViewController
            contcatInfo.groupID = getProfileDetails.jid
            contcatInfo.currentGroupName = getProfileDetails.name
            contcatInfo.delegate = self
            contcatInfo.groupInfoDelegate = self
            view.endEditing(true)
        }
    }
}

//MARK: - DoubleTap Gesture Handling for Translation

extension ChatViewParentController {
    
    // MARK: - Getting the indexpath of the double tapped cell
    private func getIndexpathOfCellFromGesture (_ gesture:UIGestureRecognizer )-> IndexPath {
        
        let gestureTouchPoint = gesture.location(in: self.chatTableView)
        let indexpath = self.chatTableView.indexPathForRow(at: gestureTouchPoint)
        return indexpath!
    }

        @objc func translationLanguage(_ sender: UITapGestureRecognizer? = nil) {
            guard NetworkReachability.shared.isConnected else {
                AppAlert.shared.showToast(message: ErrorMessage.noInternet)
                return
            }
            var chatViewParentMessageCell = ChatViewParentMessageCell()
            var receiverImageCell = ReceiverImageCell()
            var chatViewVideoIncomingCell = ChatViewVideoIncomingCell()
            var queryString:String?
            guard let gesture = sender else {return }
            
            let indexPath = self.getIndexpathOfCellFromGesture(gesture)
            
            currentIndexPath = indexPath
            
            let message = chatMessages[indexPath.section][indexPath.row]
            print(message.messageTextContent)
            
            if message.messageType == .text {
                
                if message.isMessageTranslated {
                    chatViewParentMessageCell = (self.chatTableView.cellForRow(at: indexPath) as? ChatViewParentMessageCell)!
                    queryString = (chatViewParentMessageCell.translatedTextLabel?.text)!
                } else {
                    chatViewParentMessageCell = (self.chatTableView.cellForRow(at: indexPath) as? ChatViewParentMessageCell)!
                    queryString = (chatViewParentMessageCell.messageLabel?.text)!
                }
            }
            
            if message.messageType == .image {
                if message.isMessageTranslated {
                    receiverImageCell = (self.chatTableView.cellForRow(at: indexPath) as? ReceiverImageCell)!
                    queryString = receiverImageCell.translatedTextLabel?.text
                } else {
                    receiverImageCell = (self.chatTableView.cellForRow(at: indexPath) as? ReceiverImageCell)!
                    queryString = receiverImageCell.caption.text
                }
            }
            
            if message.messageType == .video {
                if message.isMessageTranslated {
                    chatViewVideoIncomingCell = (self.chatTableView.cellForRow(at: indexPath) as? ChatViewVideoIncomingCell)!
                    queryString = chatViewVideoIncomingCell.translatedCaptionLabel.text
                } else {
                    chatViewVideoIncomingCell = (self.chatTableView.cellForRow(at: indexPath) as? ChatViewVideoIncomingCell)!
                    queryString = chatViewVideoIncomingCell.caption.text
                }
           
            }
            
            guard let queryString = queryString else {return}
            
            //MARK: - GoogleApi call for the translation
            FlyTranslationManager.shared.languageTransalation(jid: getProfileDetails.jid, messageId: message.messageId, QueryString: queryString, targetLanguageCode: FlyDefaults.targetLanguageCode, GooogleAPIKey: googleApiKey_Translation){ (translatedText,isSuccess,errorMessage) in
                if isSuccess{
                    print("translatedText-->", translatedText)
                } else
                {
                    print(errorMessage)
                }
            }
            
        }

}

//MARK: - Tableview
extension ChatViewParentController : UITableViewDataSource ,UITableViewDelegate,TableViewCellDelegate, UIScrollViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        if chatMessages.isEmpty {
            return 0
        }else {
            return chatMessages.count
        }
    }
    
    func openBottomView(indexPath: IndexPath) {
        if getBlockedByAdmin() {
            return
        }
        
        if getProfileDetails.profileChatType == .groupChat {
            if !isParticipantExist().doesExist {
                return
            }
        }
        
        replyMessage(indexPath: indexPath)
        
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if let firstMessageInSection = chatMessages[section].first {
            let date : Date
            if firstMessageInSection.messageChatType == .singleChat {
                 date = DateFormatterUtility.shared.convertMillisecondsToDateTime(milliSeconds: firstMessageInSection.messageSentTime)
            } else {
                 date = DateFormatterUtility.shared.convertGroupMillisecondsToDateTime(milliSeconds: firstMessageInSection.messageSentTime)
            }
            let finaldateFormatter = DateFormatter()
            finaldateFormatter.dateFormat = "d MMM, yyyy"
            let dateString = String().fetchMessageDateHeader(for: date)
            let label = ChatViewHeader()
            label.text = dateString
            let containerView = UIView()
            containerView.addSubview(label)
            label.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
            label.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
            containerView.transform = CGAffineTransform(rotationAngle: -.pi)
            return containerView
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatMessages[section].count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
         var cell : ChatViewParentMessageCell!
        let message = chatMessages[indexPath.section][indexPath.row]
        let  textReplyTap = UITapGestureRecognizer(target: self, action: #selector(self.replyViewTapGesture(_:)))
        print("Chat XYZ = \(message.messageType)")
        switch(message.messageType) {
        case .text:
            if(message.isMessageSentByMe) {
                cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.chatViewTextOutgoingCell, for: indexPath) as? ChatViewParentMessageCell
                cell?.transform = CGAffineTransform(rotationAngle: -.pi)
                cell?.refreshDelegate = self
                cell.selectedForwardMessage = forwardMessages ?? []
                cell = cell?.getCellFor(chatMessages[indexPath.section][indexPath.row], at: indexPath, isShowForwardView: isShowForwardView)
                cell.replyView?.addGestureRecognizer(textReplyTap)
            }
            else {
                cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.chatViewTextIncomingCell, for: indexPath) as? ChatViewParentMessageCell
                cell?.transform = CGAffineTransform(rotationAngle: -.pi)
                cell?.refreshDelegate = self
                cell.selectedForwardMessage = forwardMessages ?? []
                cell = cell?.getCellFor(chatMessages[indexPath.section][indexPath.row], at: indexPath, isShowForwardView: isShowForwardView)
                cell.replyView?.addGestureRecognizer(textReplyTap)
                
                
                //MARK: - Adding Double Tap Gesture for the Incoming Messages
             
                    if  FlyDefaults.isTranlationEnabled {
                            let  tap = UITapGestureRecognizer(target: self, action: #selector(self.translationLanguage(_:)))
                            tap.numberOfTapsRequired = 2
                            cell.addGestureRecognizer(tap)
                        }
                    
                if getProfileDetails.profileChatType == .groupChat {
                    if hideSenderNameToGroup(indexPath: indexPath) {
                        cell.groupMsgNameView?.isHidden = true
                        cell.groupMsgSenderName?.text = ""
                        cell.baseViewTopConstraint.constant = 1
                    } else {
                        cell.groupMsgNameView?.isHidden = false
                        cell.groupMsgSenderName?.textColor = ChatUtils.getColorForUser(userName: message.senderUserName)
                        cell.baseViewTopConstraint.constant = 3
                    }
                }
            }
            cell.forwardButton?.tag = (indexPath.section * 1000) + indexPath.row
            cell?.forwardButton?.addTarget(self, action: #selector(forwardAction(sender:)), for: .touchUpInside)
            cell?.refreshDelegate = self
            cell.delegate = self
            cell.selectionStyle = .none
            handleChatBubble(indexPath: indexPath)
            cell?.contentView.backgroundColor = .clear
            return cell
            
        case.location:
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onLocationMessage(sender:)))
            if(message.isMessageSentByMe) {
                cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.chatViewLocationOutgoingCell, for: indexPath) as? ChatViewParentMessageCell
                cell.transform = CGAffineTransform(rotationAngle: -.pi)
                cell.selectedForwardMessage = forwardMessages ?? []
                cell.quickForwardButton?.addTarget(self, action: #selector(quickForwardAction(sender:)), for: .touchUpInside)
                cell = cell.getCellFor(chatMessages[indexPath.section][indexPath.row], at: indexPath, isShowForwardView: isShowForwardView)
                cell.locationOutgoingView?.isUserInteractionEnabled = true
                cell.locationOutgoingView?.addGestureRecognizer(gestureRecognizer)
            }
            else {
                cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.chatViewLocationIncomingCell, for: indexPath) as? ChatViewParentMessageCell
                cell.transform = CGAffineTransform(rotationAngle: -.pi)
                cell.selectedForwardMessage = forwardMessages ?? []
                cell.quickForwardButton?.addTarget(self, action: #selector(quickForwardAction(sender:)), for: .touchUpInside)
                cell = cell.getCellFor(chatMessages[indexPath.section][indexPath.row], at: indexPath, isShowForwardView: isShowForwardView)
                if getProfileDetails.profileChatType == .groupChat {
                    if hideSenderNameToGroup(indexPath: indexPath) {
                        cell.groupMsgNameView?.isHidden = true
                        cell.groupMsgSenderName?.text = ""
                        cell.baseViewTopConstraint.constant = 1
                    } else {
                        cell.groupMsgNameView?.isHidden = false
                        cell.groupMsgSenderName?.textColor = ChatUtils.getColorForUser(userName: message.senderUserName)
                        cell.baseViewTopConstraint.constant = 3
                        
                    }
                }
                cell.locationImageView?.addGestureRecognizer(gestureRecognizer)
            }
            cell.forwardButton?.tag = (indexPath.section * 1000) + indexPath.row
            cell?.forwardButton?.addTarget(self, action: #selector(forwardAction(sender:)), for: .touchUpInside)
            cell.delegate = self
            cell?.refreshDelegate = self
            cell.selectionStyle = .none
            cell?.contentView.backgroundColor = .clear
            return cell
            
        case .contact:
            if(message.isMessageSentByMe) {
                cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.chatViewContactOutgoingCell, for: indexPath) as? ChatViewParentMessageCell
                cell.transform = CGAffineTransform(rotationAngle: -.pi)
                cell.selectedForwardMessage = forwardMessages ?? []
                cell = cell.getCellFor(chatMessages[indexPath.section][indexPath.row], at: indexPath, isShowForwardView: isShowForwardView)
            }
            else {
                cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.chatViewContactIncomingCell, for: indexPath) as? ChatViewParentMessageCell
                cell.transform = CGAffineTransform(rotationAngle: -.pi)
                cell.selectedForwardMessage = forwardMessages ?? []
                cell = cell.getCellFor(chatMessages[indexPath.section][indexPath.row], at: indexPath, isShowForwardView: isShowForwardView)!
                let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onsaveContact(sender:)))
                cell.saveContactButton?.addGestureRecognizer(gestureRecognizer)
                cell.saveContactButton?.addGestureRecognizer(gestureRecognizer)
                if getProfileDetails.profileChatType == .groupChat {
                    if hideSenderNameToGroup(indexPath: indexPath) {
                        cell.groupMsgNameView?.isHidden = true
                        cell.groupMsgSenderName?.text = ""
                        cell.baseViewTopConstraint.constant = 1
                    } else {
                        cell.groupMsgNameView?.isHidden = false
                        cell.groupMsgSenderName?.textColor = ChatUtils.getColorForUser(userName: message.senderUserName)
                        cell.baseViewTopConstraint.constant = 3
                    }
                }
            }
            cell.forwardButton?.tag = (indexPath.section * 1000) + indexPath.row
            cell?.forwardButton?.addTarget(self, action: #selector(forwardAction(sender:)), for: .touchUpInside)
            cell.quickForwardButton?.addTarget(self, action: #selector(quickForwardAction(sender:)), for: .touchUpInside)
            cell?.refreshDelegate = self
            cell.selectionStyle = .none
            cell?.delegate = self
            cell?.contentView.backgroundColor = .clear
            return cell
        case .image:
            if(message.isMessageSentByMe) {
                var cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.imageSender, for: indexPath) as? SenderImageCell
                cell?.transform = CGAffineTransform(rotationAngle: -.pi)
                cell?.selectedForwardMessage = forwardMessages
                cell?.imageContainer?.tag = indexPath.row
                cell?.imageContainer?.isUserInteractionEnabled = true
                cell?.imageGeasture.addTarget(self, action: #selector(imageGestureAction(_:)))
                cell?.retryButton?.tag = (indexPath.section * 1000) + indexPath.row
                cell?.retryButton?.addTarget(self, action: #selector(cancelOrUploadImages(sender:)), for: .touchUpInside)
                cell?.fwdButton?.addTarget(self, action: #selector(quickForwardAction(sender:)), for: .touchUpInside)
                cell?.forwardButton?.tag = (indexPath.section * 1000) + indexPath.row
                cell?.forwardButton?.addTarget(self, action: #selector(forwardAction(sender:)), for: .touchUpInside)
                cell?.sendMediaMessages = sendMediaMessages
                cell = cell?.getCellFor(chatMessages[indexPath.section][indexPath.row], at: indexPath, isShowForwardView: isShowForwardView)
                cell?.delegate = self
                cell?.refreshDelegate = self
                cell?.composeMailDelegate = self
                cell?.selectionStyle = .none
                cell?.contentView.backgroundColor = .clear
                return cell ??  UITableViewCell()
            }else {
                var cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.imageReceiverCell, for: indexPath) as? ReceiverImageCell
                cell?.transform = CGAffineTransform(rotationAngle: -.pi)
                cell?.downoadButton.tag = indexPath.row
                cell?.downoadButton.addTarget(self, action: #selector(imageDownload(sender:)), for: .touchUpInside)
                cell?.imageContainer.tag = indexPath.row
                cell?.imageContainer.isUserInteractionEnabled = true
                cell?.imageGeasture.addTarget(self, action: #selector( imageGestureAction(_:)))
                cell?.fwdIcon?.addTarget(self, action: #selector(quickForwardAction(sender:)), for: .touchUpInside)
                cell?.selectedForwardMessage = forwardMessages
                cell?.progrssButton.addTarget(self, action: #selector(cancelImageDownload(sender:)), for: .touchUpInside)
                cell?.forwardButton?.tag = (indexPath.section * 1000) + indexPath.row
                cell?.forwardButton?.addTarget(self, action: #selector(forwardAction(sender:)), for: .touchUpInside)
                cell?.receivedMediaMessages = receivedMediaMessages
                cell = cell?.getCellFor(chatMessages[indexPath.section][indexPath.row], at: indexPath, isShowForwardView: isShowForwardView)!
                //MARK: - Double tap gesture for ReceiverImageCell
    
                    if FlyDefaults.isTranlationEnabled {
                        let  tapImageCaption = UITapGestureRecognizer(target: self, action: #selector(self.translationLanguage(_:)))
                        tapImageCaption.numberOfTapsRequired = 2
                        cell?.captionStackView.isUserInteractionEnabled = true
                        cell?.captionStackView.addGestureRecognizer(tapImageCaption)
                    }
                
              
                cell?.progrssButton.tag = (indexPath.section * 1000) + indexPath.row
                cell?.delegate = self
                cell?.composeMailDelegate = self
                cell?.refreshDelegate = self
                cell?.selectionStyle = .none
                if getProfileDetails.profileChatType == .groupChat {
                    if hideSenderNameToGroup(indexPath: indexPath) {
                        cell?.senderNameContainer.isHidden = true
                        cell?.bubbleImageTopConstraint.constant = 1
                    } else {
                        cell?.senderNameContainer.isHidden = false
                        cell?.groupSenderNameLabel.textColor = ChatUtils.getColorForUser(userName: message.senderUserName)
                        cell?.bubbleImageTopConstraint.constant = 3
                    }
                }
                cell?.contentView.backgroundColor = .clear
                return cell ?? UITableViewCell()
                
            }
        case .audio:
            if(message.isMessageSentByMe) {
                var cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.audioSender, for: indexPath) as? AudioSender
                cell?.selectedForwardMessage = forwardMessages
                cell?.isShowAudioLoadingIcon = isShowAudioLoadingIcon
                cell?.uploadingMediaObjects = uploadingMediaObjects
                cell = cell?.getCellFor(chatMessages[indexPath.section][indexPath.row], at: indexPath, isPlaying: currenAudioIndexPath == indexPath ? audioPlayer?.isPlaying ?? false : false, audioClosureCallBack: { [weak self] (sliderValue)  in
                    self?.forwardAudio(sliderValue: sliderValue,indexPath:indexPath)
                }, isShowForwardView: isShowForwardView)
                cell?.audioPlaySlider?.value = Float((indexPath == currenAudioIndexPath) ? (audioPlayer?.currentTime ?? 0.0) : 0.0)
                cell?.updateCancelButton?.tag = indexPath.row
                cell?.playButton?.tag = indexPath.row
                cell?.delegate = self
                cell?.refreshDelegate = self
                cell?.playButton?.addTarget(self, action: #selector(audioAction(sender:)), for: .touchUpInside)
                cell?.updateCancelButton?.addTarget(self, action: #selector(uploadCancelaudioAction(sender:)), for: .touchUpInside)
                cell?.forwardButton?.tag = (indexPath.section * 1000) + indexPath.row
                cell?.forwardButton?.addTarget(self, action: #selector(forwardAction(sender:)), for: .touchUpInside)
                cell?.fwdBtn?.addTarget(self, action: #selector(quickForwardAction(sender:)), for: .touchUpInside)
                cell?.transform = CGAffineTransform(rotationAngle: -.pi)
                cell?.selectionStyle = .none
                cell?.contentView.backgroundColor = .clear
                return cell ?? UITableViewCell()
            } else {
                var cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.audioReceiver, for: indexPath) as? AudioReceiver
                cell?.transform = CGAffineTransform(rotationAngle: -.pi)
                cell?.selectedForwardMessage = forwardMessages ?? []
                cell = cell?.getCellFor(chatMessages[indexPath.section][indexPath.row], at: indexPath, isPlaying: currenAudioIndexPath == indexPath ? audioPlayer?.isPlaying ?? false : false, audioClosureCallBack: { [weak self] (sliderValue)  in
                    self?.forwardAudio(sliderValue: sliderValue, indexPath: indexPath)
                }, isShowForwardView: isShowForwardView)!
                cell?.slider?.value = Float((indexPath == currenAudioIndexPath) ? (audioPlayer?.currentTime ?? 0.0) : 0.0)
                cell?.delegate = self
                cell?.refreshDelegate = self
                cell?.downloadButton?.tag = (indexPath.section * 1000) + indexPath.row
                cell?.downloadButton?.addTarget(self, action:#selector(uploadCancelaudioAction(sender: )), for: .touchUpInside)
                cell?.playBtn?.addTarget(self, action: #selector(audioAction(sender:)), for: .touchUpInside)
                cell?.forwardButton?.tag = (indexPath.section * 1000) + indexPath.row
                cell?.forwardButton?.addTarget(self, action: #selector(forwardAction(sender:)), for: .touchUpInside)
                cell?.fwdBtn?.addTarget(self, action: #selector(quickForwardAction(sender:)), for: .touchUpInside)
                cell?.selectionStyle = .none
                hideSenderNameToGroup(indexPath: indexPath)
                cell?.contentView.backgroundColor = .clear
                return cell ?? UITableViewCell()
            }
        case .video:
            if(message.isMessageSentByMe) {
                var cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.videoOutgoingCell, for: indexPath) as! ChatViewVideoOutgoingCell
                cell.transform = CGAffineTransform(rotationAngle: -.pi)
                cell.selectedForwardMessage = forwardMessages ?? []
                cell.sendMediaMessages = sendMediaMessages
                cell = cell.getCellFor(chatMessages[indexPath.section][indexPath.row], at: indexPath, isShowForwardView: isShowForwardView)!
                cell.imageContainer.tag = (indexPath.section * 1000) + indexPath.row
                cell.playButton.tag = (indexPath.section * 1000) + indexPath.row
                cell.playButton.addTarget(self, action: #selector(playVideoGestureAction(sender:)), for: .touchUpInside)
                cell.cancelUploadButton.tag = (indexPath.section * 1000) + indexPath.row
                cell.cancelUploadButton.addTarget(self, action: #selector(cancelVideoUpload(sender:)), for: .touchUpInside)
                cell.retryButton?.tag = (indexPath.section * 1000) + indexPath.row
                cell.retryButton?.addTarget(self, action: #selector(retryVideoUpload(sender:)), for: .touchUpInside)
                cell.quickFwdBtn?.addTarget(self, action: #selector(quickForwardAction(sender:)), for: .touchUpInside)
                cell.forwardButton?.tag = (indexPath.section * 1000) + indexPath.row
                cell.forwardButton?.addTarget(self, action: #selector(forwardAction(sender:)), for: .touchUpInside)
                cell.delegate = self
                cell.refreshDelegate = self
                cell.selectionStyle = .none
                cell.contentView.backgroundColor = .clear
                return cell
            }else {
                var cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.videoIncomingCell, for: indexPath) as! ChatViewVideoIncomingCell
                cell.transform = CGAffineTransform(rotationAngle: -.pi)
                cell.selectedForwardMessage = forwardMessages ?? []
                cell = cell.getCellFor(chatMessages[indexPath.section][indexPath.row], at: indexPath, isShowForwardView: isShowForwardView)!
                
                //MARK: - Double tap gesture for VideoIncomingCel
                    if FlyDefaults.isTranlationEnabled {
                        let  tapVideoCaption = UITapGestureRecognizer(target: self, action: #selector(self.translationLanguage(_:)))
                        tapVideoCaption.numberOfTapsRequired = 2
                        cell.captionView.isUserInteractionEnabled = true
                        cell.captionView.addGestureRecognizer(tapVideoCaption)
                    }
                
                cell.downloadButton.tag = (indexPath.section * 1000) + indexPath.row
                cell.downloadButton.addTarget(self, action: #selector(videoDownload(sender:)), for: .touchUpInside)
                cell.playButton.tag = (indexPath.section * 1000) + indexPath.row
                cell.playButton.addTarget(self, action: #selector(playVideoGestureAction(sender:)), for: .touchUpInside)
                cell.progressButton.tag = (indexPath.section * 1000) + indexPath.row
                cell.progressButton.addTarget(self, action: #selector(cancelVideoDownload(sender:)), for: .touchUpInside)
                cell.quickForwardButton?.addTarget(self, action: #selector(quickForwardAction(sender:)), for: .touchUpInside)
                cell.forwardButton?.tag = (indexPath.section * 1000) + indexPath.row
                cell.forwardButton?.addTarget(self, action: #selector(forwardAction(sender:)), for: .touchUpInside)
                cell.delegate = self
                cell.refreshDelegate = self
                cell.selectionStyle = .none
                if getProfileDetails.profileChatType == .groupChat {
                    if hideSenderNameToGroup(indexPath: indexPath) {
                        cell.senderNameView.isHidden = true
                        cell.bubbleImageTopConstraint.constant = 1
                    } else {
                        cell.senderNameView.isHidden = false
                        cell.senderGroupNameLabel.textColor = ChatUtils.getColorForUser(userName: message.senderUserName)
                        cell.bubbleImageTopConstraint.constant = 3
                    }
                }
                cell.contentView.backgroundColor = .clear
                return cell
            }
        case .document:
            break
        case .notification:
            
            let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.notificationCell, for: indexPath) as! NotificationCell
            cell.transform = CGAffineTransform(rotationAngle: -.pi)
            cell.notificationLabel.text = chatMessages[indexPath.section][indexPath.row].messageTextContent
            cell.selectionStyle = .none
            cell.contentView.backgroundColor = .clear
            return cell
        }
        return UITableViewCell()
    }
    

    func updateSelectionColor(indexPath: IndexPath) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            if let cell = self?.chatTableView.cellForRow(at: indexPath) {
                cell.contentView.backgroundColor = .clear
            }
        }
    }
    
    func forwardAudio(sliderValue : Float,indexPath: IndexPath) {
        audioPlayer?.currentTime = TimeInterval(sliderValue)
        chatMessages[currenAudioIndexPath?.section ?? 0][currenAudioIndexPath?.row ?? 0].audioTrackTime = sliderValue
    }
    
    func checkforStar(indexs :[IndexPath]) -> Bool {
        var isStarAdded = false
        for index in indexs {
            let message = messages[index.row]
            if message.isMessageStarred {
                isStarAdded = true
                return isStarAdded
            }
        }
        return isStarAdded
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        chatTableView.deselectRow(at: indexPath, animated: true)
        if isCellLongPressed {
            isCellLongPressed = false
        }
    }
}

extension ChatViewParentController {
    @objc func onLocationMessage(sender: UIGestureRecognizer) {
        if !NetworkReachability.shared.isConnected {
            AppAlert.shared.showToast(message: ErrorMessage.checkYourInternet)
            return
        }
        guard let indexPath =  chatTableView.indexPathForRow(at: sender.location(in:  chatTableView)) else {
            return
        }
        
        print("indexPath.row: \(indexPath.row)")
        let message =  chatMessages[indexPath.section][indexPath.row]
        let selectedLatitude = message.locationChatMessage?.latitude ?? 0
        let selectedLongitude = message.locationChatMessage?.longitude ?? 0
        
        toViewLocation = true
        mLatitude = selectedLatitude
        mLongitude = selectedLongitude
        view.endEditing(true)
        goToMap()
    }
    
    func openGoogleMap(latitude: Double, longitude: Double) {
        
        if (UIApplication.shared.canOpenURL(URL(string:"comgooglemaps://")!)) {
            UIApplication.shared.openURL(URL(string:
                                                "comgooglemaps://?center=\(latitude),\(longitude)&zoom=14&views=traffic")!)
        }
        else {
            openMapsForPlace(latitude: latitude, longitude: longitude, title: "")
        }
    }

    func openMapsForPlace(latitude: CLLocationDegrees, longitude: CLLocationDegrees, title: String) {
        
        var center : CLLocationCoordinate2D = CLLocationCoordinate2D()
        let ceo: CLGeocoder = CLGeocoder()
        center.latitude = latitude
        center.longitude = longitude
        let loc: CLLocation = CLLocation(latitude:center.latitude, longitude: center.longitude)
        ceo.cancelGeocode()
        ceo.reverseGeocodeLocation(loc, completionHandler:
                                    {(placemarks, error) in
                        if (error != nil)
                        {
                            print("reverse geodcode fail: \(error!.localizedDescription)")
                        }
                        guard let pm = placemarks else {
                            self.openMap(latitude: latitude, longitude: longitude, title: title, address: nil)
                            return
                        }

                        if pm.count > 0 {
                            let pm = placemarks![0]
                            var streetName = ""
                            var address = [String : Any]()
                            if let street = pm.postalAddress?.value(forKey: "street") as? String{
                                print("Location Address street \(street)")
                                address[CNPostalAddressStreetKey] = street
                                streetName = street
                            }
                            
                            if let subLocality = pm.postalAddress?.value(forKey: "subLocality") as? String{
                                if streetName.isEmpty {
                                    address[CNPostalAddressStreetKey] = subLocality
                                } else {
                                    address[CNPostalAddressSubLocalityKey] = subLocality
                                }
                            }
                            
                            if let city = pm.postalAddress?.value(forKey: "city") as? String {
                                address[CNPostalAddressCityKey] = city
                            }
                            
                            if let subAdministrativeArea = pm.postalAddress?.value(forKey: "subAdministrativeArea") as? String {
                               address[CNPostalAddressSubAdministrativeAreaKey] = subAdministrativeArea
                            }
                            
                            if let state = pm.postalAddress?.value(forKey: "state") as? String {
                               address[CNPostalAddressStateKey] = state
                            }
                            
                            if let postalCode = pm.postalAddress?.value(forKey: "postalCode") as? String {
                                address[CNPostalAddressPostalCodeKey] = postalCode
                            }
                            
                            if let country = pm.postalAddress?.value(forKey: "country") as? String {
                                address[CNPostalAddressISOCountryCodeKey] = country
                            }
                            print("Address \(address)")
                            self.openMap(latitude: latitude, longitude: longitude, title: title, address: address)
            
                        } else {
                            self.openMap(latitude: latitude, longitude: longitude, title: title, address: nil)
                        }
                })
        
    }
    
    func openMap(latitude: CLLocationDegrees, longitude: CLLocationDegrees, title: String,address : [String: Any]?) {
        
        let regionDistance:CLLocationDistance = 10000
        let coordinates = CLLocationCoordinate2DMake(latitude, longitude)
        let regionSpan = MKCoordinateRegion(center: coordinates, latitudinalMeters: regionDistance, longitudinalMeters: regionDistance)
        let options = [
            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center),
            MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span),
        ]
        let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: address)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = title
        mapItem.openInMaps(launchOptions: options)
    }
    
    @objc func onsaveContact(sender: UIGestureRecognizer) {
        guard let indexPath =  chatTableView.indexPathForRow(at: sender.location(in:  chatTableView)) else {
            return
        }
        
        print("indexPath.row: \(indexPath.row)")
        let message  =  chatMessages[indexPath.section][indexPath.row]
        print("onsaveContact \(message.contactChatMessage?.contactName) \(message.contactChatMessage?.contactPhoneNumbers)")
        if let contactNumbers : [String:Bool] = message.contactChatMessage?.contactPhoneNumbers as? [String:Bool] {
            var contacts = [String]()
            contactNumbers.forEach { (contact: String, status: Bool) in
                contacts.append(contact)
            }
            redirectToContact(contactName: message.contactChatMessage?.contactName ?? "", contactNumber:contacts)
        }
       
    }
    
    func redirectToContact(contactName: String, contactNumber: [String]) {
        let newContact = CNMutableContact()
        contactNumber.forEach { contact in
            newContact.phoneNumbers.append(CNLabeledValue(label: "home", value: CNPhoneNumber(stringValue: contact)))
        }
        newContact.givenName = contactName
        let contactVC = CNContactViewController(forUnknownContact: newContact)
        contactVC.contactStore = CNContactStore()
        contactVC.delegate = self
        contactVC.allowsActions = false
        //let navigationController = UINavigationController(rootViewController: contactVC)
        self.navigationController?.pushViewController(contactVC, animated: true)
    }
    
    @objc func replyMessage(indexPath: IndexPath) {
        if isShowForwardView == false {
            let messageStatus =  chatMessages[indexPath.section][indexPath.row].messageStatus
                if  (messageStatus == .delivered || messageStatus == .received || messageStatus == .seen || messageStatus == .acknowledged) {
                if (longPressCount == 0 && !indexPath.isEmpty) {
                    currentPreviewIndexPath = indexPath
                    isReplyViewOpen = true
                    let message =  chatMessages[currentPreviewIndexPath?.section ?? 0][currentPreviewIndexPath?.row ?? 0]
                    let senderInfo = contactManager.getUserProfileDetails(for: message.senderUserJid)
                    replyMessageObj = message
                    replyJid = getProfileDetails.jid
                    messageText = messageTextView?.text ?? ""
                    replyView.isHidden = false
                    replyCloseButtonTapped = false
                    replyMessageId = message.messageId
                    chatTextViewXib?.closeButton?.addTarget(self, action: #selector(closeButtontapped(sender:)), for: .touchUpInside)
                    chatTextViewXib?.setupUI()
                    chatTextViewXib?.setSenderReceiverMessage(message: message, contactType: senderInfo?.contactType ?? .unknown)
                    tableViewBottomConstraint?.constant = CGFloat(chatBottomConstant)
                    tableViewBottomConstraint?.constant = (tableViewBottomConstraint?.constant ?? 0) + 40 + textToolBarViewHeight!.constant
                    messageTextView?.becomeFirstResponder()
                    chatTextViewXib?.setNeedsLayout()
                    chatTextViewXib?.layoutIfNeeded()
                }
            }
        }
    }

    @objc func closeButtontapped(sender: UIButton) {
        resetReplyView()
    }
    
    func resetReplyView() {
        replyView.isHidden = true
        isReplyViewOpen = false
        longPressCount = 0
        isCellLongPressed = false
        replyMessageId = ""
        replyMessageObj = nil
        messageText = ""
        replyCloseButtonTapped = true
        messageTextView?.resignFirstResponder()
        tableViewBottomConstraint?.constant = CGFloat(chatBottomConstant)
        tableViewBottomConstraint?.constant = textToolBarViewHeight!.constant + 5
    }

    
    func heightForView(text:String, font:UIFont, width:CGFloat) -> CGFloat{
        let label:UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.font = font
        label.text = text
        label.sizeToFit()
        return label.frame.height
    }
}

extension ChatViewParentController : UIImagePickerControllerDelegate, EditImageDelegate {
    func selectedImages(images: [ImageData]) {
        
        if getUserForAdminBlock() {
            return
        }
        
       // let group = DispatchGroup()
       executeOnMainThread { [self] in
            images.forEach { item in
              //  group.enter()
                if item.isVideo {
                    print("Video message *****")
                    self.sendVideoMessage(videoDetail: item, jid: self.getProfileDetails.jid) { chatMessage in
                        print("Video message *****sent")
                       // self.uploadMediaQueue?.append(chatMessage);
                  //  group.leave()
                    }
                } else {
                    print("Image message *****")
                    // self.sendImageMessage(imageInfo: item, jid: getProfileDetails.jid, completionHandler: (isS) -> Void)
                    self.sendImageMessage(imageInfo: item, jid: getProfileDetails.jid) { chatMessage in
                        print("Image message ***** sent")
                        
                       // self.uploadMediaQueue?.append(chatMessage);
                      //  group.leave()
                    }
                }
               // group.wait()
                
            }
            self.replyMessageId = ""
            self.containerBottomConstraint.constant = 0.0
        }
    }
    
  func insertVideoAndImage(images: [ImageData],count: Int) {
      
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        imagePicker.dismiss(animated: true, completion: nil)
        let mediaType = info[UIImagePickerController.InfoKey.mediaType] as! CFString
        switch mediaType {
        case kUTTypeImage:
            guard let selectedImage = info[.originalImage] as? UIImage else {
                print("Image not found!")
                return
            }
            // Handle image selection result
            var flippedImage: UIImage?
            if imagePicker.cameraDevice == .front {
                flippedImage = UIImage(cgImage: selectedImage.cgImage!,scale: selectedImage.scale,orientation: .leftMirrored)
            }
            let imageDetail: ImageData = ImageData(image: imagePicker.cameraDevice == .front ? flippedImage : selectedImage, caption: nil, isVideo: false,videoUrl: nil, isSlowMotion: false)
            let arrayOfImages = [imageDetail]
            // save image in local folder
            let customPhotoAlbum = CustomPhotoAlbum()
            let assetCollection = customPhotoAlbum.createFolder(image: selectedImage, currentFolder: "MirrorFlyUIkit Camera Roll")
             customPhotoAlbum.saveImage(image: selectedImage, currentFolder: "MirrorFlyUIkit Camera Roll", assetsCollection: assetCollection)
            moveToImageEdit(images: arrayOfImages, isPushVc: false)
            
        case kUTTypeMovie:
            // Handle video selection result
            print("Selected media is video \(info.keys)")
            guard let mediaURL = info[UIImagePickerController.InfoKey.mediaURL] as? URL else { return }
                       self.saveVideo(at: mediaURL)
            
        default:
            print("Mismatched type: \(mediaType)")
        }
        
    }
    
    private func saveVideo(at mediaUrl: URL) {
        let compatible = UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(mediaUrl.path)
        if compatible {
            UISaveVideoAtPathToSavedPhotosAlbum(mediaUrl.path, self, #selector(video(videoPath:didFinishSavingWithError:contextInfo:)), nil)
            
        }
    }
    
    @objc func video(videoPath: NSString, didFinishSavingWithError error: NSError?, contextInfo info: AnyObject) {
        let videoURL = URL(fileURLWithPath: videoPath as String)
        let image = FlyUtils.generateThumbnail(path: videoURL)
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
        }) { saved, error in
            if saved {
                let fetchOptions = PHFetchOptions()
                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
                let fetchResult = PHAsset.fetchAssets(with: .video, options: fetchOptions).lastObject
                let imageDetail: ImageData = ImageData(image: image, caption: nil, isVideo: true,videoUrl: fetchResult, isSlowMotion: false)
                let arrayOfImages = [imageDetail]
                DispatchQueue.main.async { [weak self] in
                    self?.moveToImageEdit(images: arrayOfImages, isPushVc: true)
                }
              
            }
            print("saved \(saved), erro \(error)")
        }
    }
}

extension ChatViewParentController : MessageEventsDelegate {
    
    func onMessageTranslated(message: ChatMessage, jid: String) {
            chatMessages[currentIndexPath.section][currentIndexPath.row] = message
            self.chatTableView.reloadRows(at: [currentIndexPath], with: UITableView.RowAnimation.none)
    }
    
    func onMessageReceived(message: ChatMessage, chatJid: String) {
        // document message not implemneted
        if message.messageType == MessageType.document {
            return
        }
        print("onMessageReceived  \(getProfileDetails.jid) = \(message.chatUserJid) \(message.isMessageSentByMe)")
        if currenAudioIndexPath == nil {
            currenAudioIndexPath = previousAudioIndexPath != nil ? previousAudioIndexPath : nil
        }
        if audioPlayer?.isPlaying == true {
            if currenAudioIndexPath != nil {
                if currenAudioIndexPath == IndexPath(row: 0, section: 0) {
                    previousAudioIndexPath = IndexPath(row: 1, section: 0)
                }
            }
        }
        if currenAudioIndexPath != nil {
            let nextRow = (currenAudioIndexPath?.row ?? 0) + 1
            let indexPath = IndexPath(row: nextRow, section: currenAudioIndexPath?.section ?? 0)
            currenAudioIndexPath = indexPath
        }
        if message.isMessageSentByMe && message.isCarbonMessage == true {
            if message.mediaChatMessage != nil && message.isCarbonMessage == true {
                FlyMessenger.downloadMediaRetry(message: message) { [weak self] (success, error, message) in
                }
            }
        }
        if (getProfileDetails.jid == message.chatUserJid){
            selectedIndexs.removeAll()
            if FlyDefaults.myJid != chatJid {
                appendNewMessage(message: message)
            } else if FlyDefaults.myJid == chatJid && message.chatUserJid == getProfileDetails.jid {
                if getProfileDetails.profileChatType == .singleChat {
                    appendNewMessage(message: message)
                } else if getProfileDetails.profileChatType == .groupChat {
                    if !isMessageExist(messageId: message.messageId) {
                        appendNewMessage(message: message)
                    }
                }
                    
            }
            markMessagessAsRead()
            DispatchQueue.main.async { [weak self] in
                //self?.chatTableView.reloadData()
                self?.chatTableView.reloadDataWithoutScroll()
            }
        }
  }
    
    func isMessageExist(messageId : String) -> Bool{
        let tempMessages = chatMessages.reversed()
        for (index, messageArray) in tempMessages.enumerated() {
            print("isMessageExist \(index)")
            for message in messageArray {
                if messageId == message.messageId {
                    print("isMessageExist if messageId == message.messageId")
                    return true
                }
            }
            if index > 1 {
                return false
            }
        }
        return false
    }
    
    func onMessageStatusUpdated(messageId: String, chatJid: String, status: MessageStatus) {
        print("onMessageStatusUpdated \(messageId) \(chatJid) \(status)")
        if let indexpath = chatMessages.indexPath(where: {$0.messageId == messageId}) {
            DispatchQueue.main.async { [weak self] in
                self?.chatMessages[indexpath.section][indexpath.row].messageStatus = status
                self?.chatTableView?.beginUpdates()
                self?.chatMessages[indexpath.section][indexpath.row].messageStatus = status
                self?.chatTableView?.reloadRows(at: [indexpath], with: .none)
                self?.chatTableView?.endUpdates()
                if let cell = self?.chatTableView.cellForRow(at: indexpath) as? SenderImageCell {
                    if status == .acknowledged || status == .received || status == .delivered || status == .seen {
                        cell.uploadView?.isHidden = true
                        cell.progressView?.isHidden = true
                        cell.nicoProgressBar?.isHidden = true
                        cell.retryButton?.isHidden = true
                    } else if status == .sent {
                        cell.nicoProgressBar?.transition(to: .indeterminate)
                        cell.nicoProgressBar?.isHidden = false
                        cell.uploadView?.isHidden = true
                    }
                }
            }
        }
    }
    
    func onMediaStatusUpdated(message: ChatMessage) {
        print("onMediaStatusUpdated \(message.messageType) \(message.messageId)")
        if let indexPath = chatMessages.indexPath(where: {$0.messageId == message.messageId}){
            chatMessages[indexPath.section][indexPath.row] = message
            _ = chatMessages[indexPath.section][indexPath.row]
            if message.isMessageSentByMe && message.isCarbonMessage == true {
                if message.messageType == .audio {
                    updateForCarbonAudio(message: message, index: indexPath)
                } else if message.messageType == .image {
                    updateForImageWithCarbon(message: message, index: indexPath)
                } else if message.messageType == .video {
                    updateCarbonVideo(message: message, index: indexPath)
                }
            } else {
                if message.messageType == .audio {
                    updateForAudioStatus(message: message, index: indexPath)
                } else if message.messageType == .image {
                    updateForImageStatus(message: message, index: indexPath)
                } else if message.messageType == .video {
                    updateVideoStatus(message: message, index: indexPath)
                }
            }
        }
    }
    
    func updateForImageWithCarbon(message: ChatMessage, index: IndexPath) {
        if message.isMessageSentByMe {
            chatMessages[index.section][index.row] = message
            if let cell = chatTableView.cellForRow(at: index) as? SenderImageCell {
                if let localPath = message.mediaChatMessage?.mediaFileName {
                    let directoryURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let folderPath: URL = directoryURL.appendingPathComponent("FlyMedia/Image", isDirectory: true)
                    let fileURL: URL = folderPath.appendingPathComponent(localPath)
                    if FileManager.default.fileExists(atPath: fileURL.relativePath) {
                              let data = NSData(contentsOf: fileURL)
                          let image = UIImage(data: data! as Data)
                        cell.imageContainer?.image = image
                      }
                } else {
                    if let thumbImage = message.mediaChatMessage?.mediaThumbImage {
                        ChatUtils.setThumbnail(imageContainer: cell.imageContainer ?? UIImageView(), base64String: thumbImage)
                    }
                }
                cell.getCellFor(message, at: index, isShowForwardView: isShowForwardView)
                if  (message.mediaChatMessage?.mediaDownloadStatus == .not_downloaded  || message.mediaChatMessage?.mediaDownloadStatus == .downloading || message.messageStatus == .notAcknowledged || isShowForwardView == true || message.messageStatus == .sent) {
                    cell.fwdView?.isHidden = true
                    cell.fwdButton?.isHidden = true
                } else {
                    cell.fwdView?.isHidden = false
                    cell.fwdButton?.isHidden = false
                }
            }
        }
    }
    
    func updateForImageStatus(message: ChatMessage, index: IndexPath) {
        if message.isMessageSentByMe {
            chatMessages[index.section][index.row] = message
            if let cell = chatTableView.cellForRow(at: index) as? SenderImageCell {
                if let localPath = message.mediaChatMessage?.mediaFileName {
                    let directoryURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let folderPath: URL = directoryURL.appendingPathComponent("FlyMedia/Image", isDirectory: true)
                    let fileURL: URL = folderPath.appendingPathComponent(localPath)
                    if FileManager.default.fileExists(atPath: fileURL.relativePath) {
                              let data = NSData(contentsOf: fileURL)
                          let image = UIImage(data: data! as Data)
                        cell.imageContainer?.image = image
                      }
                } else {
                    if let thumbImage = message.mediaChatMessage?.mediaThumbImage {
                        ChatUtils.setThumbnail(imageContainer: cell.imageContainer ?? UIImageView(), base64String: thumbImage)
                    }
                }

                if  (message.mediaChatMessage?.mediaUploadStatus == .not_uploaded  || message.mediaChatMessage?.mediaUploadStatus == .uploading || message.messageStatus == .notAcknowledged || isShowForwardView == true || message.messageStatus == .sent) {
                    cell.fwdView?.isHidden = true
                    cell.fwdButton?.isHidden = true
                } else {
                    cell.fwdView?.isHidden = false
                    cell.fwdButton?.isHidden = false
                }
               
                sendMediaMessages?.enumerated().forEach({ (index,chatMessage) in
                    if chatMessage.messageId == message.messageId {
                        if (sendMediaMessages?.count ?? 0) > index {
                            sendMediaMessages?.remove(at: index)
                        }
                    }
                })
                cell.getCellFor(message, at: index, isShowForwardView: isShowForwardView)
            }
            
        } else {
            chatMessages[index.section][index.row] = message
            if let cell = chatTableView.cellForRow(at: index) as? ReceiverImageCell {
                if let localPath = message.mediaChatMessage?.mediaFileName {
                    let directoryURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let folderPath: URL = directoryURL.appendingPathComponent("FlyMedia/Image", isDirectory: true)
                    let fileURL: URL = folderPath.appendingPathComponent(localPath)
                    if FileManager.default.fileExists(atPath: fileURL.relativePath) {
                        let data = NSData(contentsOf: fileURL)
                        if let image = UIImage(data: data! as Data) {
                            // save image in local folder
                            let customPhotoAlbum = CustomPhotoAlbum()
                            let assetCollection =  customPhotoAlbum.createFolder(image: image, currentFolder: "MirrorFlyUIkit")
                          customPhotoAlbum.saveImage(image: image, currentFolder: "MirrorFlyUIkit", assetsCollection: assetCollection)
                            cell.imageContainer.image = image
                        }
                    }
                }else {
                    if let thumbImage = message.mediaChatMessage?.mediaThumbImage {
                        ChatUtils.setThumbnail(imageContainer: cell.imageContainer ?? UIImageView(), base64String: thumbImage)
                }
                }
                
                if  (message.mediaChatMessage?.mediaDownloadStatus == .not_downloaded  || message.mediaChatMessage?.mediaDownloadStatus == .downloading || message.messageStatus == .notAcknowledged || isShowForwardView == true) {
                    cell.fwdView?.isHidden = true
                    cell.fwdIcon?.isHidden = true
                } else {
                    cell.fwdView?.isHidden = false
                    cell.fwdIcon?.isHidden = false
                }
                
                cell.downloadView.isHidden = true
                cell.progressView.isHidden = true
                cell.downoadButton.isHidden = true
                cell.progressBar?.isHidden = true
                cell.filseSize.text = ""
                cell.close.isHidden = true
            }
        }
    }
    
    func onMediaStatusFailed(error: String, messageId: String) {
        if let indexPath = chatMessages.indexPath(where: {$0.messageId == messageId}){
            print("onMediaStatusFailed \(error) \(messageId) \(indexPath)")
            let message = chatMessages[indexPath.section][indexPath.row]
            switch message.messageType {
            case .video:
                onVideoUploadFailed(message: message, indexPath: indexPath)
            case .image:
                onImageUploadFailed(message: message, indexPath: indexPath)
            case .audio:
                onAudioUploadFailed(message: message, indexPath: indexPath)
            default:
                break
            }
        }
    }
    
    func onMediaProgressChanged(message: ChatMessage, progressPercentage: Float) {
        if let indexPath = chatMessages.indexPath(where: {$0.messageId == message.messageId}){
            let progressMessage = chatMessages[indexPath.section][indexPath.row]
            if progressMessage.mediaChatMessage != nil {
                _ = messages.firstIndex(of: progressMessage)
                switch message.messageType {
                case .image :
                    updateForImageProgress(message: message, progressPercentage: progressPercentage, index: indexPath)
                case .audio :
                    updateForAudioProgress(message: message, progressPercentage: progressPercentage, index: indexPath)
                case .video :
                    updateVideoProgress(message: message, progressPercentage: progressPercentage, index: indexPath)
                default:
                    break
                }
            }
        }
    }

    
    func updateForAudioStatus(message: ChatMessage, index: IndexPath) {
        if message.isMessageSentByMe {
            if let cell = chatTableView.cellForRow(at: index) as? AudioSender {
                cell.uploadCancel?.image = UIImage(named: ImageConstant.ic_audioUploadCancel)
                cell.playIcon?.isHidden = false
                cell.uploadCancel?.isHidden = true
                cell.nicoProgressBar?.isHidden = true
                cell.nicoProgressBar?.transition(to: .determinate(percentage: 0.0))
                if  (message.mediaChatMessage?.mediaUploadStatus == .not_uploaded  || message.mediaChatMessage?.mediaUploadStatus == .uploading || message.messageStatus == .notAcknowledged || isShowForwardView == true) {
                    cell.fwdViw?.isHidden = true
                    cell.fwdBtn?.isHidden = true
                } else {
                    cell.fwdViw?.isHidden = false
                    cell.fwdBtn?.isHidden = false
                }
                uploadingMediaObjects?.enumerated().forEach({ (index,chatMessage) in
                    if chatMessage.messageId == message.messageId {
                        if (uploadingMediaObjects?.count ?? 0) > index {
                            uploadingMediaObjects?.remove(at: index)
                        }
                    }
                })
            }
        }else{
            if let cell = chatTableView.cellForRow(at: index) as? AudioReceiver {
                cell.download?.image = UIImage(named: ImageConstant.ic_download_cancel)
                cell.download?.isHidden = true
                cell.playImage?.isHidden = false
                cell.nicoProgressBar?.isHidden = true
                cell.playBtn?.isHidden = false
                cell.playBtn?.addTarget(self, action: #selector(audioAction(sender:)), for: .touchUpInside)
                cell.nicoProgressBar?.transition(to: .determinate(percentage: 0.0))
                if (message.mediaChatMessage?.mediaDownloadStatus == .not_downloaded  || message.mediaChatMessage?.mediaDownloadStatus == .downloading || message.messageStatus == .notAcknowledged || isShowForwardView == true) {
                    cell.fwdViw?.isHidden = true
                    cell.fwdBtn?.isHidden = true
                } else {
                    cell.fwdViw?.isHidden = false
                    cell.fwdBtn?.isHidden = false
                }
            }
        }
    }
    
    func updateForCarbonAudio(message: ChatMessage, index: IndexPath) {
        if message.isMessageSentByMe && message.isCarbonMessage == true {
            if let cell = chatTableView.cellForRow(at: index) as? AudioSender {
                cell.uploadCancel?.image = UIImage(named: ImageConstant.ic_audioUploadCancel)
                cell.playIcon?.isHidden = false
                cell.uploadCancel?.isHidden = true
                cell.nicoProgressBar?.isHidden = true
                cell.nicoProgressBar?.transition(to: .determinate(percentage: 0.0))
                if  (message.mediaChatMessage?.mediaDownloadStatus == .not_downloaded  || message.mediaChatMessage?.mediaDownloadStatus == .downloading || message.messageStatus == .notAcknowledged || isShowForwardView == true) {
                    cell.fwdViw?.isHidden = true
                    cell.fwdBtn?.isHidden = true
                } else {
                    cell.fwdViw?.isHidden = false
                    cell.fwdBtn?.isHidden = false
                }
            }
        }
    }
    
    func updateForImageProgress(message: ChatMessage, progressPercentage: Float, index: IndexPath) {
        if message.isMessageSentByMe {
            if let cell = chatTableView.cellForRow(at: index) as? SenderImageCell {
                if let thumbImage = message.mediaChatMessage?.mediaThumbImage {
                    ChatUtils.setThumbnail(imageContainer: cell.imageContainer ?? UIImageView(), base64String: thumbImage)
                    cell.nicoProgressBar?.isHidden = false
                    cell.nicoProgressBar?.transition(to: .indeterminate)
                    cell.retryButton?.isHidden = false
                    cell.uploadView?.isHidden = true
                    cell.progressView?.isHidden = false
                }
            }
        } else if let cell = chatTableView.cellForRow(at: index) as? ReceiverImageCell {
                cell.downloadView.isHidden = true
                if let thumbImage = message.mediaChatMessage?.mediaThumbImage {
                    ChatUtils.setThumbnail(imageContainer: cell.imageContainer ?? UIImageView(), base64String: thumbImage)
                }
                //cell.progressBar?.transition(to: .indeterminate)
                cell.progressBar?.isHidden = false
                cell.progressView.isHidden = false
                cell.downloadView?.isHidden = true
                cell.downoadButton?.isHidden = true
                cell.filseSize.text = ""
                cell.close.isHidden = false
            }
       }
    
    func updateForAudioProgress(message: ChatMessage, progressPercentage: Float, index: IndexPath) {
        print("progressPercentage", progressPercentage)
        if message.isMessageSentByMe {
            if let cell = chatTableView.cellForRow(at: index) as? AudioSender {
                cell.uploadCancel?.image = UIImage(named: ImageConstant.ic_audioUploadCancel)
                cell.uploadCancel?.isHidden = false
                cell.updateCancelButton?.isHidden = false
                cell.nicoProgressBar?.isHidden = false
                if progressPercentage == 100 || progressPercentage < 1 {
                    cell.nicoProgressBar?.transition(to: .indeterminate)
                } else {
                    cell.nicoProgressBar?.transition(to: .determinate(percentage: CGFloat((progressPercentage/100))))
                }
            }
        }else{
            if let cell = chatTableView.cellForRow(at: index) as? AudioReceiver {
                cell.download?.image = UIImage(named: ImageConstant.ic_download_cancel)
                cell.nicoProgressBar?.isHidden = false
                cell.download?.isHidden = false
                cell.playImage?.isHidden = true
                cell.playBtn?.isHidden = true
                cell.downloadButton?.isHidden = false
                if progressPercentage == 100 || progressPercentage < 1 {
                    cell.nicoProgressBar?.transition(to: .indeterminate)
                } else {
                    cell.nicoProgressBar?.transition(to: .determinate(percentage: CGFloat((progressPercentage/100))))
                }
            }
        }
    }
    
    func onMessagesClearedOrDeleted(messageIds: Array<String>) {
        
    }
    
    func onMessagesDeletedforEveryone(messageIds: Array<String>) {
        
    }
    
    func showOrUpdateOrCancelNotification() {
        
    }
    
    func onMessagesCleared(toJid: String) {
        
    }
    
    func setOrUpdateFavourite(messageId: String, favourite: Bool, removeAllFavourite: Bool) {
        
    }
    
}

extension Array where Element : Collection, Element.Index == Int {
    func indexPath(where predicate: (Element.Iterator.Element) -> Bool) -> IndexPath? {
        for (i, row) in  enumerated() {
            if let j = row.firstIndex(where: predicate) {
                return IndexPath(indexes: [i, j])
            }
        }
        return nil
    }
}


//MARK - Send Messages
extension ChatViewParentController {
    func sendTextMessage(message: String,jid: String?) {
        var lastSection = 0
        if  chatMessages.count == 0 {
            lastSection = ( chatTableView?.numberOfSections ?? 0)
        }else {
            lastSection = ( chatTableView?.numberOfSections ?? 0) - 1
        }
        
        //Reply Message
        var getReplyId: String = ""
        if( isReplyViewOpen) {
            getReplyId =  replyMessageId
            isReplyViewOpen = false
        }
        FlyMessenger.sendTextMessage(toJid: getProfileDetails.jid, message: message,replyMessageId: getReplyId){ [weak self] isSuccess,error,textMessage in
            if isSuccess {
              //  self.view.endEditing(true)

                if  self?.chatMessages.count == 0 {

                    if let message = textMessage {
                        self?.addNewGroupedMessage(messages: [message])
                    }


                }else{
                    if let message = textMessage {
                        self?.chatMessages[0].insert(message, at: 0)
                        self?.chatTableView?.insertRows(at: [IndexPath.init(row: 0, section: 0)], with: .right)

                        let indexPath = IndexPath(row: 0, section: 0)
                    self?.chatTableView?.scrollToRow(at: indexPath, at: .top, animated: true)
                    self?.messageTextView?.text = ""
                    self?.replyMessageId = ""
                        self?.tableViewBottomConstraint?.constant = CGFloat(chatBottomConstant)
                    self?.handleSendButton()
                        if self?.replyJid == self?.getProfileDetails.jid {
                            self?.replyMessageObj = nil
                            self?.isReplyViewOpen = false
                        }
                    }
                }
                self?.chatTableView.reloadData()
            }
        }
    }
    
    func onContact() {
        requestContactAccess()
    }
}

//MARK - Contacts Delegate
extension ChatViewParentController: ContactDelegate {
    func didSendPressed(contactDetails: ContactDetails,jid: String?) {
        
        if getUserForAdminBlock() {
            return
        }
        
        var lastSection = 0
        if  chatMessages.count == 0 {
            lastSection = ( chatTableView?.numberOfSections ?? 0)
        }else {
            lastSection = ( chatTableView?.numberOfSections ?? 0) - 1
        }
        
        print("didSendPressed \(contactDetails.contactName)  \(contactDetails.contactNumber)")
        
        FlyMessenger.sendContactMessage(toJid: getProfileDetails.jid, contactName: contactDetails.contactName, contactNumbers: contactDetails.contactNumber, replyMessageId: replyMessageId){ [weak self] isSuccess,error,message  in
            if isSuccess {
                self?.view.endEditing(true)
                if  self?.chatMessages.count == 0 {
                    self?.addNewGroupedMessage(messages: [message!])
                }else{
                    self?.chatMessages[0].insert(message!, at: 0)
                    self?.chatTableView?.beginUpdates()
                    self?.chatTableView?.insertRows(at: [IndexPath.init(row: 0, section: 0)], with: .right)
                    self?.chatTableView?.endUpdates()
                    let indexPath = IndexPath(row: 0, section: 0)
                    self?.chatTableView?.scrollToRow(at: indexPath, at: .top, animated: true)
                    self?.messageTextView?.text = ""
                    self?.replyMessageId = ""
                    self?.tableViewBottomConstraint?.constant = CGFloat(chatBottomConstant)
                    if self?.replyJid == self?.getProfileDetails.jid {
                        self?.replyMessageObj = nil
                        self?.isReplyViewOpen = false
                    }
                }
            }
        }
    }
}

//MARK - Location Delegate
extension ChatViewParentController: LocationDelegate {
    func didSendPressed(latitude: Double, longitude: Double,jid: String?) {
        
        if getUserForAdminBlock() {
            return
        }
        
        var lastSection = 0
        if  chatMessages.count == 0 {
            lastSection = ( chatTableView?.numberOfSections ?? 0)
        }else {
            lastSection = ( chatTableView?.numberOfSections ?? 0) - 1
        }
        FlyMessenger.sendLocationMessage(toJid: getProfileDetails.jid, latitude: latitude, longitude: longitude, replyMessageId: replyMessageId){ [weak self]isSuccess,error,message in
            if isSuccess {
                self?.view.endEditing(true)
                if self?.chatMessages.count == 0 {
                    self?.addNewGroupedMessage(messages: [message!])
                }else{
                    self?.chatMessages[0].insert(message!, at: 0)
                    self?.chatTableView?.insertRows(at: [IndexPath.init(row: 0, section: 0)], with: .right)
                    let indexPath = IndexPath(row: 0, section: 0)
                    self?.chatTableView?.scrollToRow(at: indexPath, at: .top, animated: true)
                    self?.messageTextView?.text = ""
                    self?.replyMessageId = ""
                    self?.tableViewBottomConstraint?.constant = CGFloat(chatBottomConstant)
                    self?.dismissKeyboard()
                    if self?.replyJid == self?.getProfileDetails.jid {
                        self?.replyMessageObj = nil
                        self?.isReplyViewOpen = false
                    }
                }
            }
        }
    }
}

extension ChatViewParentController : ConnectionEventDelegate {
    func onConnected() {
        self.getLastSeen()
        markMessagessAsRead()
        print("ChatViewParentController ConnectionEventDelegate onConnected")
    }
    func onDisconnected() {
        print("ChatViewParentController ConnectionEventDelegate onDisconnected")
    }
    
    func onConnectionNotAuthorized() {
        print("ChatViewParentController ConnectionEventDelegate onConnectionNotAuthorized")
    }
}

extension ChatViewParentController : ProfileEventsDelegate {
    func userCameOnline(for jid: String) {
        print("ChatViewParentController ProfileEventsDelegate userCameOnline \(jid)")
        if jid ==  getProfileDetails.jid {
            lastSeenLabel.text = online.localized
        }
    }
    
    func userWentOffline(for jid: String) {
        print("ChatViewParentController ProfileEventsDelegate userWentOffline \(jid)")
        if jid ==  getProfileDetails.jid {
           setLastSeen(lastSeenTime: "0")
        }
    }
    
    func userProfileFetched(for jid: String, profileDetails: ProfileDetails?) {
        
    }
    
    func myProfileUpdated() {
        
    }
    
    func usersProfilesFetched() {
        if let profile = ChatManager.profileDetaisFor(jid : getProfileDetails.jid) {
            self.getProfileDetails = profile
            setProfile()
            checkForUserBlocked()
            getLastSeen()
        }
        if isReplyViewOpen {
            if let replyMessageUserJid = replyMessageObj?.senderUserJid, let profileDetails = contactManager.getUserProfileDetails(for: replyMessageUserJid){
                chatTextViewXib?.titleLabel?.text = (replyMessageObj?.isMessageSentByMe ?? false) ? "You" : getUserName(jid: replyMessageUserJid, name: profileDetails.name, nickName: profileDetails.nickName, contactType: profileDetails.contactType)
            }
        }
        if getProfileDetails.profileChatType == .groupChat{
            getMessages()
        }
    }
    
    func blockedThisUser(jid: String) {
        
    }
    
    func unblockedThisUser(jid: String) {
        
    }
    
    func usersIBlockedListFetched(jidList: [String]) {
        
    }
    
    func usersBlockedMeListFetched(jidList: [String]) {
        
    }
    
    func userUpdatedTheirProfile(for jid: String, profileDetails: ProfileDetails) {
        print("userUpdatedTheirProfile \(jid)")
        let profile = ["jid": profileDetails.jid, "name": profileDetails.name, "image": profileDetails.image, "status": profileDetails.status]
        NotificationCenter.default.post(name: Notification.Name(FlyConstants.contactSyncState), object: nil, userInfo: profile as [AnyHashable : Any])
        if jid ==  getProfileDetails.jid {
            getProfileDetails = profileDetails
            setProfile()
        }
    }
    
    func userBlockedMe(jid: String) {
        
    }
    
    func userUnBlockedMe(jid: String) {
        
    }
    
    func hideUserLastSeen() {
        
    }
    
    func getUserLastSeen() {
        
    }
    
    func userDeletedTheirProfile(for jid : String , profileDetails:ProfileDetails){
        if getProfileDetails.jid == jid{
            getProfileDetails = profileDetails
            setProfile()
            lastSeenLabel.text = emptyString()
            lastSeenLabel.isHidden = true
        }
        if isReplyViewOpen && (replyMessageObj?.senderUserJid == jid) {
            chatTextViewXib?.titleLabel?.text = (replyMessageObj?.isMessageSentByMe ?? false) ? "You" : getUserName(jid: jid, name: profileDetails.name, nickName: profileDetails.nickName, contactType: profileDetails.contactType)
        }
        if getProfileDetails.profileChatType == .groupChat{
            getMessages()
            if let index = groupMembers.firstIndex(where: { participant in
                participant.memberJid == jid
            }){
                groupMembers.remove(at: index)
                setGroupMemberInHeader()
            }
        }
        
    }
}

//MARK - Selecting Contact will show Contact Picker
extension ChatViewParentController: CNContactPickerDelegate {
    func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func setupCustomAppearance() {
        UINavigationBar.appearance().tintColor = UIColor.white
        UINavigationBar.appearance().barTintColor = UIColor(red: 175.0/255.0, green: 22.0/255.0, blue: 28.0/255.0, alpha: 1.0)
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        UINavigationBar.appearance().barStyle = .black
    }
    
    func setupDefaultAppearance() {
        UINavigationBar.appearance().tintColor = nil
        UINavigationBar.appearance().barTintColor = nil
        UINavigationBar.appearance().titleTextAttributes = nil
        UINavigationBar.appearance().barStyle = .default
    }
    
    func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
    }
    
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contactProperty: CNContactProperty) {
    }
    
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        picker.dismiss(animated: true, completion: nil)
        
        guard let contactName = CNContactFormatter.string(from: contact, style: .fullName) else {
            return
        }
        contactNumber = []
        contactStatus = []
        contactLabel = []
        for number in contact.phoneNumbers {
            guard let mobileNumber = number.value.value(forKey: "digits") as? String else {
                return
            }
          
            if number.label != nil {
                if let label : String? = CNLabeledValue<NSString>.localizedString(forLabel: number.label!){
                    contactLabel.append(label ?? "")
                } else {
                    contactLabel.append("")
                }
            } else {
                contactLabel.append("")
            }
            
            contactNumber.append(mobileNumber)
            contactStatus.append(contactSelect)
        }
        var imageData : Data?
        if contact.imageDataAvailable {
            imageData = contact.imageData
        }
        
        if contactNumber.count > 0 {
            contactDetails = [ContactDetails.init(contactName: contactName, contactNumber: contactNumber, contactLabel: contactLabel, status:  contactStatus, imageData: imageData)]
            performSegue(withIdentifier: Identifiers.chatScreenToContact, sender: nil)
        }
        else {
            AppAlert.shared.showToast(message: noContactNumberAlert.localized)
        }
    }
}

//MARK : - Contact Permission
extension ChatViewParentController {
    func requestContactAccess()  {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized:
            showContactPicker()
        case .denied:
            showSettingsAlertForContacts()
        case .restricted, .notDetermined:
            CNContactStore().requestAccess(for: .contacts) { [weak self] granted, error in
                if granted {
                    self?.showContactPicker()
                }
            }
        }
    }
    
    func showSettingsAlertForContacts() {
        let alert = UIAlertController(title: nil, message: contactDenyAlert.localized, preferredStyle: .alert)
        if
            let settings = URL(string: UIApplication.openSettingsURLString),
            UIApplication.shared.canOpenURL(settings) {
            alert.addAction(UIAlertAction(title: okButton.localized, style: .default) { action in
                UIApplication.shared.open(settings)
            })
        }
        alert.addAction(UIAlertAction(title: cancel.localized, style: .cancel) { action in
            
        })
        present(alert, animated: true)
    }
    
    func showContactPicker() {
        DispatchQueue.main.async {  [weak self] in
            let contactPicker = CNContactPickerViewController()
            self?.setupDefaultAppearance()
            contactPicker.delegate = self
            contactPicker.displayedPropertyKeys = [CNContactPhoneNumbersKey]
            self?.present(contactPicker, animated: true)
        }
    }
}
//MARK: Video
extension ChatViewParentController {
    
    func sendVideoMessage (videoDetail: ImageData,jid: String?, completionHandler :  @escaping (ChatMessage) -> Void) {
        selectedIndexs.removeAll()
        let tempReplyMessageId = replyMessageId
        view.endEditing(true)
        loadVideoData(phAsset: videoDetail.videoUrl!, slowMotionVideoUrl: videoDetail.slowMotionVideoUrl) { [weak self] videoData in
            guard let videoData = videoData else {
                return
            }
            let videoName  = FlyConstants.video + FlyUtils.generateUniqueId() + MessageExtension.video.rawValue
            if let videoLocalPath  = FlyUtils.saveInDirectory(with: videoData , fileName: videoName, messageType: .video)?.0 {
                FlyMessenger.sendVideoMessage(toJid: self?.getProfileDetails.jid ?? "", videoFileName: videoName, videoFileUrl: videoLocalPath, localFilePath: videoLocalPath, videoCaption: videoDetail.caption, replyMessageId: tempReplyMessageId){ isSuccess,error,message in
                    if let chatMessage = message {
                        chatMessage.mediaChatMessage?.mediaUploadStatus = .not_uploaded
                        chatMessage.mediaChatMessage?.mediaCaptionText = videoDetail.caption ?? ""
                        if NetworkReachability.shared.isConnected {
                            if self?.sendMediaMessages?.filter({$0.messageId == chatMessage.messageId}).count == 0 {
                                self?.sendMediaMessages?.append(chatMessage)
                            }
                        }
                        DispatchQueue.main.async {  [weak self] in
                            if let chatMsg = self?.chatMessages {
                                if chatMsg.count > 0 {
                                    self?.chatMessages[0].insert(chatMessage, at: 0)
                                }
                                else {
                                    var chatArray = [ChatMessage]()
                                    chatArray.append(chatMessage)
                                    self?.chatMessages.append(chatArray)
                                }
                            }
                            self?.chatTableView.reloadData()
                            self?.tableViewBottomConstraint?.constant = CGFloat(chatBottomConstant)
//                            if let indexPath = self?.chatMessages.indexPath(where: {$0.messageId == chatMessage.messageId}) {
//                                if let cell = self?.chatTableView.cellForRow(at: indexPath) as? ChatViewVideoOutgoingCell {
//                                    cell.uploadView.isHidden = true
//                                    cell.progressView.isHidden = false
//                                    cell.progressLoader.transition(to: .indeterminate)
//                                }
//                            }
                     }
                        if self?.replyJid == self?.getProfileDetails.jid {
                            self?.replyMessageObj = nil
                            self?.isReplyViewOpen = false
                        }
                        DispatchQueue.main.async {
                            self?.chatTableView.reloadData()
                        }
                        self?.uploadMediaQueue?.append(chatMessage);
                        completionHandler(chatMessage)
                    }
                }
            }
        }
    }
    
    func loadVideoData(phAsset: PHAsset, slowMotionVideoUrl : URL? ,completion: @escaping (Data?)->()) {
        guard phAsset.mediaType == .video else {
            return completion(nil)
        }
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        PHCachingImageManager().requestAVAsset(forVideo: phAsset, options: options) { (avAsset, _, _) in
            if let composition =  avAsset as? AVComposition {
                if let tempUrl = slowMotionVideoUrl {
                    var videoData: Data?
                    do {
                        videoData = try Data(contentsOf: tempUrl)
                    } catch {
                        fatalError()
                    }
                    completion(videoData)
                }
            } else {
                guard let avUrlAsset = avAsset as? AVURLAsset else {
                    return
                }
                var videoData: Data?
                do {
                    videoData = try Data(contentsOf: avUrlAsset.url)
                } catch {
                    fatalError()
                }
                completion(videoData)
            }
        }
    }
    
    @objc func videoDownload(sender: UIButton){
        let row = sender.tag % 1000
        let section = sender.tag / 1000
        let chatMessage = chatMessages[section][row]
        if NetworkReachability.shared.isConnected {
            if chatMessage.mediaChatMessage?.mediaDownloadStatus == .not_downloaded {
                if let indexPath = chatMessages.indexPath(where: {$0.messageId == chatMessage.messageId}) {
                    if let cell = chatTableView.cellForRow(at: indexPath) as? ChatViewVideoIncomingCell {
                        cell.playButton.isHidden = true
                        cell.downloadView.isHidden = true
                        cell.downloadButton.isHidden = true
                        cell.progressView.isHidden = false
                        cell.progressLoader?.isHidden = false
                        cell.fileSizeLabel.isHidden = false
                        cell.progressLoader?.transition(to: .determinate(percentage: 0.0))
                        cell.progressLoader?.transition(to: .indeterminate)
                    }
                }
                chatMessage.mediaChatMessage?.mediaDownloadStatus = .downloading
                FlyMessenger.downloadMediaRetry(message: chatMessage) { (success, error, message) in
                    print("videoDownload \(success) \(error)")
                }
            }
        }
        else {
            AppAlert.shared.showToast(message: ErrorMessage.noInternet)
        }
        
    }
    
    @objc func retryVideoUpload(sender: UIButton){
        let row = sender.tag % 1000
        let section = sender.tag / 1000
        let chatMessage = chatMessages[section][row]
        print("retryVideoUpload A status \(chatMessage.mediaChatMessage?.mediaUploadStatus) \(chatMessage.mediaChatMessage?.mediaFileUrl)")
        if NetworkReachability.shared.isConnected {
            if let indexPath = chatMessages.indexPath(where: {$0.messageId == chatMessage.messageId}) {
                if let cell = chatTableView.cellForRow(at: indexPath) as? ChatViewVideoOutgoingCell {
                    chatMessages[section][row].mediaChatMessage?.mediaUploadStatus = .uploading
                    cell.playButton.isHidden = true
                    cell.uploadView.isHidden = true
                    cell.retryButton?.isHidden = true
                    cell.progressView.isHidden = false
                    cell.progressLoader.isHidden = false
                    cell.progressLoader.transition(to: .indeterminate)
                    FlyMessenger.uploadMediaRetry(message: chatMessage) { (success, error, message) in
                        print("retryVideoUpload \(success) \(error)")
                    }
                }
            }
        } else {
            AppAlert.shared.showToast(message: ErrorMessage.noInternet)
        }
        
    }
    
    @objc func cancelVideoUpload(sender: UIButton){
        print("cancelVideoUpload")
        let row = sender.tag % 1000
        let section = sender.tag / 1000
        let message = chatMessages[section][row]
        FlyMessenger.cancelMediaUploadOrDownload(message: message) { [weak self] isSuccess in
            if let indexPath = self?.chatMessages.indexPath(where: {$0.messageId == message.messageId}) {
                if let cell = self?.chatTableView.cellForRow(at: indexPath) as? ChatViewVideoOutgoingCell {
                    self?.chatMessages[section][row].mediaChatMessage?.mediaUploadStatus = .not_uploaded
                    cell.progressView.isHidden = true
                    cell.retryLabel.isHidden = false
                    cell.retryButton?.isHidden = false
                    cell.uploadView.isHidden = false
                    cell.progressLoader.transition(to: .determinate(percentage: 0.0))
                }
                
            }
        }
    }
    
    @objc func cancelVideoDownload(sender : UIButton){
        print("cancelVideoDownload")
        let row = sender.tag % 1000
        let section = sender.tag / 1000
        let message = chatMessages[section][row]
        FlyMessenger.cancelMediaUploadOrDownload(message: message) { [weak self] isSuccess in
            DispatchQueue.main.async {
                if let indexPath = self?.chatMessages.indexPath(where: {$0.messageId == message.messageId}) {
                    if let cell = self?.chatTableView.cellForRow(at: indexPath) as? ChatViewVideoIncomingCell {
                        cell.progressView.isHidden = true
                        cell.playButton.isHidden = true
                        cell.downloadView.isHidden = false
                        cell.downloadButton.isHidden = false
                        cell.fileSizeLabel.isHidden = false
                    }
                }
            }
        }
    }
    
    @objc func videoGestureAction(sender: UIButton){
        let row = sender.tag % 1000
        let section = sender.tag / 1000
        let message = chatMessages[section][row]
        let videoUrl = URL(fileURLWithPath: message.mediaChatMessage!.mediaLocalStoragePath)
        print("videoGestureAction B \(videoUrl)")
        playVideo(view: self, asset: videoUrl)
    }
    
    @objc func playVideoGestureAction(sender : UIButton) {
        view.endEditing(true)
        let row = sender.tag % 1000
        let section = sender.tag / 1000
        let message = chatMessages[section][row]
        if let indexPath = chatMessages.indexPath(where: {$0.messageId == message.messageId}) {
            let message = chatMessages[indexPath.section][indexPath.row]
            let videoUrl = URL(fileURLWithPath: message.mediaChatMessage?.mediaLocalStoragePath ?? "")
            playVideo(view: self, asset: videoUrl)
        }
    }
    
    func playVideo (view:UIViewController, asset:URL) {
        
        DispatchQueue.main.async {
            let player = AVPlayer(url: asset)
            let playerViewController = AVPlayerViewController()
            playerViewController.player = player
            view.present(playerViewController, animated: true) {
                playerViewController.player!.play()
            }
        }
    }
    
    func updateVideoProgress(message: ChatMessage, progressPercentage: Float, index: IndexPath) {
        DispatchQueue.main.async { [weak self] in
            print("uploadingProgress ABC \(progressPercentage)")
            if message.isMessageSentByMe {
                if let cell = self?.chatTableView.cellForRow(at: index) as? ChatViewVideoOutgoingCell {
                    self?.chatMessages[index.section][index.row].mediaChatMessage?.mediaUploadStatus = .uploading
                    if (message.mediaChatMessage?.mediaThumbImage) != nil {
                        if let thumImage = message.mediaChatMessage?.mediaThumbImage {
                            ChatUtils.setThumbnail(imageContainer: cell.imageContainer, base64String: thumImage)
                        }
                        print("updateVideoProgress  progressPercentage \(progressPercentage)")
                        cell.progressLoader.isHidden = false
                        cell.progressView.isHidden = false
                        cell.progressLoader?.transition(to: .determinate(percentage: CGFloat(progressPercentage/100)))
                        if progressPercentage == 100 {
                            cell.progressLoader.transition(to: .indeterminate)
                        }

                    }
                    cell.uploadView.isHidden = true
                    cell.playButton.isHidden = true
                    cell.retryButton?.isHidden = true
                }
            }else {
                print("updateVideoProgress else \(progressPercentage)")
                if let cell = self?.chatTableView.cellForRow(at: index) as? ChatViewVideoIncomingCell {
                    cell.downloadView.isHidden = true
                    self?.chatMessages[index.section][index.row].mediaChatMessage?.mediaDownloadStatus = .downloading
                    if (message.mediaChatMessage?.mediaThumbImage) != nil {
                        if let thumImage = message.mediaChatMessage?.mediaThumbImage {
                            ChatUtils.setThumbnail(imageContainer: cell.imageContainer, base64String: thumImage)
                        }
                        let progrss = message.mediaChatMessage?.mediaProgressStatus ?? 0
                        cell.progressLoader?.transition(to: .determinate(percentage: CGFloat(progressPercentage/100)))
                        if progressPercentage == 100 {
                            cell.progressLoader?.transition(to: .indeterminate)
                        }
                        cell.progressLoader?.isHidden = progrss < 100 ? false : true
                        cell.progressView.isHidden = progrss < 100 ? false : true
                        cell.playButton.isHidden = true
                        cell.downloadButton.isHidden = true
                    }
                    
                }
            }
        }
    }
    
    func updateCarbonVideo(message: ChatMessage, index: IndexPath) {
        DispatchQueue.main.async { [weak self] in
            if message.isMessageSentByMe && message.isCarbonMessage == true {
                print("updateVideoStatus message.isMessageSentByMe")
                if let cell = self?.chatTableView.cellForRow(at: index) as? ChatViewVideoIncomingCell {
                    self?.chatMessages[index.section][index.row].mediaChatMessage?.mediaDownloadStatus = .downloaded
                    if let thumImage = message.mediaChatMessage?.mediaThumbImage {
                        ChatUtils.setThumbnail(imageContainer: cell.imageContainer, base64String: thumImage)
                    }
                    cell.progressLoader?.transition(to: .indeterminate)
                    cell.progressLoader?.isHidden = true
                    cell.progressView.isHidden = true
                    cell.playButton.isHidden = false
                    
                    if (message.mediaChatMessage?.mediaDownloadStatus == .not_downloaded  || message.mediaChatMessage?.mediaDownloadStatus == .downloading || message.messageStatus == .notAcknowledged
                        || self?.isShowForwardView == true) {
                        cell.quickForwardView?.isHidden = true
                        cell.quickForwardButton?.isHidden = true
                    } else {
                        cell.quickForwardView?.isHidden = false
                        cell.quickForwardButton?.isHidden = false
                    }
                }
            }
        }
    }
    
    func updateVideoStatus(message: ChatMessage, index: IndexPath) {
        DispatchQueue.main.async { [weak self] in
            if message.isMessageSentByMe {
                print("updateVideoStatus message.isMessageSentByMe")
                if let cell = self?.chatTableView.cellForRow(at: index) as? ChatViewVideoOutgoingCell {
                    self?.chatMessages[index.section][index.row].mediaChatMessage?.mediaUploadStatus = .uploaded
                    if let thumImage = message.mediaChatMessage?.mediaThumbImage {
                        ChatUtils.setThumbnail(imageContainer: cell.imageContainer, base64String: thumImage)
                    }
                    cell.progressLoader?.transition(to: .indeterminate)
                    cell.progressLoader.isHidden = true
                    cell.progressView.isHidden = true
                    cell.retryButton?.isHidden = true
                    cell.uploadView.isHidden = true
                    cell.playButton.isHidden = false
                    
                    if (message.mediaChatMessage?.mediaUploadStatus == .not_uploaded  || message.mediaChatMessage?.mediaUploadStatus == .uploading || message.messageStatus == .notAcknowledged
                        || self?.isShowForwardView == true) {
                            cell.quickfwdView?.isHidden = true
                            cell.quickFwdBtn?.isHidden = true
                        } else {
                            cell.quickfwdView?.isHidden = false
                            cell.quickFwdBtn?.isHidden = false
                        }
                    self?.updateVideoMessageStatus(statusImage: cell.msgStatus, messageStatus: message.messageStatus)
                }
            }else {
                print("updateVideoStatus else")
                if let cell = self?.chatTableView.cellForRow(at: index) as? ChatViewVideoIncomingCell {
                    self?.chatMessages[index.section][index.row].mediaChatMessage?.mediaDownloadStatus = .downloaded
                    if let thumImage = message.mediaChatMessage?.mediaThumbImage {
                        ChatUtils.setThumbnail(imageContainer: cell.imageContainer, base64String: thumImage)
                    }
                    cell.progressLoader?.transition(to: .indeterminate)
                    cell.progressLoader?.isHidden = true
                    cell.progressView.isHidden = true
                    cell.downloadView.isHidden = true
                    cell.downloadButton.isHidden = true
                    cell.playButton.isHidden = false
                    if  message.mediaChatMessage?.mediaDownloadStatus == .not_downloaded  || message.mediaChatMessage?.mediaDownloadStatus == .downloading || message.messageStatus == .notAcknowledged || self?.isShowForwardView == true {
                        cell.quickForwardView?.isHidden = true
                        cell.quickForwardButton?.isHidden = true
                    } else {
                        cell.quickForwardView?.isHidden = false
                        cell.quickForwardButton?.isHidden = false
                    }
                }
            }
        }
    }
    
    func onVideoUploadFailed(message : ChatMessage, indexPath : IndexPath) {
        DispatchQueue.main.async { [weak self] in
            if message.isMessageSentByMe {
                if let cell = self?.chatTableView.cellForRow(at: indexPath) as? ChatViewVideoOutgoingCell {
                    self?.chatMessages[indexPath.section][indexPath.row].mediaChatMessage?.mediaUploadStatus = .not_uploaded
                    if let thumImage = message.mediaChatMessage?.mediaThumbImage {
                        ChatUtils.setThumbnail(imageContainer: cell.imageContainer, base64String: thumImage)
                    }
                    cell.progressLoader.transition(to: .determinate(percentage: 0.0))
                    cell.progressLoader.isHidden = true
                    cell.progressView.isHidden = true
                    cell.playButton.isHidden = true
                    
                    cell.retryLabel.isHidden = false
                    cell.retryButton?.isHidden = false
                    cell.uploadView.isHidden = false
                    cell.uploadImage.isHidden = false
                    self?.updateVideoMessageStatus(statusImage: cell.msgStatus, messageStatus: message.messageStatus)
                }
            }else {
                if let cell = self?.chatTableView.cellForRow(at: indexPath) as? ChatViewVideoIncomingCell {
                    self?.chatMessages[indexPath.section][indexPath.row].mediaChatMessage?.mediaDownloadStatus = .not_downloaded
                    if let thumImage = message.mediaChatMessage?.mediaThumbImage {
                        ChatUtils.setThumbnail(imageContainer: cell.imageContainer, base64String: thumImage)
                    }
                    cell.progressView.isHidden = true
                    cell.progressLoader?.transition(to: .determinate(percentage: 0.0))
                    cell.downloadView.isHidden = false
                    cell.downloadButton.isHidden = false
                    cell.fileSizeLabel.isHidden = false
                    cell.playButton.isHidden = true
                }
            }
            
        }
    }
    
    func onImageUploadFailed(message : ChatMessage, indexPath : IndexPath) {
        DispatchQueue.main.async { [weak self] in
            if message.isMessageSentByMe {
                if let cell = self?.chatTableView.cellForRow(at: indexPath) as? SenderImageCell {
                    let localPath = message.mediaChatMessage?.mediaLocalStoragePath ?? ""
                    if let thumImage = message.mediaChatMessage?.mediaThumbImage {
                        ChatUtils.setThumbnail(imageContainer: cell.imageContainer ?? UIImageView(), base64String: thumImage)
                    }
                    cell.nicoProgressBar?.isHidden = true
                    cell.progressView?.isHidden = true
                    
                    cell.retryLab?.isHidden = false
                    cell.uploadView?.isHidden = false
                    self?.sendMediaMessages?.enumerated().forEach({ (index,chatMessage) in
                        if chatMessage.messageId == message.messageId {
                            self?.sendMediaMessages?.remove(at: index)
                        }
                    })
                    self?.updateVideoMessageStatus(statusImage: cell.msgStatus ?? UIImageView(), messageStatus: message.messageStatus)
                }
            } else {
                if let cell = self?.chatTableView.cellForRow(at: indexPath) as? ReceiverImageCell {
                    if let localPath = message.mediaChatMessage?.mediaFileName {
                        let directoryURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                        let folderPath: URL = directoryURL.appendingPathComponent("FlyMedia/Image", isDirectory: true)
                        let fileURL: URL = folderPath.appendingPathComponent(localPath)
                        if FileManager.default.fileExists(atPath: fileURL.relativePath) {
                            let data = NSData(contentsOf: fileURL)
                            let image = UIImage(data: data! as Data)
                            cell.imageContainer.image = image
                        }
                    } else {
                        if let thumbImage = message.mediaChatMessage?.mediaThumbImage {
                            ChatUtils.setThumbnail(imageContainer: cell.imageContainer ?? UIImageView(), base64String: thumbImage)
                        }
                    }
                    cell.progressBar?.isHidden = true
                    cell.progressView.isHidden = true
                    cell.downloadView.isHidden = false
                    if self?.receivedMediaMessages?.count ?? 0 > 0 {
                        if self?.receivedMediaMessages?.filter({$0.messageId == message.messageId}).count ?? 0 > 0 {
                            self?.receivedMediaMessages?.enumerated().forEach({ (index,chatMessage) in
                                if chatMessage.messageId == message.messageId {
                                    self?.receivedMediaMessages?.remove(at: index)
                                }
                            })
                        }
                    }
                    if let fileSiz = message.mediaChatMessage?.mediaFileSize{
                        cell.filseSize.text = "\(fileSiz.byteSize)"
                    } else {
                        cell.filseSize.text = ""
                    }
                }
            }
        }
    }
    
    func onAudioUploadFailed(message : ChatMessage, indexPath : IndexPath) {
        DispatchQueue.main.async { [weak self] in
            if message.isMessageSentByMe {
                if let cell = self?.chatTableView.cellForRow(at: indexPath) as? AudioSender {
                    
                    cell.stopUpload()
                    self?.updateVideoMessageStatus(statusImage: cell.status ?? UIImageView(), messageStatus: message.messageStatus)
                }
            } else {
                if let cell = self?.chatTableView.cellForRow(at: indexPath) as? AudioReceiver {
                    cell.stopDownload()
                }
            }
        }
    }
    
    func updateVideoMessageStatus(statusImage : UIImageView, messageStatus : MessageStatus) {
        switch messageStatus {
        case .notAcknowledged:
            statusImage.image = UIImage.init(named: ImageConstant.ic_hour)
            statusImage.accessibilityLabel = notAcknowledged.localized
        break
        case .sent:
            statusImage.image = UIImage.init(named: ImageConstant.ic_hour)
            statusImage.accessibilityLabel = sent.localized
            break
        case .acknowledged:
            statusImage.image = UIImage.init(named: ImageConstant.ic_sent)
            statusImage.accessibilityLabel = acknowledged.localized
            break
        case .delivered:
            statusImage.image = UIImage.init(named: ImageConstant.ic_delivered)
            statusImage.accessibilityLabel = delivered.localized
            break
        case .seen:
            statusImage.image = UIImage.init(named: ImageConstant.ic_seen)
            statusImage.accessibilityLabel = seen.localized
            break
        case .received:
            statusImage.image = UIImage.init(named: ImageConstant.ic_delivered)
            statusImage.accessibilityLabel = delivered.localized
            break
        default:
            statusImage.image = UIImage.init(named: ImageConstant.ic_hour)
            statusImage.accessibilityLabel = notAcknowledged.localized
            break
        }
    }
}
extension ChatViewParentController {
    
    @objc func makeCall(_ sender : UIButton){
        var callType = CallType.Audio
        if sender.tag == 102 {
            callType = .Video
        }
        if getProfileDetails.profileChatType == .groupChat {
            let storyboard = UIStoryboard.init(name: Storyboards.main, bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: Identifiers.contactViewController) as! ContactViewController
            controller.modalPresentationStyle = .fullScreen
            controller.makeCall = true
            controller.isMultiSelect = true
            controller.callType = callType
            controller.hideNavigationbar = true
            controller.groupJid = getProfileDetails.jid
            self.navigationController?.pushViewController(controller, animated: true)
        } else if getProfileDetails.profileChatType == .singleChat{
            if getProfileDetails.contactType != .deleted{
                RootViewController.sharedInstance.callViewController?.makeCall(usersList: [getProfileDetails.jid], callType: callType)
            }
        }
    }
}
// Typing Delegate
extension ChatViewParentController : TypingStatusDelegate {
    func onChatTypingStatus(userJid: String, status: TypingStatus) {
        print("ChatViewParentController onChatTypingStatus \(status) userJid \(userJid)")
        DispatchQueue.main.async { [weak self] in
            if userJid == self?.getProfileDetails.jid{
                if status == TypingStatus.composing {
                    self?.lastSeenLabel.text = typing.localized
                } else if status == TypingStatus.gone {
                    self?.getLastSeen()
                }
            }
        }
    }
    
    func onGroupTypingStatus(groupJid: String, groupUserJid: String, status: TypingStatus) {
        DispatchQueue.main.async { [weak self] in
            if groupJid == self?.getProfileDetails.jid && groupUserJid != FlyDefaults.myJid {
                if status == TypingStatus.composing {
                    let user = self?.groupMembers.filter({$0.memberJid == groupUserJid}).first
                    let name = getUserName(jid: user?.profileDetail?.jid ?? "", name: user?.profileDetail?.name ?? "", nickName: user?.profileDetail?.nickName ?? "", contactType: user?.profileDetail?.contactType ?? .unknown)
                    self?.groupMemberLable.text = name + " " + isText + " " + typing.localized
                } else if status == TypingStatus.gone {
                    self?.setGroupMemberInHeader()
                }
            }
        }
    }
}

extension ChatViewParentController : GroupEventsDelegate {
    func didAddNewMemeberToGroup(groupJid: String, newMemberJid: String, addedByMemberJid: String) {
        getGroupMember()
        checkMemberOfGroup()
    }
    
    func didRemoveMemberFromGroup(groupJid: String, removedMemberJid: String, removedByMemberJid: String) {
        checkMemberOfGroup()
    }
    
    func didFetchGroupProfile(groupJid: String) {
        getGroupMember()
        checkMemberOfGroup()
    }
    
    func didUpdateGroupProfile(groupJid: String) {
        let group = GroupManager.shared.getAGroupFromLocal(groupJid: groupJid)
        DispatchQueue.main.async { [weak self] in
            self?.getProfileDetails.nickName = (group?.name ?? group?.nickName) ?? ""
            self?.getProfileDetails.name = (group?.name ?? group?.nickName) ?? ""
            self?.getProfileDetails.image = group?.image ?? ""
            self?.setProfile()
        }
    }
    
    func didMakeMemberAsAdmin(groupJid: String, newAdminMemberJid: String, madeByMemberJid: String) {
        
    }
    
    func didRemoveMemberFromAdmin(groupJid: String, removedAdminMemberJid: String, removedByMemberJid: String) {
        
    }
    
    func didDeleteGroupLocally(groupJid: String) {
        
    }
    
    func didLeftFromGroup(groupJid: String, leftUserJid: String) {
        checkMemberOfGroup()
    }
    
    func didCreateGroup(groupJid: String) {
        getGroupMember()
        checkMemberOfGroup()
    }
    
    func didFetchGroups(groups: [ProfileDetails]) {
        
    }
    
    func didFetchGroupMembers(groupJid: String) {
        getGroupMember()
        checkMemberOfGroup()
    }
    
    func didReceiveGroupNotificationMessage(message: ChatMessage) {
        onMessageReceived(message: message, chatJid: message.chatUserJid)
    }
    
}

//MARK : Group
extension ChatViewParentController {
    
    func checkMemberOfGroup() {
        if getProfileDetails.profileChatType == .groupChat {
            let result = isParticipantExist()
            print("ChatViewParentController Group isExist \(result.doesExist) \(result.message)")
            chatTextViewXib?.cannotSendMessageView?.isHidden = result.doesExist ? true : false
            disableForBlocking(disable: result.doesExist ? false : true)
            GroupManager.shared.getGroupMemebersFromLocal(groupJid: getProfileDetails.jid)
        }
    }
    
    func isParticipantExist() -> (doesExist : Bool, message : String) {
       return GroupManager.shared.isParticiapntExistingIn(groupJid: getProfileDetails.jid, participantJid: FlyDefaults.myJid)
    }
    
    func getGroupMember() {
        print("getGrouMember")
        groupMembers = [GroupParticipantDetail]()
        groupMembers =  GroupManager.shared.getGroupMemebersFromLocal(groupJid: getProfileDetails.jid).participantDetailArray.filter({$0.memberJid != FlyDefaults.myJid})
        print("getGrouMember \(groupMembers.count)")
        setGroupMemberInHeader()
    }
    
    func getParticipants() {
        GroupManager.shared.getParticipants(groupJID: getProfileDetails.jid)
    }
    
    func setGroupMemberInHeader() {
        DispatchQueue.main.async { [weak self] in
            var memberString = ""
            let members = self?.groupMembers ?? [GroupParticipantDetail]()
            for (index, member) in members.enumerated() {
                let profileDetail = member.profileDetail
                let participantName = getUserName(jid : profileDetail?.jid ?? "" ,name: profileDetail?.name ?? "", nickName: profileDetail?.nickName ?? "", contactType: profileDetail?.contactType ?? .live)
                if index != (members.count - 1) {
                    memberString = memberString + (participantName) + ", "
                } else {
                    memberString = memberString + (participantName) + " "
                }
            }
            self?.groupMemberLable.type = .continuous
            self?.groupMemberLable.animationCurve = .linear
            self?.groupMemberLable.speed = .duration(45)
            self?.groupMemberLable.text = memberString
            
            print("setGroupMemberInHeader \(memberString)")
        }

    }
    
    func hideSenderNameToGroup(indexPath: IndexPath) -> Bool{
        let section = indexPath.section
        let row = indexPath.row
        let totalCount = chatMessages[section].count
        print("handleSenderNameToGroup section \(section) row \(row) totalCount \(totalCount)")
     
        
        if row < totalCount-1 && row > 0 {
            
            let currentMessage = chatMessages[section][row]
            let nextMessage = chatMessages[section][row + 1]
            let previousMessage = chatMessages[section][row - 1]
            
            let currentJid = currentMessage.senderUserJid
            let nextJid = nextMessage.senderUserJid
            let previousJid = previousMessage.senderUserJid
            
            print("handleSenderNameToGroup \(currentJid) \(nextJid) \(previousJid)")
            if !currentMessage.isMessageSentByMe {
                print("handleSenderNameToGroup \(currentMessage.messageTextContent) \(nextMessage.messageTextContent) \(previousMessage.messageTextContent)")
                if currentJid == nextJid && currentJid != previousJid {
                    return true
                }
                
                if currentJid == nextJid && currentJid == previousJid {
                    return true
                }
            }
        } else {
            let currentMessage = chatMessages[section][row]
            if row == 0 && totalCount > 1 && !currentMessage.isMessageSentByMe {
                
                let nextMessage = chatMessages[section][row + 1]
                if currentMessage.senderUserJid == nextMessage.senderUserJid {
                    return true
                }
            }
        }
        
        return false
    }
    
   
}

// handle message views
extension ChatViewParentController {
    func handleChatBubble(indexPath : IndexPath) {
        let currentMessage = chatMessages[indexPath.section][indexPath.row]
        print("handleChatBubble Section \(indexPath.section) Row \(indexPath.row) \(currentMessage.messageTextContent)")
        
    }
}

extension ChatViewParentController : RefreshBubbleImageViewDelegate {
    func refreshBubbleImageView(indexPath: IndexPath,isSelected: Bool) {
        switch isSelected {
        case true:
            if forwardMessages?.filter({$0.chatMessage.messageId == chatMessages[indexPath.section][indexPath.row].messageId}).count == 0 {
                var selectedForwardMessage = SelectedForwardMessage()
                selectedForwardMessage.isSelected = isSelected
                selectedForwardMessage.chatMessage = chatMessages[indexPath.section][indexPath.row]
                forwardMessages?.append(selectedForwardMessage)
            }
        case false:
            forwardMessages?.enumerated().forEach { (index,item) in
                if item.chatMessage.messageId == chatMessages[indexPath.section][indexPath.row].messageId {
                    forwardMessages?.remove(at: index)
                    return
                }
            }
        }
        chatTableView.reloadData()
        forwardButton?.isHidden = (forwardMessages?.count ?? 0 > 0) ? false : true
        showHideForwardView()
    }
    
    private func showHideForwardView() {
        forwardBottomView?.isHidden = (isShowForwardView == true) ? false : true
        textToolBarView?.isHidden = isShowForwardView == true ? true : false
    }
}

extension ChatViewParentController : SendSelectecUserDelegate {
    func sendSelectedUsers(selectedUsers: [Profile],completion: @escaping (() -> Void)) {
        guard let messageIds = forwardMessages?.map({$0.chatMessage.messageId}) else { return  }
        let jids = selectedUsers.map({$0.jid})
        print("Jids:",jids)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            if jids.filter({$0 == self?.getProfileDetails.jid}).count > 0 {
                self?.getMessages()
            } else {
                self?.chatTableView?.reloadData()
            }
        }
        messageTextView?.resignFirstResponder()
        forwardMessages?.removeAll()
        isShowForwardView = false
        showHideForwardView()
        DispatchQueue.main.async {
           completion()
        }
    }
}

extension ChatViewParentController: ShowMailComposeDelegate {
    func showMailComposer(mail: String){
        // Build the URL from its components
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = mail
        

        guard let url = components.url else {
            NSLog("Failed to create mailto URL")
            return
        }

        UIApplication.shared.open(url) { success in
          
        }
    }
}


// MARK Network change detecting
extension ChatViewParentController {
    func networkMonitor() {
        if !NetworkReachability.shared.isConnected {
            DispatchQueue.main.async { [weak self] in
                self?.lastSeenLabel.text = waitingForNetwork
            }
        }
        NetStatus.shared.netStatusChangeHandler = { [weak self] in
            print("networkMonitor \(NetStatus.shared.isConnected)")
            if !NetStatus.shared.isConnected {
                DispatchQueue.main.async {
                    self?.lastSeenLabel.text = waitingForNetwork
                }
            }
        }
    }
}
// MARK: Image cancel and upload methods
extension ChatViewParentController {
    @objc func cancelOrUploadImages(sender: UIButton) {
        let row = sender.tag % 1000
        let section = sender.tag / 1000
        let indexPath = IndexPath(row: row, section: section)
        let message = chatMessages[indexPath.section][indexPath.row]
        if message.isMessageSentByMe {
            if message.mediaChatMessage?.mediaUploadStatus == .uploading || sendMediaMessages?.filter({$0.messageId == message.messageId}).count ?? 0 > 0 {
                message.mediaChatMessage?.mediaUploadStatus = .not_uploaded
                chatMessages[indexPath.section][indexPath.row] = message
                sendMediaMessages?.enumerated().forEach({ (index,chatMessage) in
                    if chatMessage.messageId == message.messageId {
                        if (sendMediaMessages?.count ?? 0) > index {
                            sendMediaMessages?.remove(at: index)
                        }
                    }
                })
                if let cell = chatTableView.cellForRow(at: indexPath) as? SenderImageCell {
                    cell.sendMediaMessages = sendMediaMessages
                    cell.getCellFor(message, at: indexPath, isShowForwardView: isShowForwardView)
                }
                FlyMessenger.cancelMediaUploadOrDownload(message: message) { [weak self] isSuccess in
                    if message.messageType == .image {
                        DispatchQueue.main.async { [weak self] in
                            if let cell = self?.chatTableView.cellForRow(at: indexPath) as? SenderImageCell {
                                cell.sendMediaMessages = self?.sendMediaMessages
                                cell.getCellFor(message, at: indexPath, isShowForwardView: self?.isShowForwardView)
                            }
                        }
                    }
                }
            } else if message.mediaChatMessage?.mediaUploadStatus == .not_uploaded {
                imageUpload(sender: sender)
            } else if message.mediaChatMessage?.mediaUploadStatus == .uploaded {
                if let cell = chatTableView.cellForRow(at: indexPath) as? SenderImageCell {
                    cell.sendMediaMessages = sendMediaMessages
                    cell.getCellFor(message, at: indexPath, isShowForwardView: isShowForwardView)
                }
            }
        }
    }
    
    private func imageUpload(sender: UIButton,completion: @escaping (Bool?)->()) {
        let buttonPosition = sender.convert(CGPoint.zero, to: chatTableView)
        if let indexPath = chatTableView.indexPathForRow(at:buttonPosition) {
            let message = chatMessages[indexPath.section][indexPath.row]
            if NetworkReachability.shared.isConnected {
                print("sendMediaMessages",sendMediaMessages?.count)
                if sendMediaMessages?.filter({$0.messageId == message.messageId}).count == 0 {
                    sendMediaMessages?.append(message)
                    if let progress = message.mediaChatMessage?.mediaUploadStatus, progress == .not_uploaded {
                            message.mediaChatMessage?.mediaUploadStatus = .uploading
                            FlyMessenger.uploadMediaRetry(message: message) { (success, error, message) in
                                completion(true)
                            }
                        }
                } else {
                    sendMediaMessages?.enumerated().forEach({ (index,chatMessage) in
                        if chatMessage.messageId == message.messageId {
                            if (sendMediaMessages?.count ?? 0) > index {
                                sendMediaMessages?.remove(at: index)
                            }
                        }
                    })
                }
            } else {
                AppAlert.shared.showToast(message: ErrorMessage.noInternet)
            }
        }
    }
    
    @objc func imageUpload(sender: UIButton) {
            imageUpload(sender: sender) { isSuccess in
        }
    }
}

// MARK: Image cancel and Download methods
extension ChatViewParentController {
    @objc func cancelImageDownload(sender: UIButton) {
        let buttonPosition = sender.convert(CGPoint.zero, to: chatTableView)
        if let indexPath = chatTableView.indexPathForRow(at:buttonPosition) {
            let message = chatMessages[indexPath.section][indexPath.row]
            if message.isMessageSentByMe {
                if message.mediaChatMessage?.mediaUploadStatus == .uploading {
                message.mediaChatMessage?.mediaUploadStatus = .not_uploaded
                chatMessages[indexPath.section][indexPath.row] = message
                FlyMessenger.cancelMediaUploadOrDownload(message: message) { [weak self] isSuccess in
                    if message.messageType == .image {
                        DispatchQueue.main.async { [weak self] in
                            if let cell = self?.chatTableView.cellForRow(at: indexPath) as? SenderImageCell {
                                cell.getCellFor(message, at: indexPath, isShowForwardView: self?.isShowForwardView)
                                if self?.sendMediaMessages?.count ?? 0 > 0 {
                                    if self?.sendMediaMessages?.filter({$0.messageId == message.messageId}).count ?? 0 > 0 {
                                        self?.sendMediaMessages?.enumerated().forEach({ (index,chatMessage) in
                                            if chatMessage.messageId == message.messageId {
                                                self?.sendMediaMessages?.remove(at: index)
                                            }
                                        })
                                    }
                                }
                            }
                        }
                    }
                }
                } else {
                    if message.messageType == .image {
                        if sendMediaMessages?.count ?? 0 > 0 {
                        if sendMediaMessages?.filter({$0.messageId == message.messageId}).count ?? 0 > 0 {
                            sendMediaMessages?.enumerated().forEach({ (index,chatMessage) in
                                if chatMessage.messageId == message.messageId {
                                   sendMediaMessages?.remove(at: index)
                                }
                            })
                        }
                    }
                        DispatchQueue.main.async { [weak self] in
                            if let cell = self?.chatTableView.cellForRow(at: indexPath) as? SenderImageCell {
                                cell.sendMediaMessages = self?.sendMediaMessages
                                cell.getCellFor(message, at: indexPath, isShowForwardView: self?.isShowForwardView)
                            }
                        }
                    }
                }
            } else {
                    message.mediaChatMessage?.mediaDownloadStatus = .not_downloaded
                    FlyMessenger.cancelMediaUploadOrDownload(message: message) { [weak self] isSuccess in
                        self?.chatMessages[indexPath.section][indexPath.row] = message
                        if message.messageType == .image {
                            if self?.receivedMediaMessages?.count ?? 0 > 0 {
                                if self?.receivedMediaMessages?.filter({$0.messageId == message.messageId}).count ?? 0 > 0 {
                                    self?.receivedMediaMessages?.enumerated().forEach({ (index,chatMessage) in
                                    if chatMessage.messageId == message.messageId {
                                        self?.receivedMediaMessages?.remove(at: index)
                                    }
                                })
                            }
                        }
                        DispatchQueue.main.async {
                            if let cell = self?.chatTableView.cellForRow(at: indexPath) as? ReceiverImageCell {
                                cell.getCellFor(message, at: indexPath, isShowForwardView: self?.isShowForwardView)
                                }
                            }
                        }
                    }
                }
            }
        }
    
    @objc func imageDownload(sender: UIButton) {
        let buttonPosition = sender.convert(CGPoint.zero, to: chatTableView)
        if let indexPath = chatTableView.indexPathForRow(at:buttonPosition) {
            let message = chatMessages[indexPath.section][indexPath.row]
            if NetworkReachability.shared.isConnected {
                if message.mediaChatMessage?.mediaDownloadStatus == .not_downloaded {
                    if let cell = chatTableView.cellForRow(at: indexPath) as? ReceiverImageCell {
                        cell.progressBar?.transition(to: .indeterminate)
                        cell.progressBar?.isHidden = false
                        cell.downloadView?.isHidden = true
                        cell.progressView.isHidden = false
                        cell.close.isHidden = false
                        cell.downoadButton?.isHidden = true
                        cell.progrssButton.isHidden = false
                    }
                    if message.isCarbonMessage == true {
                        if let cell = chatTableView.cellForRow(at: indexPath) as? SenderImageCell {
                            cell.nicoProgressBar?.transition(to: .indeterminate)
                            cell.nicoProgressBar?.isHidden = false
                            cell.downloadView?.isHidden = true
                            cell.progressView?.isHidden = false
                            cell.downloadButton?.isHidden = true
                        }
                    }
                    if receivedMediaMessages?.filter({$0.messageId == message.messageId}).count == 0 {
                        receivedMediaMessages?.append(message)
                        FlyMessenger.downloadMediaRetry(message: message) { [weak self] (success, error, message) in
                            if let cell = self?.chatTableView.cellForRow(at: indexPath) as? ReceiverImageCell {
                                cell.getCellFor(message, at: indexPath, isShowForwardView: self?.isShowForwardView)
                            }
                        }
                    }
                    
                }
            } else {
                AppAlert.shared.showToast(message: ErrorMessage.noInternet)
            }
        }
    }
}


// MARK: Audio cancel and upload methods
extension ChatViewParentController {
    @objc func audioUpload(sender: UIButton) {
        audioUpload(sender: sender) { isSuccess in
        }
    }
    
    private func audioUpload(sender: UIButton,completion: @escaping (Bool?)->()) {
        let buttonPosition = sender.convert(CGPoint.zero, to: chatTableView)
        if let indexPath = chatTableView.indexPathForRow(at:buttonPosition) {
            let message = chatMessages[indexPath.section][indexPath.row]
            if NetworkReachability.shared.isConnected {
                print("count:;",uploadingMediaObjects?.filter({$0.messageId == message.messageId}).count)
                if uploadingMediaObjects?.filter({$0.messageId == message.messageId}).count == 0 {
                    uploadingMediaObjects?.insert(message, at: 0)
                    if let progress = message.mediaChatMessage?.mediaUploadStatus, progress != .uploaded {
                        DispatchQueue.main.async {
                            FlyMessenger.uploadMediaRetry(message: message) { (success, error, message) in
                                completion(true)
                            }
                        }
                    }
                }
            } else {
                AppAlert.shared.showToast(message: ErrorMessage.noInternet)
            }
        }
    }
    
    @objc func uploadCancelaudioAction(sender: UIButton) {
        isShowAudioLoadingIcon = false
        if !NetworkReachability.shared.isConnected {
            AppAlert.shared.showToast(message: ErrorMessage.checkYourInternet)
            return
        }
        let row = sender.tag % 1000
        let section = sender.tag / 1000
        let indexPath = IndexPath(row: row, section: section)
        if indexPath.section < chatMessages.count {
            let message = chatMessages[indexPath.section][indexPath.row]
            print("indexPath",indexPath)
            if message.isMessageSentByMe {
                DispatchQueue.main.async { [weak self] in
                    if message.isCarbonMessage == true {
                        if message.mediaChatMessage?.mediaDownloadStatus == .downloading {
                            if let cell = self?.chatTableView.cellForRow(at: indexPath) as? AudioSender {
                                cell.isShowAudioLoadingIcon = self?.isShowAudioLoadingIcon
                                cell.stopDownload()
                            }
                            message.mediaChatMessage?.mediaDownloadStatus = .not_downloaded
                            self?.chatMessages[indexPath.section][indexPath.row] = message
                            print("cancelIndex",message.messageId)
                            FlyMessenger.cancelMediaUploadOrDownload(message: message) { isSuccess in
                                DispatchQueue.main.async {
                                    if let cell = self?.chatTableView.cellForRow(at: indexPath) as? AudioSender {
                                        cell.isShowAudioLoadingIcon = self?.isShowAudioLoadingIcon
                                        self?.chatTableView?.reloadRows(at: [indexPath], with: .none)
                                    }
                                }
                            }
                        } else if message.mediaChatMessage?.mediaDownloadStatus == .not_downloaded {
                            if let cell = self?.chatTableView.cellForRow(at: indexPath) as? AudioSender {
                                cell.isShowAudioLoadingIcon = self?.isShowAudioLoadingIcon
                                cell.startUpload()
                            }
                            message.mediaChatMessage?.mediaDownloadStatus = .downloading
                            self?.chatMessages[indexPath.section][indexPath.row] = message
                            FlyMessenger.downloadMediaRetry(message: message) { (success, error, chatMessage) in
                                DispatchQueue.main.async {
                                    if let cell = self?.chatTableView.cellForRow(at: indexPath) as? AudioSender {
                                        cell.getCellFor(message, at: indexPath, isPlaying: self?.currenAudioIndexPath == indexPath ? self?.audioPlayer?.isPlaying ?? false : false, audioClosureCallBack: { (_) in
                                        }, isShowForwardView: self?.isShowForwardView)
                                    }
                                }
                            }
                        } else {
                            if let _ = self?.chatTableView.cellForRow(at: indexPath) as? AudioSender {
                                self?.chatTableView.reloadRows(at: [indexPath], with: .none)
                            }
                        }
                    } else {
                        if message.mediaChatMessage?.mediaUploadStatus == .uploading {
                            if let cell = self?.chatTableView.cellForRow(at: indexPath) as? AudioSender {
                                cell.isShowAudioLoadingIcon = self?.isShowAudioLoadingIcon
                                cell.stopUpload()
                            }
                            self?.uploadingMediaObjects?.enumerated().forEach({ (index,chatMessage) in
                                if chatMessage.messageId == message.messageId {
                                    if (self?.uploadingMediaObjects?.count ?? 0) > index {
                                        self?.uploadingMediaObjects?.remove(at: index)
                                    }
                                }
                            })
                            message.mediaChatMessage?.mediaUploadStatus = .not_uploaded
                            self?.chatMessages[indexPath.section][indexPath.row] = message
                            print("cancelIndex",message.messageId)
                            FlyMessenger.cancelMediaUploadOrDownload(message: message) { isSuccess in
                                if let cell = self?.chatTableView.cellForRow(at: indexPath) as? AudioSender {
                                    cell.isShowAudioLoadingIcon = self?.isShowAudioLoadingIcon
                                    self?.chatTableView?.reloadRows(at: [indexPath], with: .none)
                                }
                            }
                        } else if message.mediaChatMessage?.mediaUploadStatus == .not_uploaded {
                            if let cell = self?.chatTableView.cellForRow(at: indexPath) as? AudioSender {
                                cell.isShowAudioLoadingIcon = self?.isShowAudioLoadingIcon
                                cell.startUpload()
                            }
                            message.mediaChatMessage?.mediaUploadStatus = .uploading
                            self?.chatMessages[indexPath.section][indexPath.row] = message
                            self?.audioUpload(sender: sender) { isSuccess in
                                if let cell = self?.chatTableView.cellForRow(at: indexPath) as? AudioSender {
                                    cell.isShowAudioLoadingIcon = self?.isShowAudioLoadingIcon
                                    cell.getCellFor(message, at: indexPath, isPlaying: self?.currenAudioIndexPath == indexPath ? self?.audioPlayer?.isPlaying ?? false : false, audioClosureCallBack: { (_) in
                                    }, isShowForwardView: self?.isShowForwardView)
                                }
                            }
                        } else {
                            if let _ = self?.chatTableView.cellForRow(at: indexPath) as? AudioSender {
                                self?.chatTableView.reloadRows(at: [indexPath], with: .none)
                            }
                        }
                    }
                }
            } else {
                DispatchQueue.main.async { [weak self] in
                    if message.mediaChatMessage?.mediaDownloadStatus == .downloading {
                        if let cell = self?.chatTableView.cellForRow(at: indexPath) as? AudioReceiver {
                            cell.stopDownload()
                        }
                        message.mediaChatMessage?.mediaDownloadStatus = .not_downloaded
                        self?.chatMessages[indexPath.section][indexPath.row] = message
                        FlyMessenger.cancelMediaUploadOrDownload(message: message) { isSuccess in
                            DispatchQueue.main.async {
                                if let cell = self?.chatTableView.cellForRow(at: indexPath) as? AudioReceiver {
                                    cell.stopDownload()
                                }
                            }
                        }
                    } else if message.mediaChatMessage?.mediaDownloadStatus == .not_downloaded {
                        if let cell = self?.chatTableView.cellForRow(at: indexPath) as? AudioReceiver {
                            cell.startDownload()
                        }
                        message.mediaChatMessage?.mediaDownloadStatus = .downloading
                        self?.chatMessages[indexPath.section][indexPath.row] = message
                        FlyMessenger.downloadMediaRetry(message: message) { (success, error, chatMessage) in
                            if let cell = self?.chatTableView.cellForRow(at: indexPath) as? AudioReceiver {
                                cell.getCellFor(message, at: indexPath, isPlaying: self?.currenAudioIndexPath == indexPath ? self?.audioPlayer?.isPlaying ?? false : false, audioClosureCallBack: { (_) in
                                }, isShowForwardView: self?.isShowForwardView)
                            }
                        }
                    }
                }
            }
        }
    }
}

extension ChatViewParentController {
    @objc func contactSyncCompleted(notification: Notification){
        if let contactSyncState = notification.userInfo?[FlyConstants.contactSyncState] as? String {
            switch ContactSyncState(rawValue: contactSyncState) {
            case .inprogress:
                break
            case .success:
                setProfile()
            case .failed:
                print("contact sync failed")
            case .none:
                print("contact sync failed")
            }
        }
    }
}

extension ChatViewParentController {
    @objc func cancelOrDownloadImages(sender: UIButton) {
        let row = sender.tag % 1000
        let section = sender.tag / 1000
        let indexPath = IndexPath(row: row, section: section)
        let message = chatMessages[indexPath.section][indexPath.row]
        if message.isMessageSentByMe {
            if message.mediaChatMessage?.mediaDownloadStatus == .downloading {
                message.mediaChatMessage?.mediaDownloadStatus = .not_downloaded
                chatMessages[indexPath.section][indexPath.row] = message
                if let cell = chatTableView.cellForRow(at: indexPath) as? SenderImageCell {
                    cell.getCellFor(message, at: indexPath, isShowForwardView: isShowForwardView)
                }
                FlyMessenger.cancelMediaUploadOrDownload(message: message) { [weak self] isSuccess in
                    if message.messageType == .image {
                        DispatchQueue.main.async { [weak self] in
                            if let cell = self?.chatTableView.cellForRow(at: indexPath) as? SenderImageCell {
                                cell.getCellFor(message, at: indexPath, isShowForwardView: self?.isShowForwardView)
                            }
                        }
                    }
                }
            } else if message.mediaChatMessage?.mediaDownloadStatus == .not_downloaded {
                imageDownload(sender: sender)
            }
        }
    }
}

extension UIApplication {
    /// Checks if view hierarchy of application contains `UIRemoteKeyboardWindow` if it does, keyboard is presented
    var isKeyboardPresented: Bool {
        if let keyboardWindowClass = NSClassFromString("UIRemoteKeyboardWindow"),
           self.windows.contains(where: { $0.isKind(of: keyboardWindowClass) }) {
            return true
        } else {
            return false
        }
    }
}

// To handle user blocked by admin
extension ChatViewParentController {
    
    func checkUserForBlocking(jid : String , isBlocked : Bool) {
        if getProfileDetails.jid == jid && getProfileDetails.profileChatType == .singleChat {
            getProfileDetails.isBlockedByAdmin = isBlocked
            checkForUserBlocked()
            getLastSeen()
            setProfile()
        } else if isBlocked && getProfileDetails.jid == jid && getProfileDetails.profileChatType == .groupChat {
            view.endEditing(true)
            AppAlert.shared.showToast(message: groupNoLongerAvailable)
            navigate()
        }
    }
    
    func getBlockedByAdmin() -> Bool {
        return getProfileDetails.isBlockedByAdmin
    }
    
    func checkForUserBlocked() {
        let isBlocked = getBlockedByAdmin()
        disableForBlocking(disable: isBlocked)
        hideSendMessageView(isHidden: isBlocked)
        if isBlocked {
            view.endEditing(true)
        }
    }
    
    func disableForBlocking(disable : Bool) {
        videoButton.isEnabled = !disable
        audioButton.isEnabled = !disable
        menuButton.isEnabled = !disable
    }
    
    func hideSendMessageView(isHidden : Bool) {
        if getProfileDetails.profileChatType == .groupChat {
            chatTextViewXib?.blockedMessageLabel.text = youCantSendMessagesToThiGroup
        } else {
            chatTextViewXib?.blockedMessageLabel.text = thisUerIsNoLonger
        }
        chatTextViewXib?.cannotSendMessageView?.isHidden = !isHidden
    }
    
    
}

extension ChatViewParentController : AdminBlockDelegate {
    func didBlockOrUnblockContact(userJid: String, isBlocked: Bool) {
        checkUserForBlocking(jid: userJid, isBlocked: isBlocked)
    }
    
    func didBlockOrUnblockSelf(userJid: String, isBlocked: Bool) {
        
    }
    
    func didBlockOrUnblockGroup(groupJid: String, isBlocked: Bool) {
        checkUserForBlocking(jid: groupJid, isBlocked: isBlocked)
    }

}

// Reporting user or message
extension ChatViewParentController {
    
    @objc func didTapMenu(_ sender : UIButton) {
        let values : [String] = ChatActions.allCases.map { $0.rawValue }
        var actions = [(String, UIAlertAction.Style)]()
        values.forEach { title in
            actions.append((title, UIAlertAction.Style.default))
        }
        
        AppActionSheet.shared.showActionSeet(title: chatActions, message: "", actions: actions) { [weak self] didCancelTap, tappedOption in
            if !didCancelTap {
                switch tappedOption {
                case ChatActions.report.rawValue:
                    
                    if self?.getProfileDetails.contactType == .deleted {
                        AppAlert.shared.showToast(message: unableToReportDeletedUser)
                        return
                    }
                    
                    print("\(tappedOption)")
                    if ChatUtils.isMessagesAvailableFor(jid: self?.getProfileDetails.jid ?? "") {
                        if let profileDetails = self?.getProfileDetails {
                            self?.reportForJid(profileDetails: profileDetails)
                        }
                    } else {
                        AppAlert.shared.showToast(message: noMessgesToReport)
                    }
                default:
                    print(" \(tappedOption)")
                }
            }
        }
    }
    
    func didTapReportInMessage(chatMessge : ChatMessage) {
        reportFromMessage(chatMessage: chatMessge)
    }
}

extension ChatViewParentController : RefreshProfileInfo {
    func refreshProfileDetails(profileDetails:ProfileDetails?) {
        if getProfileDetails.jid == profileDetails?.jid{
            getProfileDetails = profileDetails
            setProfile()
            setGroupMemberInHeader()
        }
    }
}

//
extension ChatViewParentController {
    
    private func startUploadMediaTimer() {
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) {[weak self]  _ in
            if self?.canUploadMedia() == true {
                self?.uploadNext()
            }
        }
    }
    
    private func canUploadMedia() -> Bool {
        uploadMediaQueue?.count ?? 0 > 0 && !uploading
    }
    
    private func stopUploadMediaTimer() {
        
        timer?.invalidate()
        timer = nil
    }
    
    private func uploadNext() {
        
        if (uploading) { return }
        
        if let message = uploadMediaQueue?.first {
            
            uploading = true
            FlyMessenger.uploadFile(chatMessage: message) {[weak self] result in
                self?.uploadMediaQueue?.removeFirst();
                
                self?.uploading = false
            }
        }
        
    }
}

extension ChatViewParentController : GroupInfoDelegate {
    func didComefromGroupInfo() {
        getMessages()
    }
}
