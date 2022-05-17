//  ContactViewController.swift
//  MirrorflyUIkit
//  Created by User on 11/08/21.


import UIKit
import FlyCore
import FlyCommon
import SDWebImage
import FlyCall
import Contacts

class ContactViewController: UIViewController {
    @IBOutlet weak var profilePopupContainer: UIView!
    @IBOutlet weak var profilePopup: UIView!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var bottomBtn: UIButton!
    @IBOutlet weak var searchTxt: UISearchBar!
    @IBOutlet weak var contactList: UITableView!
    @IBOutlet weak var bottomBtnHeight: NSLayoutConstraint!
    @IBOutlet weak var headerVIewHeight: NSLayoutConstraint!
    @IBOutlet weak var topBarViewHeight: NSLayoutConstraint!
    @IBOutlet weak var serachFieldTopMargin: NSLayoutConstraint!
    @IBOutlet weak var titleLable: UILabel!
    @IBOutlet weak var headerView: UIView?
    
    var allContacts =  [ProfileDetails]()
    var contacts = [ProfileDetails]()
    var selectectProfiles = [ProfileDetails]()
    var selectedProfilesJid = NSMutableArray()
    var synced = false
    var isLocalCalled = false
    var currentIndex = -1
    var isMultiSelect = false
    var makeCall = false
    var isInvite = false
    var callType : CallType = .Audio
    var replyMessageObj: ChatMessage?
    var replyJid: String?
    var messageTxt: String?
    var replyTagDelegate: ReplyMessagesDelegate?
    var hideNavigationbar = false
    var tappedProfile : ProfileDetails? = nil
    var groupJid : String = ""
    var callUsers : [String] = []

    var isGroupBlockedByAdmin : Bool = false

    var permissionDialogShowedOnViewDidLoad = false

    
    public var profileCount = Int()
    //var randomColors = [UIColor?]()
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:
                                    #selector(ContactViewController.handleRefresh(_:)),
                                 for: UIControl.Event.valueChanged)
        refreshControl.tintColor = UIColor.gray
        return refreshControl
    }()
    private var contactViewModel : ContactViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        handleBackgroundAndForground()
        configureDefaults()
        bottomBtn.isEnabled = false
        bottomBtn.setTitleColor(UIColor.white, for: .normal)
        bottomBtn.setTitleColor(UIColor.white, for: .disabled)
        if makeCall || isMultiSelect {
            bottomBtnHeight.constant = 48
            bottomBtn.backgroundColor = UIColor.lightGray
            if isInvite {
                bottomBtn.setTitle("Add Participants", for: .normal)
            }else{
                bottomBtn.setTitle("Call Now", for: .normal)
            }
        }else{
            bottomBtnHeight.constant = 0
        }
        if isInvite{
            callUsers.append(contentsOf: CallManager.getCallUsersList() ?? [])
        }
        if isInvite || !groupJid.isEmpty{
            if isInvite{
                self.title = "Add participants"
            }else{
                self.title = "Participants"
            }
        }
    }
    @objc override func willCometoForeground() {
        getCotactFromLocal(fromServer: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        navigationController?.setNavigationBarHidden(!hideNavigationbar, animated: true)
        if hideNavigationbar {
            headerVIewHeight.constant = 0
            topBarViewHeight.constant = 48
            serachFieldTopMargin.constant = 0
        }else{
            headerVIewHeight.constant = 50
            topBarViewHeight.constant = 98
            serachFieldTopMargin.constant = 4
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.methodOfReceivedNotification(notification:)), name: Notification.Name(Identifiers.ncContactRefresh), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.contactSyncCompleted(notification:)), name: NSNotification.Name(FlyConstants.contactSyncState), object: nil)
        getCotactFromLocal(fromServer: false)
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("#content \(permissionDialogShowedOnViewDidLoad)")
        ContactManager.shared.profileDelegate = self

        ChatManager.shared.adminBlockDelegate = self

        if !permissionDialogShowedOnViewDidLoad && groupJid.isEmpty{
            showContactPermissionAlert(showDialogONly: true)
        }
        permissionDialogShowedOnViewDidLoad = false

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(FlyConstants.contactSyncState), object: nil)
        replyTagDelegate?.replyMessageObj(message: replyMessageObj, jid: replyJid ?? "", messageText: messageTxt ?? "")
        ContactManager.shared.profileDelegate = nil
        ChatManager.shared.adminBlockDelegate = nil
    }
    
    func setupUI() {
        navigationController?.view.backgroundColor = .white
        navigationController?.setNavigationBarHidden(!hideNavigationbar, animated: false)
        profilePopupContainer.isHidden = true
        self.title = contact
        userName.font = UIFont.font22px_appSemibold()
        searchTxt.placeholder = search
        contactList.estimatedRowHeight = 60
        contactList.tableFooterView = UIView()
    }
    
    func configureDefaults() {
        contactViewModel =  ContactViewModel()
        searchTxt.delegate = self
        self.contactList.addSubview(self.refreshControl)
        permissionDialogShowedOnViewDidLoad = true
        if ENABLE_CONTACT_SYNC && groupJid.isEmpty{
            showContactPermissionAlert()
        }else{
            refreshContacts()
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        profilePopupContainer.addGestureRecognizer(tap)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        if NetworkReachability.shared.isConnected {
            if groupJid.isEmpty{
                showContactPermissionAlert()
            }else{
                refreshContacts()
            }
        }else {
            refreshControl.endRefreshing()
            AppAlert.shared.showToast(message: ErrorMessage.noInternet)
        }
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        UIView.transition(with: profilePopupContainer, duration: 0.5, options: .transitionFlipFromLeft, animations: { [weak self] in
            self?.profilePopupContainer.isHidden = true
        })
    }
    
    @objc func methodOfReceivedNotification(notification: Notification) {
        if (self.view.window != nil) {
            getCotactFromLocal(fromServer: false)
        }
    }
    
    @objc func contactSyncCompleted(notification: Notification){
        if let contactSyncState = notification.userInfo?[FlyConstants.contactSyncState] as? String {
            switch ContactSyncState(rawValue: contactSyncState) {
            case .inprogress:
                refreshControl.startRotating()
            case .success:
                refreshControl.endRefreshing()
                getCotactFromLocal(fromServer: false)
            case .failed:
                refreshControl.endRefreshing()
                print("contact sync failed")
            case .none:
                print("contact sync failed")
            }
        }
    }
    
    func getCotactFromLocal(fromServer: Bool) {
        if ENABLE_CONTACT_SYNC && CNContactStore.authorizationStatus(for: CNEntityType.contacts) == .denied && groupJid.isEmpty{
            contacts.removeAll()
            allContacts.removeAll()
            contactList.reloadData()
            return
        }
        print("#image getCotactFromLocal")
        var profileDetails = [ProfileDetails]()
        if groupJid.isEmpty{
            if fromServer{
                contactViewModel.getContacts(fromServer: true, removeContacts: callUsers) { [weak self] (profiles, error)  in
                    if error != nil {
                        return
                    }
                    if  let  contactsList = profiles {
                        profileDetails.append(contentsOf: contactsList)
                        self?.reloadTableView(profileDetails: profileDetails)
                    }
                }
            }
            contactViewModel.getContacts(fromServer: false,removeContacts: callUsers) { [weak self] (profiles, error)  in
                if error != nil {
                    return
                }
                if  let  contactsList = profiles {
                    profileDetails.append(contentsOf: contactsList)
                    self?.reloadTableView(profileDetails: profileDetails)
                }
            }
        }else{
            var groupMembers =  GroupManager.shared.getGroupMemebersFromLocal(groupJid: groupJid).participantDetailArray.filter({$0.memberJid != FlyDefaults.myJid && $0.profileDetail?.isBlockedByAdmin == false})
            if isInvite{
                groupMembers.removeAll { member in
                    callUsers.contains(member.memberJid)
                }
            }
            for item in groupMembers{
                if let pd = item.profileDetail{
                    profileDetails.append(pd)
                }
            }
            reloadTableView(profileDetails: profileDetails)
        }
    }
    
    func reloadTableView(profileDetails: [ProfileDetails]){
        DispatchQueue.main.async { [weak self] in
            self?.allContacts.removeAll()
            self?.contacts.removeAll()
            self?.allContacts = profileDetails.sorted { getUserName(jid: $0.jid,name: $0.name, nickName: $0.nickName, contactType: $0.contactType).capitalized < getUserName(jid: $1.jid, name: $1.name, nickName: $1.nickName,contactType: $1.contactType).capitalized }
            self?.contacts = profileDetails
            let contactDetails = self?.searchTxt.text?.count == 0 ? self?.allContacts : self?.allContacts.filter({  getUserName(jid: $0.jid,name: $0.name, nickName: $0.nickName, contactType: $0.contactType).capitalized.contains(self?.searchTxt.text?.capitalized ?? "")})
            self?.contacts = contactDetails ?? []
            self?.contactList.reloadData()
            let index = self?.currentIndex
            let count = self?.contacts.count
            if index ?? 0 > -1  && index ?? 0 < count ?? 0 {
                self?.userName.text = self?.contacts[index ?? 0].name
                self?.setProfile()
            }
        }
    }
    
    func refreshContacts() {
        if ENABLE_CONTACT_SYNC && CNContactStore.authorizationStatus(for: CNEntityType.contacts) == .denied && groupJid.isEmpty || FlyDefaults.isContactPermissionSkipped && ENABLE_CONTACT_SYNC{
            contacts.removeAll()
            allContacts.removeAll()
            contactList.reloadData()
            return
        }
        if !groupJid.isEmpty{
            refreshControl.endRefreshing()
            return
        }
        searchTxt.resignFirstResponder()
        searchTxt.setShowsCancelButton(false, animated: true)
        searchTxt.text = ""
        contactViewModel.getContacts(fromServer: synced, removeContacts: callUsers) { [weak self] (profiles, error) in
            guard let weakSelf = self else { return }
            weakSelf.synced = true
            if profiles?.count == 0 {
                if  !weakSelf.isLocalCalled {
                    weakSelf.isLocalCalled  = true
                    weakSelf.refreshContacts()
                }
            }
            if error == nil {
                if  let  contactsList = profiles {
                    weakSelf.allContacts.removeAll()
                    weakSelf.contacts.removeAll()
                    weakSelf.allContacts = contactsList.sorted { getUserName(jid: $0.jid,name: $0.name, nickName: $0.nickName, contactType: $0.contactType).capitalized < getUserName(jid: $1.jid,name: $1.name, nickName: $1.nickName,contactType: $1.contactType).capitalized }
                    weakSelf.contacts = weakSelf.allContacts
                }
            }
           // weakSelf.randomColors = AppUtils.shared.setRandomColors(totalCount: weakSelf.contacts.count)
            if error != nil {
                weakSelf.contactList.reloadData()
            }
        }
    }
    
    @objc func closeKeyboard() {
        self.view.endEditing(true)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            contactList.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height + contactList.rowHeight, right: 0)
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        contactList.contentInset = .zero
    }
    
    @IBAction func bottomBtnTapped(_ sender: Any) {
        if makeCall{
            makeFlyCall()
        }
    }
    
    @objc func imageButtonAction(_ sender:AnyObject) {
        closeKeyboard()
        UIView.transition(with: profilePopupContainer, duration: 0.5, options: .transitionCrossDissolve, animations: { [weak self] in
            self?.profilePopupContainer.isHidden = false
        })
        if  let buttonTag = sender.tag {
            currentIndex = buttonTag
            setProfile()
        }
    }
    
    func setProfile() {
        tappedProfile = contacts[currentIndex]
        if let profile =  tappedProfile{
            let name = getUserName(jid: profile.jid,name: profile.name, nickName: profile.nickName, contactType: profile.contactType)
            self.userName.text = name
            userImage.loadFlyImage(imageURL: profile.image, name: name, chatType: profile.profileChatType)
        }
    }
    
    func getPlaceholder(name: String, color: UIColor)-> UIImage {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let ipimage = IPImage(text: trimmedName, radius: Double(userImage.frame.size.height), font: UIFont.font84px_appBold(), textColor: nil, color: color)
        let placeholder = ipimage.generateInitialSqareImage()
        return placeholder ?? #imageLiteral(resourceName: "ic_profile_placeholder")
    }
    
    @IBAction func message(_ sender: Any) {
        openChat(index: currentIndex)
    }
    
    @IBAction func call(_ sender: Any) {
    }
    
    @IBAction func videoCall(_ sender: Any) {
    }
    
    @IBAction func userInfo(_ sender: Any) {
    }
    
    func showContactPermissionAlert(showDialogONly : Bool = false){
        if ENABLE_CONTACT_SYNC {
            let contactPermissionStatus = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
            if contactPermissionStatus == .authorized{
                if !showDialogONly{
                    refreshContacts()
                    refreshControl.endRefreshing()
                }
            }else if contactPermissionStatus == .denied{
                allContacts.removeAll()
                contacts.removeAll()
                contactList.reloadData()
                alertContactAccessNeeded()
            }else if (contactPermissionStatus == .restricted || contactPermissionStatus == .notDetermined){
                CNContactStore().requestAccess(for: .contacts){ [weak self] (access, error)  in
                    executeOnMainThread {
                        self?.contactViewModel.syncContacts()
                        self?.refreshControl.endRefreshing()
                    }
                }
            }
        }else{
            if !showDialogONly{
                refreshContacts()
            }
        }
    }
    
    func alertContactAccessNeeded() {
        let settingsAppURL = URL(string: UIApplication.openSettingsURLString)!
        let alert = UIAlertController(
            title: "Need Contacts permission",
            message: "Contacts access has been denied. Kindly enable contact access in app settings.",
            preferredStyle: UIAlertController.Style.alert
        )
        alert.addAction(UIAlertAction(title: "Go to settings", style: .default, handler: { (alert) -> Void in
            executeOnMainThread {
                UIApplication.shared.open(settingsAppURL, options: [:], completionHandler: nil)
            }
        }))
        alert.addAction(UIAlertAction(title: "Don't  Allow ", style: .cancel, handler: { (alert) -> Void in
            executeOnMainThread {
                self.refreshControl.endRefreshing()
            }
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
}

// SearchBar Delegate Method
extension ContactViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String){
        contacts = searchText.isEmpty ? allContacts : allContacts.filter { term in
            return getUserName(jid: term.jid ,name: term.name, nickName: term.nickName, contactType: term.contactType).lowercased().contains(searchText.lowercased())
        }
        self.contactList.reloadData()
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchTxt.setShowsCancelButton(false, animated: true)
        searchTxt.text = ""
        contacts = allContacts
        self.contactList.reloadData()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchTxt.setShowsCancelButton(true, animated: true)
    }
}

//Tableview Delegate
extension ContactViewController :  UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if contacts.count > 0 {
            return contacts.count
        }else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if contacts.count > 0 && indexPath.row < contacts.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.contactCell) as! ContactCell
            cell.selectionStyle = .none
            print("Contact XYZ \(contacts.count) \(indexPath.row)")
            let profile = contacts[indexPath.row]
            let name = getUserName(jid: profile.jid,name: profile.name, nickName: profile.nickName, contactType: profile.contactType)
            cell.profileButton.tag = indexPath.row
            cell.profileButton.addTarget(self, action: #selector( imageButtonAction(_:)), for: .touchUpInside)
            cell.name.text = name
            cell.status.text = profile.status
            let color = getColor(userName: name)
            cell.profile.loadFlyImage(imageURL: profile.image, name: name)
            cell.checkBox.tag = indexPath.row
            cell.checkBox.isSelected = selectedProfilesJid.contains(profile.jid)
            cell.checkBox.isHidden = !isMultiSelect
            cell.setTextColorWhileSearch(searchText: searchTxt.text ?? "", profile: profile)
            return cell
        }else {
            let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.noContacts)
            cell?.textLabel?.font = UIFont.font15px_appMedium()
            cell?.textLabel?.textAlignment = .center
            cell?.textLabel?.text = ErrorMessage.noContactsFound
            cell?.isUserInteractionEnabled = false
            return cell!
        }
    }
    
    func hash(_ string: String) -> Int {
        func djb(_ string: String) -> Int {
            
            return string.utf8
                .map {return $0}
                .reduce(5381) {
                    ($0 << 5) &+ $0 &+ Int($1)
                }
        }
        
        return djb(string)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isMultiSelect {
            if makeCall {
                let profile = contacts[indexPath.row]
                if (CallManager.getCallUsersList()?.count ?? 0) + selectedProfilesJid.count  == 7  && !selectedProfilesJid.contains(profile.jid!) {
                    AppAlert.shared.showAlert(view: self, title: "Alert", message: "Only upto 8 members are allowed for a call (including the caller)", buttonTitle: "Ok")
                }else{
                    if selectedProfilesJid.contains(profile.jid!) {
                        selectedProfilesJid.remove(profile.jid!)
                    } else {
                        selectedProfilesJid.add(profile.jid!)
                    }
                    let cell = tableView.cellForRow(at: indexPath) as! ContactCell
                    cell.checkBox.isSelected = selectedProfilesJid.contains(profile.jid!)
                    
                }
                updateBottomButton()
            }else{
                // TODO
            }
        }else{
            openChat(index: indexPath.row)
        }
    }
    
    func openChat(index: Int) {
        let profile = contacts[index]
        let vc = UIStoryboard.init(name: Storyboards.chat, bundle: Bundle.main).instantiateViewController(withIdentifier: Identifiers.chatViewParentController) as? ChatViewParentController
        vc?.getProfileDetails = profile
        let color = getColor(userName: profile.name)
        vc?.contactColor = color
        vc?.replyJid = replyJid
        vc?.replyMessageObj = replyMessageObj
        vc?.replyMessagesDelegate = self
        vc?.messageText = messageTxt
        navigationController?.modalPresentationStyle = .fullScreen
        guard let viewController = vc else { return }
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    @objc func buttonSelected(sender: UIButton){
        let profile = contacts[sender.tag]
        if selectectProfiles.contains(profile) {
            if  let indx = selectectProfiles.firstIndex(of: profile) {
                selectectProfiles.remove(at: indx)
                contactList.reloadData()
            }
        }else{
            selectectProfiles.append(profile)
            contactList.reloadData()
        }
    }
    
    func updateBottomButton() {
        if makeCall{
            var btnTitle = "Call Now"
            if selectedProfilesJid.count == 0 {
                if isInvite {
                    btnTitle = "Add Participants"
                }
            } else {
                if isInvite {
                    btnTitle = "Add Participants (\(selectedProfilesJid.count))"
                }else{
                    btnTitle = "Call Now (\(selectedProfilesJid.count))"
                }
            }
            bottomBtn.setTitle(btnTitle, for: .normal)
            bottomBtn.isEnabled = selectedProfilesJid.count > 0
            bottomBtn.backgroundColor = (selectedProfilesJid.count > 0) ? UIColor.systemBlue : UIColor.lightGray
        }
    }
    
}

extension ContactViewController : ProfileEventsDelegate {
    func userCameOnline(for jid: String) {
        
    }
    
    func userWentOffline(for jid: String) {
        
    }
    
    func userProfileFetched(for jid: String, profileDetails: ProfileDetails?) {
        
    }
    
    func myProfileUpdated() {
        
    }
    
    func usersProfilesFetched() {
        getCotactFromLocal(fromServer: false)
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
        if  let index = allContacts.firstIndex(where: { pd in pd.jid == jid }) {
            allContacts[index] = profileDetails
            print("userUpdatedTheirProfile currentIndex \(currentIndex)")
            let profile = ["jid": profileDetails.jid, "name": profileDetails.name, "image": profileDetails.image, "status": profileDetails.status]
            NotificationCenter.default.post(name: Notification.Name(Identifiers.ncProfileUpdate), object: nil, userInfo: profile as [AnyHashable : Any])
            NotificationCenter.default.post(name: Notification.Name(FlyConstants.contactSyncState), object: nil, userInfo: profile as [AnyHashable : Any])
            if let index = contacts.firstIndex(where: { pd in pd.jid == jid })  {
                contacts[index] = profileDetails
                let indexPath = IndexPath(item: index, section: 0)
                contactList?.reloadRows(at: [indexPath], with: .fade)
                if let tappedPd = tappedProfile, tappedPd.jid == profileDetails.jid{
                    currentIndex = index
                    setProfile()
                }
            }else{
                let indexPath = IndexPath(item: index, section: 0)
                contactList?.reloadRows(at: [indexPath], with: .fade)
                if let tappedPd = tappedProfile, tappedPd.jid == profileDetails.jid{
                    currentIndex = index
                    setProfile()
                }
            }
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
}

//Call
extension ContactViewController {
    
    func makeFlyCall() {
        if isGroupBlockedByAdmin {
            AppAlert.shared.showToast(message: "\(groupNoLongerAvailable), can't make call")
            return
        }
        
        if !CallManager.isOngoingCall() || isInvite{
            if isInvite{
                CallManager.inviteUsersToOngoingCall(selectedProfilesJid as! [String])
            }else{
                RootViewController.sharedInstance.callViewController?.makeCall(usersList: selectedProfilesJid as! [String], callType: callType, groupId : groupJid)
            }
            self.navigationController?.popViewController(animated: false)
        }else{
            AppAlert.shared.showToast(message: "Already in another call, can't make new call")
        }
    }
}

extension ContactViewController : ReplyMessagesDelegate {
    func replyMessageObj(message: ChatMessage?,jid: String,messageText: String) {
        replyMessageObj = message
        replyJid = jid
        messageTxt = messageText
    }
}

extension ContactViewController : AdminBlockDelegate {
    func didBlockOrUnblockContact(userJid: String, isBlocked: Bool) {
        checkUserForAdminBlocking(jid: userJid, isBlocked: isBlocked)
    }
    
    func didBlockOrUnblockSelf(userJid: String, isBlocked: Bool) {
    
    }
    
    func didBlockOrUnblockGroup(groupJid: String, isBlocked: Bool) {
        checkUserForAdminBlocking(jid: groupJid, isBlocked: isBlocked)
    }

}

// To handle Admin Blocked user

extension ContactViewController {
    func checkUserForAdminBlocking(jid : String, isBlocked : Bool) {
        
        if isBlocked {
            allContacts = removeAdminBlockedContact(profileList: allContacts, jid: jid, isBlockedByAdmin: isBlocked)
            contacts = removeAdminBlockedContact(profileList: contacts, jid: jid, isBlockedByAdmin: isBlocked)
            selectectProfiles = removeAdminBlockedContact(profileList: selectectProfiles, jid: jid, isBlockedByAdmin: isBlocked)
            
            if isBlocked && selectedProfilesJid.count > 0 && selectedProfilesJid.contains(jid){
                selectedProfilesJid.remove(jid)
            }
        } else {
            if !FlyUtils.isValidGroupJid(groupJid: jid) {
                contacts = addUnBlockedContact(profileList: contacts, jid: jid, isBlockedByAdmin : isBlocked)
                allContacts = addUnBlockedContact(profileList: allContacts, jid: jid, isBlockedByAdmin: isBlocked)
            }
        }
        
        
        if FlyUtils.isValidGroupJid(groupJid: jid) && groupJid == jid {
            isGroupBlockedByAdmin = isBlocked
        }
        
        executeOnMainThread { [weak self] in
            self?.updateBottomButton()
            self?.contactList.reloadData()
        }
    }
}

