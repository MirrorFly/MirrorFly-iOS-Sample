//
//  AddParticipantsViewController.swift
//  MirrorflyUIkit
//
//  Created by John on 23/11/21.
//

import UIKit
import FlyCommon
import FlyCore
import AudioToolbox

protocol AddParticipantsDelegate: class {
    func updatedAddParticipants()
}

class AddParticipantsViewController: UIViewController {
    
    let groupCreationViewModel = GroupCreationViewModel()
    var groupCreationDeletgate : GroupCreationDelegate?
    
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var participantTableView: UITableView!
    
    weak var delegate: AddParticipantsDelegate? = nil
    
    var participants = [ProfileDetails]()
    var searchedParticipants = [ProfileDetails]()
    var existingParticipants: ProfileDetails!
    var filteredContacts = [String]()
    
    var isFromGroupInfo: Bool = false
    var groupID = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
        setUpTableView()
        getContacts()
        checkExistingGroup()
        NotificationCenter.default.addObserver(self, selector: #selector(self.contactSyncCompleted(notification:)), name: NSNotification.Name(FlyConstants.contactSyncState), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        resetSearch()
        participantTableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        ChatManager.shared.adminBlockDelegate = self
        ContactManager.shared.profileDelegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        ChatManager.shared.adminBlockDelegate = nil
        ContactManager.shared.profileDelegate = nil
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(FlyConstants.contactSyncState), object: nil)
    }
    
    func setUpUI() {
        setUpStatusBar()
        searchBar.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            participantTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height + participantTableView.rowHeight + 30, right: 0)
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        participantTableView.contentInset = .zero
    }
    
    func setUpTableView() {
        participantTableView.delegate = self
        participantTableView.dataSource = self
        participantTableView.register(UINib(nibName: Identifiers.participantCell , bundle: .main), forCellReuseIdentifier: Identifiers.participantCell)
        participantTableView.register(UINib(nibName: Identifiers.noResultFound , bundle: .main),forCellReuseIdentifier: Identifiers.noResultFound)
    }
    
    
    @IBAction func didBackTap(_ sender: Any) {
        groupCreationViewModel.initializeGroupCreationData()
        navigationController?.popViewController(animated: true)
    }
    
    
    @IBAction func didNextTap(_ sender: Any) {
        
        if isFromGroupInfo == true {
            if GroupCreationData.participants.count == 0 {
                AppAlert.shared.showToast(message: "Please select minimum one Participant")
                return
            }
            groupCreationViewModel.addNewParticipantToGroup(groupID: groupID) { [weak self] success in
                if success {
                    self?.groupCreationViewModel.initializeGroupCreationData()
                    self?.navigationController?.popViewController(animated: true)
                    self?.delegate?.updatedAddParticipants()
                    AppAlert.shared.showToast(message: "Members added successfully")
                }
            }
            
        } else {
            if groupCreationViewModel.checkMaximumParticipant(selectedParticipant: GroupCreationData.participants) {
                AppAlert.shared.showToast(message: maximumGroupUsers)
                return
            }
            
            if groupCreationViewModel.checkMinimumParticipant(selectedParticipants: GroupCreationData.participants) {
                print("groupName\(GroupCreationData.groupName) imagePath\(GroupCreationData.groupImageLocalPath)                                selecteddd\(GroupCreationData.participants.count)")
                performSegue(withIdentifier: Identifiers.groupCreationPreview, sender: nil)
            } else {
                AppAlert.shared.showToast(message: atLeastTwoParticipant)
            }
        }
    }
    
    func getContacts() {
        groupCreationViewModel.getContacts(fromServer: false,
                                           completionHandler: { [weak self] (profiles, error) in
            if error != nil {
                return
            }
            
            if self?.isFromGroupInfo == true {
                self?.participants = self?.groupCreationViewModel.removeExistingParticipants(groupID: self?.groupID ?? "", contacts: profiles ?? []) ?? []
                self?.participantTableView.reloadData()
            } else {
                
                self?.participants = (profiles?.sorted{ $0.name.capitalized < $1.name.capitalized }) ?? []
                self?.searchedParticipants = (profiles?.sorted{ $0.name.capitalized < $1.name.capitalized }) ?? []
                self?.participantTableView.reloadData()
            }
        })
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Identifiers.groupCreationPreview {
            let groupCreationPreviewController = segue.destination as! GroupCreationPreviewController
            groupCreationPreviewController.groupCreationDeletgate = groupCreationDeletgate
        }
    }
    
    func checkExistingGroup() {
        if isFromGroupInfo {
            if participants.isEmpty {
                nextButton.alpha = 0.5
            } else {
                nextButton.alpha = 1.0
            }
            nextButton.setTitle("Add", for: .normal)
        } else {
            nextButton.setTitle("Next", for: .normal)
        }
    }
}

// TableViewDelegate
extension AddParticipantsViewController : UITableViewDelegate, UITableViewDataSource {
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchedParticipants.count > 0 {
            return searchedParticipants.count
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if searchedParticipants.count > 0 {
            let cell = (tableView.dequeueReusableCell(withIdentifier: Identifiers.participantCell, for: indexPath) as? ParticipantCell)!
            let profileDetail = searchedParticipants[indexPath.row]
            let name = getUserName(jid: profileDetail.jid,name: profileDetail.name, nickName: profileDetail.nickName, contactType: profileDetail.contactType)
            cell.nameUILabel?.text = name
            cell.statusUILabel?.text = profileDetail.status
            let hashcode = profileDetail.name.hashValue
            let color = getColor(userName: name)
            cell.removeButton?.isHidden = true
            cell.removeIcon?.isHidden = true
            cell.setImage(imageURL: profileDetail.image, name: name, color: color ?? .gray, chatType: profileDetail.profileChatType)
            cell.checkBoxImageView?.image = GroupCreationData.participants.contains(where: {$0.jid == profileDetail.jid}) ?  UIImage(named: ImageConstant.ic_checked) : UIImage(named: ImageConstant.ic_check_box)
            cell.setTextColorWhileSearch(searchText: searchBar.text ?? "", profileDetail: profileDetail)
            cell.emptyView?.isHidden = true
            return cell
        } else {
            let cell = (tableView.dequeueReusableCell(withIdentifier: Identifiers.noResultFound, for: indexPath) as? NoResultFoundCell)!
            return cell
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if searchedParticipants.count > indexPath.row {
            let profileDetail = searchedParticipants[indexPath.row]
            let cell = tableView.cellForRow(at: indexPath) as! ParticipantCell
            let jid = profileDetail.jid ?? ""
            if GroupCreationData.participants.contains(where: {$0.jid == jid}) {
                cell.checkBoxImageView?.image = UIImage(named: ImageConstant.ic_check_box)
                GroupCreationData.participants = groupCreationViewModel.removeSelectedParticipantJid(selectedParticipants: GroupCreationData.participants, participant: profileDetail)
            } else {
                cell.checkBoxImageView?.image = UIImage(named: ImageConstant.ic_checked)
                GroupCreationData.participants.append(profileDetail)
            }
        }
    }
    
    func resetSearch() {
        searchBar.text = ""
        searchedParticipants = groupCreationViewModel.searchContacts(text: "", contacts: participants)
        searchBar.resignFirstResponder()
        dismissKeyboard()
    }
    
    private func getColor(userName : String) -> UIColor {
        return ChatUtils.getColorForUser(userName: userName)
    }
}

extension AddParticipantsViewController : UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String){
        searchedParticipants = groupCreationViewModel.searchContacts(text: searchText.trim(), contacts: participants)
        self.participantTableView.reloadData()
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.text = ""
        searchedParticipants = participants
        self.participantTableView.reloadData()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
}

extension AddParticipantsViewController {
    @objc func contactSyncCompleted(notification: Notification) {
        if let contactSyncState = notification.userInfo?[FlyConstants.contactSyncState] as? String {
            switch ContactSyncState(rawValue: contactSyncState) {
            case .inprogress:
                break
            case .success:
                getContacts()
            case .failed:
                print("contact sync failed")
            case .none:
                print("contact sync failed")
            }
        }
    }
}

extension AddParticipantsViewController : AdminBlockDelegate {
    func didBlockOrUnblockContact(userJid: String, isBlocked: Bool) {
        checkingUserForBlocking(jid: userJid, isBlocked: isBlocked)
    }
    
    func didBlockOrUnblockSelf(userJid: String, isBlocked: Bool) {
       
    }
    
    func didBlockOrUnblockGroup(groupJid: String, isBlocked: Bool) {
        if isFromGroupInfo && groupID == groupJid && isBlocked {
            self.navigationController?.navigationBar.isHidden = false
            self.navigationController?.popToRootViewController(animated: true)
            executeOnMainThread {
                AppAlert.shared.showToast(message: groupNoLongerAvailable)
            }
        }
    }
    
}
// To handle user blocking by admin
extension AddParticipantsViewController {
    
    func checkingUserForBlocking(jid : String, isBlocked : Bool) {
        if isBlocked {
            participants = removeAdminBlockedContact(profileList: participants, jid: jid, isBlockedByAdmin: isBlocked)
            searchedParticipants = removeAdminBlockedContact(profileList: searchedParticipants, jid: jid, isBlockedByAdmin: isBlocked)
            GroupCreationData.participants = removeAdminBlockedContact(profileList: GroupCreationData.participants, jid: jid, isBlockedByAdmin: isBlocked)
        } else {
            participants = addUnBlockedContact(profileList: participants, jid: jid, isBlockedByAdmin: isBlocked)
            searchedParticipants = addUnBlockedContact(profileList: searchedParticipants, jid: jid, isBlockedByAdmin: isBlocked)
        }
        executeOnMainThread { [weak self] in
            self?.participantTableView.reloadData()
        }
    }
    
}

extension AddParticipantsViewController : ProfileEventsDelegate{
    
    func userCameOnline(for jid: String) {
        
    }
    
    func userWentOffline(for jid: String) {
        
    }
    
    func userProfileFetched(for jid: String, profileDetails: ProfileDetails?) {
            
    }
    
    func myProfileUpdated() {
        
    }
    
    func usersProfilesFetched() {
        participantTableView.reloadData()
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
        participantTableView.reloadData()
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
       getContacts()
        if GroupCreationData.participants.contains(where: {$0.jid == jid}) {
            GroupCreationData.participants = groupCreationViewModel.removeSelectedParticipantJid(selectedParticipants: GroupCreationData.participants, participant: profileDetails)
        }
    }
}
