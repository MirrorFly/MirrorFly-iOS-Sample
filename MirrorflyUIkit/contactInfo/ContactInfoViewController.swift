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
    
    let contactInfoViewModel = ContactInfoViewModel()
    
    let contactInfoTitle = [email, mobileNumber, status]
    let contactInfoIcon = [ImageConstant.ic_info_email, ImageConstant.ic_info_phone, ImageConstant.ic_info_status]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setConfiguration()
        setUpUI()
        getLastSeen()
    }
    
    private func setConfiguration(){
        ContactManager.shared.profileDelegate = self
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
            cell.onlineStatus?.text = lastSeen
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
        navigationController?.navigationBar.isHidden = false
        navigationController?.popViewController(animated: true)
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

}

extension ContactInfoViewController : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 2 {
            return 3
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = (tableView.dequeueReusableCell(withIdentifier: Identifiers.contactImageCell, for: indexPath) as? ContactImageCell)!
            
            cell.backButton?.addTarget(self, action: #selector(didTapBack(sender:)), for: .touchUpInside)
            let name = (profileDetails?.name.isEmpty ?? false) ? profileDetails?.nickName : profileDetails?.name
            cell.userNameLabel?.text = name
            let imageUrl = profileDetails?.image  ?? ""
            
            let placeholder = ChatUtils.getPlaceholder(name: profileDetails?.name ?? "", userColor: ChatUtils.getColorForUser(userName: name), userImage: cell.userImage ?? UIImageView())
            cell.userImage?.backgroundColor = ChatUtils.getColorForUser(userName: name)
            cell.userImage?.sd_setImage(with: ChatUtils.getUserImaeUrl(imageUrl: imageUrl), placeholderImage: placeholder)
            
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapImage(sender:)))
            cell.userImage?.isUserInteractionEnabled = true
            cell.userImage?.addGestureRecognizer(gestureRecognizer)
            
            return cell
        } else if indexPath.section == 1 {
            let cell = (tableView.dequeueReusableCell(withIdentifier: Identifiers.muteNotificationCell, for: indexPath) as? MuteNotificationCell)!
            cell.muteSwitch?.addTarget(self, action: #selector(stateChanged), for: .valueChanged)
            cell.muteSwitch?.setOn(profileDetails?.isMuted ?? false, animated: true)
            return cell
        } else if indexPath.section == 2 {
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
        return 4
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
    
}
