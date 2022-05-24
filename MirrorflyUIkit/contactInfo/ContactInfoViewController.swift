//
//  ContactInfoViewController.swift
//  MirrorflyUIkit
//
//  Created by John on 28/01/22.
//

import UIKit
import FlyCommon
import SDWebImage
import FlyCore

class ContactInfoViewController: ViewController {
    
    @IBOutlet weak var contactInfoTableView: UITableView?
    
    var contactJid = ""
    var profileDetails : ProfileDetails?
    var isFromGroupInfo: Bool = false
    var groupId = ""
    
    let contactInfoViewModel = ContactInfoViewModel()
    let contactInfoTitle = [email, mobileNumber, status]
    let contactInfoIcon = [ImageConstant.ic_info_email, ImageConstant.ic_info_phone, ImageConstant.ic_info_status]
    var delegate: RefreshProfileInfo?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setConfiguration()
        setUpUI()
        getLastSeen()
        networkMonitor()
        NotificationCenter.default.addObserver(self, selector: #selector(self.contactSyncCompleted(notification:)), name: NSNotification.Name(FlyConstants.contactSyncState), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        ContactManager.shared.profileDelegate = self
        ChatManager.shared.adminBlockDelegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        ContactManager.shared.profileDelegate = nil
        ChatManager.shared.adminBlockDelegate = nil
        delegate = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(FlyConstants.contactSyncState), object: nil)
    }
    
    
    private func setConfiguration(){
        if contactJid.isNotEmpty {
            profileDetails = contactInfoViewModel.getContactInfo(jid: contactJid)
        }
    }
    
    private func getLastSeen() {
        contactInfoViewModel.getLastSeen(jid: contactJid) { [weak self] lastSeen in
            self?.setLastSeen(lastSeen: lastSeen)
        }
    }
    
    private func setLastSeen(lastSeen : String) {
        let indexPath = IndexPath(row: 0, section: 0)
        if let cell = contactInfoTableView?.cellForRow(at: indexPath) as? ContactImageCell {
            if (profileDetails?.contactType == .deleted) {
                cell.onlineStatus?.text = emptyString()
                cell.onlineStatus?.isHidden = true
            }else{
                cell.onlineStatus?.text = lastSeen
                cell.onlineStatus?.isHidden = false
            }
        }
    }
    
    private func refreshData() {
        contactInfoTableView?.reloadData()
    }
    
    private func setUpUI() {
        navigationController?.navigationBar.isHidden = true
        setUpStatusBar()
        contactInfoTableView?.delegate = self
        contactInfoTableView?.dataSource = self
        
        contactInfoTableView?.register(UINib(nibName: Identifiers.contactInfoCell , bundle: .main), forCellReuseIdentifier: Identifiers.contactInfoCell)
        
        contactInfoTableView?.register(UINib(nibName: Identifiers.viewAllMediaCell , bundle: .main), forCellReuseIdentifier: Identifiers.viewAllMediaCell)
        
        contactInfoTableView?.register(UINib(nibName: Identifiers.muteNotificationCell , bundle: .main), forCellReuseIdentifier: Identifiers.muteNotificationCell)
        
        contactInfoTableView?.register(UINib(nibName: Identifiers.contactImageCell , bundle: .main), forCellReuseIdentifier: Identifiers.contactImageCell)
    }
    
   
    
    @objc func didTapBack(sender : Any) {
        if isFromGroupInfo == true {
            navigationController?.navigationBar.isHidden = true
            navigationController?.popViewController(animated: true)
        } else {
            navigationController?.navigationBar.isHidden = false
            navigationController?.popViewController(animated: true)
        }
    }
    
    @objc func didTapImage(sender : Any) {
        if let image = profileDetails?.image, image.isNotEmpty {
            performSegue(withIdentifier: Identifiers.viewUserImageController, sender: self)
        }
    }
    
    @objc func stateChanged(switchState: UISwitch) {
        if switchState.isOn {
            contactInfoViewModel.muteNotification(jid: contactJid, mute: true)
        } else {
            contactInfoViewModel.muteNotification(jid: contactJid, mute: false)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Identifiers.viewUserImageController {
            let viewUserImageVC = segue.destination as! ViewUserImageController
            viewUserImageVC.profileDetails = profileDetails
        }
    }
    
    func networkMonitor() {
        if !NetworkReachability.shared.isConnected {
            DispatchQueue.main.async { [weak self] in
                self?.setLastSeen(lastSeen: waitingForNetwork)
            }
        }
        NetStatus.shared.netStatusChangeHandler = { [weak self] in
            print("networkMonitor \(NetStatus.shared.isConnected)")
            DispatchQueue.main.async {
                if NetStatus.shared.isConnected {
                    self?.getLastSeen()
                } else {
                    self?.setLastSeen(lastSeen: waitingForNetwork)
                }
            }
        }
    }
}

extension ContactInfoViewController : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            return 3
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = (tableView.dequeueReusableCell(withIdentifier: Identifiers.contactImageCell, for: indexPath) as? ContactImageCell)!
            
            cell.backButton?.addTarget(self, action: #selector(didTapBack(sender:)), for: .touchUpInside)
            cell.editTextField.isHidden = true
            let name = getUserName(jid: profileDetails?.jid ?? "",name: profileDetails?.name ?? "", nickName: profileDetails?.nickName ?? "", contactType: profileDetails?.contactType ?? .unknown )
            cell.userNameLabel?.text = name
            let imageUrl = profileDetails?.image  ?? ""
            var placeholder : UIImage
            if profileDetails?.contactType == .deleted{
                cell.userImage?.image = UIImage(named: "ic_profile_placeholder") ?? UIImage()
                cell.userImage?.contentMode = .center
                cell.userImage?.backgroundColor = UIColor.darkGray
            }else{
                placeholder = ChatUtils.getPlaceholder(name: name, userColor: ChatUtils.getColorForUser(userName: name), userImage: cell.userImage ?? UIImageView())
                cell.userImage?.backgroundColor = ChatUtils.getColorForUser(userName: name)
                cell.userImage?.loadFlyImage(imageURL: imageUrl, name: name ?? "", chatType: profileDetails?.profileChatType ?? .singleChat)
            }
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapImage(sender:)))
            cell.userImage?.isUserInteractionEnabled = true
            cell.userImage?.addGestureRecognizer(gestureRecognizer)
            cell.editButton?.isHidden = true
            cell.editProfileButton?.isHidden = true
            
            return cell
//        } else if indexPath.section == 1 {
//            let cell = (tableView.dequeueReusableCell(withIdentifier: Identifiers.muteNotificationCell, for: indexPath) as? MuteNotificationCell)!
//            cell.muteSwitch?.addTarget(self, action: #selector(stateChanged), for: .valueChanged)
//            cell.muteSwitch?.setOn(profileDetails?.isMuted ?? false, animated: true)
//            return cell
          } else if indexPath.section == 1 {
            let cell = (tableView.dequeueReusableCell(withIdentifier: Identifiers.contactInfoCell, for: indexPath) as? ContactInfoCell)!
            
            cell.titleLabel?.text = contactInfoTitle[indexPath.row]
            cell.icon?.image = UIImage(named: contactInfoIcon[indexPath.row])
            
            if indexPath.row == 0 {
                cell.contentLabel?.text = profileDetails?.email ?? ""
            } else if indexPath.row == 1 {
                cell.contentLabel?.text = profileDetails?.mobileNumber ?? ""
            } else if indexPath.row == 2 {
                cell.contentLabel?.text = profileDetails?.status ?? ""
            }
            
            return cell
        } else if indexPath.section == 3 {
            let cell = (tableView.dequeueReusableCell(withIdentifier: Identifiers.viewAllMediaCell, for: indexPath) as? ViewAllMediaCell)!
            return cell
        }
        
        return UITableViewCell()
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if (profileDetails?.contactType != .deleted){
            return 2
        }else{
            return 1
        }
    }
    
}

extension ContactInfoViewController : ProfileEventsDelegate {
    func userCameOnline(for jid: String) {
        if contactJid == jid {
            setLastSeen(lastSeen: online.localized)
        }
    }
    
    func userWentOffline(for jid: String) {
        if contactJid == jid {
            let lastSeen = contactInfoViewModel.calculateLastSeen(lastSeenTime: "0")
            setLastSeen(lastSeen: lastSeen)
        }
    }
    
    func userProfileFetched(for jid: String, profileDetails: ProfileDetails?) {
        
    }
    
    func myProfileUpdated() {
        
    }
    
    func usersProfilesFetched() {
        if let profile = contactInfoViewModel.getContactInfo(jid: profileDetails?.jid ?? "") {
            profileDetails = profile
            refreshData()
            delegate?.refreshProfileDetails(profileDetails: profileDetails)
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
        if jid ==  contactJid {
            let profile = ["jid": profileDetails.jid, "name": profileDetails.name, "image": profileDetails.image, "status": profileDetails.status]
            NotificationCenter.default.post(name: Notification.Name(FlyConstants.contactSyncState), object: nil, userInfo: profile as [AnyHashable : Any])
            self.profileDetails = profileDetails
            refreshData()
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
    
    func userDeletedTheirProfile(for jid : String, profileDetails:ProfileDetails){
        self.profileDetails = profileDetails
        contactInfoTableView?.reloadData()
        setLastSeen(lastSeen: emptyString())
        delegate?.refreshProfileDetails(profileDetails: profileDetails)
    }
    
}

extension ContactInfoViewController {
    @objc func contactSyncCompleted(notification: Notification){
        if let contactSyncState = notification.userInfo?[FlyConstants.contactSyncState] as? String {
            switch ContactSyncState(rawValue: contactSyncState) {
            case .inprogress:
                break
            case .success:
               setConfiguration()
            case .failed:
                print("contact sync failed")
            case .none:
                print("contact sync failed")
            }
        }
    }
}

extension ContactInfoViewController : AdminBlockDelegate {
    func didBlockOrUnblockContact(userJid: String, isBlocked: Bool) {
        
    }
    
    func didBlockOrUnblockSelf(userJid: String, isBlocked: Bool) {
        
    }
    
    func didBlockOrUnblockGroup(groupJid: String, isBlocked: Bool) {
        if isFromGroupInfo && groupId == groupJid  && isBlocked {
            self.navigationController?.navigationBar.isHidden = false
            self.navigationController?.popToRootViewController(animated: true)
            executeOnMainThread {
                AppAlert.shared.showToast(message: groupNoLongerAvailable)
            }
        }
    }
    
    
}
