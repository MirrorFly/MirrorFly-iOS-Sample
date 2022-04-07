//  ContactViewController.swift
//  MirrorflyUIkit
//  Created by User on 11/08/21.


import UIKit
import FlyCore
import FlyCommon
import SDWebImage
import FlyCall

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
    var isFromRecentChat = false
    
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        if isFromRecentChat{
            headerVIewHeight.constant = 0
            topBarViewHeight.constant = 48
            serachFieldTopMargin.constant = 0
        }else{
            headerVIewHeight.constant = 50
            topBarViewHeight.constant = 98
            serachFieldTopMargin.constant = 4
        }
        ContactManager.shared.profileDelegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(self.methodOfReceivedNotification(notification:)), name: Notification.Name(Identifiers.ncContactRefresh), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.contactSyncCompleted(notification:)), name: NSNotification.Name(FlyConstants.contactSyncState), object: nil)
        getCotactFromLocal()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        NotificationCenter.default.removeObserver(self)
        replyTagDelegate?.replyMessageObj(message: replyMessageObj, jid: replyJid ?? "", messageText: messageTxt ?? "")
    }
    
    func setupUI() {
        navigationController?.view.backgroundColor = .white
        navigationController?.setNavigationBarHidden(false, animated: false)
        profilePopupContainer.isHidden = true
        self.title = contact
        userName.font = UIFont.font22px_appSemibold()
        searchTxt.placeholder = search
        contactList.estimatedRowHeight = 60
        contactList.tableFooterView = UIView()
    }
    
    func configureDefaults() {
        ContactManager.shared.profileDelegate = self
        contactViewModel =  ContactViewModel()
        searchTxt.delegate = self
        self.contactList.addSubview(self.refreshControl)
        refreshContacts()
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        profilePopupContainer.addGestureRecognizer(tap)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        if NetworkReachability.shared.isConnected {
            refreshContacts()
        }else {
            AppAlert.shared.showToast(message: ErrorMessage.noInternet)
        }
        refreshControl.endRefreshing()
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        UIView.transition(with: profilePopupContainer, duration: 0.5, options: .transitionFlipFromLeft, animations: { [weak self] in
            self?.profilePopupContainer.isHidden = true
        })
    }
    
    @objc func methodOfReceivedNotification(notification: Notification) {
        if (self.view.window != nil) {
            getCotactFromLocal()
        }
    }
    
    @objc func contactSyncCompleted(notification: Notification){
        if let contactSyncState = notification.userInfo?[FlyConstants.contactSyncState] as? ContactSyncState {
            switch contactSyncState {
            case .inprogress:
                refreshControl.startRotating()
            case .success:
                refreshControl.endRefreshing()
                getCotactFromLocal()
            case .failed:
                refreshControl.endRefreshing()
                print("contact sync failed")
            }
        }
    }
    
    func getCotactFromLocal() {
        contactViewModel.getContacts(fromServer: false) { [weak self] (profiles, error)  in
            if error != nil {
                return
            }
            self?.allContacts.removeAll()
            self?.contacts.removeAll()
            if  let  contactsList = profiles {
                self?.allContacts = contactsList.sorted { $0.name.capitalized < $1.name.capitalized }
                self?.contacts = contactsList
                if  let contactDetails = self?.searchTxt.text?.count == 0 ? self?.allContacts : self?.allContacts.filter({ $0.name.capitalized.contains(self?.searchTxt.text?.capitalized ?? "")}) {
                    self?.contacts = contactDetails
                    self?.contactList.reloadData()
                    let index = self?.currentIndex ?? -1
                    if index > -1 {
                        self?.userName.text = self?.contacts[index].name
                        self?.setProfile()
                    }
                }
            }
        }
    }
    
    func refreshContacts() {
        searchTxt.resignFirstResponder()
        searchTxt.setShowsCancelButton(false, animated: true)
        searchTxt.text = ""
        contactViewModel.getContacts(fromServer: synced) { [weak self] (profiles, error) in
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
                    weakSelf.allContacts = contactsList.sorted { $0.name.capitalized < $1.name.capitalized }
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
    
    @objc func imageButtonAction(_ sender:AnyObject){
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
        let profile = contacts[currentIndex]
        userName.text = profile.name
        let urlString = "\(Environment.sandboxImage.baseURL)\(media)/\(profile.image)?mf=\(FlyDefaults.authtoken)"
        let url = URL(string: urlString)
        let color = getColor(userName: profile.name)
        userImage.sd_imageIndicator = SDWebImageActivityIndicator.gray
        userImage.sd_setImage(with: url, placeholderImage: getPlaceholder(name: profile.name, color: color))
    }
    
    func getPlaceholder(name: String, color: UIColor)->UIImage {
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
    
}

// SearchBar Delegate Method
extension ContactViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String){
        contacts = searchText.isEmpty ? allContacts : allContacts.filter { term in
            return term.name.lowercased().contains(searchText.lowercased())
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
        if contacts.count > 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.contactCell) as! ContactCell
            cell.selectionStyle = .none
            let profile = contacts[indexPath.row]
            cell.profileButton.tag = indexPath.row
            cell.profileButton.addTarget(self, action: #selector( imageButtonAction(_:)), for: .touchUpInside)
            cell.name.text = profile.name
            cell.status.text = profile.status
            let color = getColor(userName: profile.name)
            cell.setImage(imageURL: profile.image, name: profile.name, color: color)
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
    
    private func getColor(userName : String) -> UIColor {
        return ChatUtils.getColorForUser(userName: userName)
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
        let profileDatas =  contacts.filter({ ($0.jid.contains(jid)) })
        if profileDatas.count > 0, let profileData = profileDatas.first  {
            if  let indx = contacts.firstIndex(of: profileData) {
                contacts[indx] = profileDetails
                if let contactIndx = allContacts.firstIndex(of: profileData) {
                    allContacts[contactIndx] = profileDetails
                }
                print("userUpdatedTheirProfile currentIndex \(currentIndex)")
                if currentIndex > -1 {
                    contacts[currentIndex] = profileDetails
                    userName.text = profileDetails.name
                    setProfile()
                }
                let profile = ["jid": profileDetails.jid, "name": profileDetails.name, "image": profileDetails.image, "status": profileDetails.status]
                NotificationCenter.default.post(name: Notification.Name(Identifiers.ncProfileUpdate), object: nil, userInfo: profile as [AnyHashable : Any])
                contactList.reloadData()
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
        if !CallManager.isOngoingCall() || isInvite{
            if isInvite{
                CallManager.inviteUsersToOngoingCall(selectedProfilesJid as! [String])
            }else{
                RootViewController.sharedInstance.callViewController?.makeCall(usersList: selectedProfilesJid as! [String], callType: callType)
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
