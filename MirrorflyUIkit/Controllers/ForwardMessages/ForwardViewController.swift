//
//  ForwardViewController.swift
//  MirrorflyUIkit
//
//  Created by Sowmiya T on 14/12/21.
//

import UIKit
import FlyCore
import FlyCommon

protocol SendSelectecUserDelegate {
    func sendSelectedUsers(selectedUsers: [Profile],completion: @escaping (() -> Void))
}

class ForwardViewController: UIViewController {
    @IBOutlet weak var forwardTableView: UITableView?
    @IBOutlet weak var segmentControl: UISegmentedControl?
    @IBOutlet weak var searchBar: UISearchBar?
    @IBOutlet weak var descriptionLabel: UILabel?
    @IBOutlet weak var emptyMessageView: UIView?
    @IBOutlet weak var segmentControlView: UIView?
    @IBOutlet weak var sendButton: UIButton?
    
    private var contactViewModel : ContactViewModel?
    private var recentChatViewModel: RecentChatViewModel?
    var getRecentChat: [RecentChat] = []
    var getAllRecentChat: [RecentChat] = []
    var filteredContactList =  [ProfileDetails]()
    var allContactsList =  [ProfileDetails]()
    var isSearchEnabled: Bool = false
    var randomColors = [UIColor?]()
    var segmentSelectedIndex: Int? = 0
    var selectedMessages: [Profile] = []
    var pageDismissClosure:(()-> ())?
    var selectedUserDelegate: SendSelectecUserDelegate? = nil
    var getProfileDetails: ProfileDetails?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        contactViewModel =  ContactViewModel()
        recentChatViewModel = RecentChatViewModel()
        configTableView()
        loadChatList()
        FlyMessenger.shared.messageEventsDelegate = self
        ContactManager.shared.profileDelegate = self
        GroupManager.shared.groupDelegate = self
    }
    
    // MARK: ConfigTableView
    private func configTableView() {
            searchBar?.delegate = self
            forwardTableView?.rowHeight = UITableView.automaticDimension
            forwardTableView?.estimatedRowHeight = 130
            forwardTableView?.delegate = self
            forwardTableView?.dataSource = self
            forwardTableView?.separatorStyle = .none
        let nib = UINib(nibName: Identifiers.participantCell, bundle: Bundle.main)
        forwardTableView?.register(nib, forCellReuseIdentifier: Identifiers.participantCell)
        let recentChatNib = UINib(nibName: Identifiers.recentChatCell, bundle: .main)
        forwardTableView?.register(recentChatNib, forCellReuseIdentifier: Identifiers.recentChatCell)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
        sendButton?.isEnabled = false
        sendButton?.alpha = 0.4
    }
    
    //MARK: API Call
    private func loadChatList() {
        getRecentChatList()
        getContactList()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        navigationController?.isNavigationBarHidden = false
    }
    
    func getLastMesssage() -> [ChatMessage]? {
        var chatMessage: [ChatMessage] = []
        let filteredObj = isSearchEnabled == true ? getRecentChat.filter({$0.lastMessageType == .video || $0.lastMessageType == .image}) : getAllRecentChat.filter({$0.lastMessageType == .video || $0.lastMessageType == .image})
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
    
    @IBAction func closeButtonTapped(_ sender: Any) {
        DispatchQueue.main.async { [weak self] in
            self?.pageDismissClosure?()
            self?.navigationController?.popViewController(animated: true)
        }
    }
    @IBAction func sendButtonTapped(_ sender: Any) {
        if selectedMessages.count == 1 {
            let vc = UIStoryboard.init(name: Storyboards.chat, bundle: Bundle.main).instantiateViewController(withIdentifier: Identifiers.chatViewParentController) as? ChatViewParentController
            switch segmentSelectedIndex {
            case 0:
                let profile = isSearchEnabled == true ? filteredContactList.filter({$0.isSelected == true}).first : allContactsList.filter({$0.isSelected == true}).first
                vc?.getProfileDetails = profile
                let array = isSearchEnabled == true ? filteredContactList : allContactsList
                array.enumerated().forEach { (index,element) in
                    if element.jid == profile?.jid {
                        vc?.contactColor =  randomColors[index] ?? .gray
                    }
                }
            case 1:
                let recentChat = isSearchEnabled == true ? getRecentChat.filter({$0.isSelected == true && $0.profileType == .groupChat}).first : getAllRecentChat.filter({$0.isSelected == true && $0.profileType == .groupChat}).first
                let profile = ProfileDetails(jid: recentChat?.jid ?? "")
                profile.name =  recentChat?.profileName ?? ""
                profile.nickName = recentChat?.nickName ?? ""
                profile.image = recentChat?.profileImage ?? ""
                profile.profileChatType = ChatType(rawValue: recentChat?.profileType.rawValue ?? "") ?? .singleChat
                vc?.getProfileDetails = profile
                let array = isSearchEnabled == true ? getRecentChat.filter({$0.isSelected == true && $0.profileType == .groupChat}) : getAllRecentChat.filter({$0.isSelected == true && $0.profileType == .groupChat})
                array.enumerated().forEach { (index,element) in
                    if element.jid == profile.jid {
                        vc?.contactColor =  randomColors[index] ?? .gray
                    }
                }
              break
            case 2:
                break
            case 3:
                let recentChat = isSearchEnabled == true ? getRecentChat.filter({$0.isSelected == true}).first : getAllRecentChat.filter({$0.isSelected == true}).first
                let profile = ProfileDetails(jid: recentChat?.jid ?? "")
                profile.name =  recentChat?.profileName ?? ""
                profile.nickName = recentChat?.nickName ?? ""
                profile.image = recentChat?.profileImage ?? ""
                profile.profileChatType = ChatType(rawValue: recentChat?.profileType.rawValue ?? "") ?? .singleChat
                vc?.getProfileDetails = profile
                let array = isSearchEnabled == true ? getRecentChat : getAllRecentChat
                array.enumerated().forEach { (index,element) in
                    if element.jid == profile.jid {
                        vc?.contactColor =  randomColors[index] ?? .gray
                    }
                }
            default:
                break
            }
            vc?.isPopToRootVC = true
            selectedUserDelegate?.sendSelectedUsers(selectedUsers: selectedMessages ,completion: { [weak self] in
                    self?.startLoading(withText: "Sending")
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self?.navigationController?.modalPresentationStyle = .fullScreen
                    guard let viewController = vc else { return }
                    self?.navigationController?.pushViewController(viewController, animated: true)
                    self?.stopLoading()
                }
            })
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.selectedUserDelegate?.sendSelectedUsers(selectedUsers: self?.selectedMessages ?? [],completion: { [weak self] in
                    self?.startLoading(withText: "Sending")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self?.navigationController?.popViewController(animated: true)
                        self?.stopLoading()
                    }
                })
            }
        }
    }
    
    @IBAction func SegmentControlValueChanged(_ sender: UISegmentedControl) {
        segmentSelectedIndex = sender.selectedSegmentIndex
        forwardTableView?.reloadData()
        handleEmptyViewWhileSearch()
        // temporarily show empty message by default
        if segmentSelectedIndex == 2 {
            showEmptyMessage()
            descriptionLabel?.text = "No broadcast available"
        }
    }
    
    private func hideEmptyMessage() {
        emptyMessageView?.isHidden = true
    }
    
    private func showEmptyMessage() {
        emptyMessageView?.isHidden = false
        descriptionLabel?.text = "No results found"
    }
    
    private func showHideEmptyMessage(totalCount: Int?) {
        if totalCount ?? 0 == 0 {
            showEmptyMessage()
        } else {
            hideEmptyMessage()
        }
    }
    
    private func handleEmptyViewWhileSearch() {
        switch segmentSelectedIndex {
        case 0:
            showHideEmptyMessage(totalCount: isSearchEnabled == true ? filteredContactList.count : allContactsList.count)
        case 1:
            showHideEmptyMessage(totalCount: isSearchEnabled == true ? getRecentChat.filter({$0.profileType == .groupChat}).count : getAllRecentChat.filter({$0.profileType == .groupChat}).count)
        case 2:
            showHideEmptyMessage(totalCount: 0)
        case 3:
            showHideEmptyMessage(totalCount: isSearchEnabled == true ? getRecentChat.count : getAllRecentChat.count)
        default:
            break
        }
    }
    
    private func refreshMessages() {
        isSearchEnabled = false
        searchBar?.resignFirstResponder()
        searchBar?.setShowsCancelButton(false, animated: true)
        searchBar?.text = ""
        forwardTableView?.reloadData()
    }
}

// TableViewDelegate
extension ForwardViewController : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch segmentSelectedIndex {
        case 0:
            return isSearchEnabled == true ? filteredContactList.count : allContactsList.count
        case 1:
            return isSearchEnabled == true ? getRecentChat.filter({$0.profileType == .groupChat}).count : getAllRecentChat.filter({$0.profileType == .groupChat}).count
        case 2:
           return 0
        case 3:
            return isSearchEnabled == true ? getRecentChat.count : getAllRecentChat.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = (tableView.dequeueReusableCell(withIdentifier: Identifiers.participantCell, for: indexPath) as? ParticipantCell) {
            switch segmentSelectedIndex {
                case 0:
                let contactDetails = isSearchEnabled == true ? filteredContactList[indexPath.row] : allContactsList[indexPath.row]
                cell.nameUILabel?.text = contactDetails.name
                cell.statusUILabel?.text = contactDetails.status
                 let hashcode = contactDetails.name.hashValue
                 let color = randomColors[abs(hashcode) % randomColors.count]
                cell.setImage(imageURL: contactDetails.image, name: contactDetails.name, color: color ?? .gray)
                cell.checkBoxImageView?.image = contactDetails.isSelected ?  UIImage(named: ImageConstant.ic_checked) : UIImage(named: ImageConstant.ic_check_box)
                cell.setTextColorWhileSearch(searchText: searchBar?.text ?? "", profileDetail: contactDetails)
                cell.statusUILabel?.isHidden = false
                cell.removeButton?.isHidden = true
                cell.removeIcon?.isHidden = true
                cell.hideLastMessageContentInfo()
                showHideEmptyMessage(totalCount: isSearchEnabled == true ? filteredContactList.count : allContactsList.count)
                case 1:
                let recentChatDetails = isSearchEnabled == true ? getRecentChat.filter({$0.profileType == .groupChat})[indexPath.row] : getAllRecentChat.filter({$0.profileType == .groupChat})[indexPath.row]
                let hashcode = recentChatDetails.profileName.hashValue
                let color = randomColors[abs(hashcode) % randomColors.count]
                cell.setRecentChatDetails(recentChat: recentChatDetails, color: color ?? .gray)
                cell.hideLastMessageContentInfo()
                showHideEmptyMessage(totalCount: isSearchEnabled == true ? getRecentChat.filter({$0.profileType == .groupChat}).count : getAllRecentChat.filter({$0.profileType == .groupChat}).count)
                case 2:
                showHideEmptyMessage(totalCount: 0)
                case 3:
                let recentChatDetails = isSearchEnabled == true ? getRecentChat[indexPath.row] : getAllRecentChat[indexPath.row]
                let hashcode = recentChatDetails.profileName.hashValue
                let color = randomColors[abs(hashcode) % randomColors.count]
                cell.setRecentChatDetails(recentChat: recentChatDetails, color: color ?? .gray)
                cell.showLastMessageContentInfo()
                if recentChatDetails.profileType == .singleChat {
                    cell.statusUILabel?.text = recentChatDetails.lastMessageType == .text ? recentChatDetails.lastMessageContent : recentChatDetails.lastMessageType?.rawValue
                } else {
                    cell.statusUILabel?.text = recentChatDetails.lastMessageContent
                }
                showHideEmptyMessage(totalCount: isSearchEnabled == true ? getRecentChat.count : getAllRecentChat.count)
                default:
                break
            }
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch segmentSelectedIndex {
        case 0:
            switch isSearchEnabled  {
            case true:
                var profile = Profile()
                profile.profileName = filteredContactList[indexPath.row].name
                profile.jid = filteredContactList[indexPath.row].jid
                profile.isSelected = !(profile.isSelected ?? false)
                if selectedMessages.filter({$0.jid == filteredContactList[indexPath.row].jid}).count == 0  && selectedMessages.count < 5 {
                    getRecentChat.filter({$0.jid == filteredContactList[indexPath.row].jid}).first?.isSelected = true
                    filteredContactList[indexPath.row].isSelected = true
                    selectedMessages.append(profile)
                } else if selectedMessages.filter({$0.jid == filteredContactList[indexPath.row].jid}).count > 0 {
                    selectedMessages.enumerated().forEach({ (index,item) in
                        if item.jid == filteredContactList[indexPath.row].jid {
                            if index <= selectedMessages.count {
                                getRecentChat.filter({$0.jid == filteredContactList[indexPath.row].jid}).first?.isSelected = false
                                filteredContactList[indexPath.row].isSelected = false
                                selectedMessages.remove(at: index)
                            }
                        }
                    })
                } else {
                    AppAlert.shared.showToast(message: ErrorMessage.restrictedforwardUsers)
                }
                forwardTableView?.reloadRows(at: [indexPath], with: .none)
            case false:
                var profile = Profile()
                profile.profileName = allContactsList[indexPath.row].name
                profile.jid = allContactsList[indexPath.row].jid
                profile.isSelected = !(profile.isSelected ?? false)
                if selectedMessages.filter({$0.jid == allContactsList[indexPath.row].jid}).count == 0  && selectedMessages.count < 5 {
                    getAllRecentChat.filter({$0.jid == allContactsList[indexPath.row].jid}).first?.isSelected = true
                    allContactsList[indexPath.row].isSelected = true
                    selectedMessages.append(profile)
                } else if selectedMessages.filter({$0.jid == allContactsList[indexPath.row].jid}).count > 0 {
                    selectedMessages.enumerated().forEach({ (index,item) in
                        if item.jid == allContactsList[indexPath.row].jid {
                            if index <= selectedMessages.count {
                                getAllRecentChat.filter({$0.jid == allContactsList[indexPath.row].jid}).first?.isSelected = false
                                allContactsList[indexPath.row].isSelected = false
                                selectedMessages.remove(at: index)
                            }
                        }
                    })
                } else {
                    AppAlert.shared.showToast(message: ErrorMessage.restrictedforwardUsers)
                }
                forwardTableView?.reloadRows(at: [indexPath], with: .none)
            }
        case 1:
            switch isSearchEnabled  {
            case true:
                var profile = Profile()
                profile.profileName = getRecentChat.filter({$0.profileType == .groupChat})[indexPath.row].profileName
                profile.jid = getRecentChat.filter({$0.profileType == .groupChat})[indexPath.row].jid
                profile.isSelected = !(profile.isSelected ?? false)
                if selectedMessages.filter({$0.jid == getRecentChat.filter({$0.profileType == .groupChat})[indexPath.row].jid}).count == 0  && selectedMessages.count < 5 {
                    getRecentChat.filter({$0.profileType == .groupChat})[indexPath.row].isSelected = true
                    getRecentChat.filter({$0.jid ==  getRecentChat.filter({$0.profileType == .groupChat})[indexPath.row].jid}).first?.isSelected = true
                    selectedMessages.append(profile)
                } else if selectedMessages.filter({$0.jid == getRecentChat.filter({$0.profileType == .groupChat})[indexPath.row].jid}).count > 0 {
                    selectedMessages.enumerated().forEach({ (index,item) in
                        if item.jid == getRecentChat.filter({$0.profileType == .groupChat})[indexPath.row].jid {
                            if index <= selectedMessages.count {
                                getRecentChat.filter({$0.profileType == .groupChat})[indexPath.row].isSelected = false
                                getRecentChat.filter({$0.jid ==  getRecentChat.filter({$0.profileType == .groupChat})[indexPath.row].jid}).first?.isSelected = false
                                selectedMessages.remove(at: index)
                            }
                        }
                    })
                } else {
                    AppAlert.shared.showToast(message: ErrorMessage.restrictedforwardUsers)
                }
                forwardTableView?.reloadRows(at: [indexPath], with: .none)
            case false:
                var profile = Profile()
                profile.profileName = getAllRecentChat.filter({$0.profileType == .groupChat})[indexPath.row].profileName
                profile.jid = getAllRecentChat.filter({$0.profileType == .groupChat})[indexPath.row].jid
                profile.isSelected = !(profile.isSelected ?? false)
                if selectedMessages.filter({$0.jid == getAllRecentChat.filter({$0.profileType == .groupChat})[indexPath.row].jid}).count == 0  && selectedMessages.count < 5 {
                    getAllRecentChat.filter({$0.profileType == .groupChat})[indexPath.row].isSelected = true
                    getAllRecentChat.filter({$0.jid ==  getAllRecentChat.filter({$0.profileType == .groupChat})[indexPath.row].jid}).first?.isSelected = true
                    selectedMessages.append(profile)
                } else if selectedMessages.filter({$0.jid == getAllRecentChat.filter({$0.profileType == .groupChat})[indexPath.row].jid}).count > 0 {
                    selectedMessages.enumerated().forEach({ (index,item) in
                        if item.jid == getAllRecentChat.filter({$0.profileType == .groupChat})[indexPath.row].jid {
                            if index <= selectedMessages.count {
                                getAllRecentChat.filter({$0.profileType == .groupChat})[indexPath.row].isSelected = false
                                getAllRecentChat.filter({$0.jid ==  getAllRecentChat.filter({$0.profileType == .groupChat})[indexPath.row].jid}).first?.isSelected = false
                                selectedMessages.remove(at: index)
                            }
                        }
                    })
                } else {
                    AppAlert.shared.showToast(message: ErrorMessage.restrictedforwardUsers)
                }
                forwardTableView?.reloadRows(at: [indexPath], with: .none)
            }
        case 2:
            break
        case 3:
            switch isSearchEnabled  {
            case true:
                var profile = Profile()
                profile.profileName = getRecentChat[indexPath.row].profileName
                profile.jid = getRecentChat[indexPath.row].jid
                profile.isSelected = !(profile.isSelected ?? false)
                    if selectedMessages.filter({$0.jid == getRecentChat[indexPath.row].jid}).count == 0 && selectedMessages.count < 5 {
                        getRecentChat[indexPath.row].isSelected = true
                        filteredContactList.filter({$0.jid == getRecentChat[indexPath.row].jid}).first?.isSelected = true
                        selectedMessages.append(profile)
                    } else if selectedMessages.filter({$0.jid == getRecentChat[indexPath.row].jid}).count > 0 {
                        selectedMessages.enumerated().forEach({ (index,item) in
                        if item.jid == getRecentChat[indexPath.row].jid {
                            if index <= selectedMessages.count {
                                getRecentChat[indexPath.row].isSelected = false
                                filteredContactList.filter({$0.jid == getRecentChat[indexPath.row].jid}).first?.isSelected = false
                                selectedMessages.remove(at: index)
                            }
                        }
                        })
                    } else {
                        AppAlert.shared.showToast(message: ErrorMessage.restrictedforwardUsers)
                    }
                forwardTableView?.reloadRows(at: [indexPath], with: .none)
            case false:
                var profile = Profile()
                profile.profileName = getAllRecentChat[indexPath.row].profileName
                profile.jid = getAllRecentChat[indexPath.row].jid
                profile.isSelected = !(profile.isSelected ?? false)
                if selectedMessages.filter({$0.jid == getAllRecentChat[indexPath.row].jid}).count == 0  && selectedMessages.count < 5 {
                    getAllRecentChat[indexPath.row].isSelected = true
                    allContactsList.filter({$0.jid == getAllRecentChat[indexPath.row].jid}).first?.isSelected = true
                    selectedMessages.append(profile)
                } else if selectedMessages.filter({$0.jid == getAllRecentChat[indexPath.row].jid}).count > 0 {
                    selectedMessages.enumerated().forEach({ (index,item) in
                        if item.jid == getAllRecentChat[indexPath.row].jid {
                            if index <= selectedMessages.count {
                                getAllRecentChat[indexPath.row].isSelected = false
                                allContactsList.filter({$0.jid == getAllRecentChat[indexPath.row].jid}).first?.isSelected = false
                                selectedMessages.remove(at: index)
                            }
                        }
                    })
                } else {
                    AppAlert.shared.showToast(message: ErrorMessage.restrictedforwardUsers)
                }
                forwardTableView?.reloadRows(at: [indexPath], with: .none)
            }
        default:
            break
        }
        sendButton?.isEnabled = selectedMessages.count == 0 ? false : true
        sendButton?.alpha = selectedMessages.count == 0 ? 0.4 : 1.0
    }
}

// SearchBar Delegate Method
extension ForwardViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.trim().count > 0 {
            isSearchEnabled = true
            getRecentChat = searchText.isEmpty ? getAllRecentChat : getAllRecentChat.filter({ recentChat -> Bool in
                return recentChat.profileName.capitalized.range(of: searchText.trim().capitalized, options: [.caseInsensitive, .diacriticInsensitive]) != nil ||
                recentChat.lastMessageContent.capitalized.range(of: searchText.trim().capitalized, options: [.caseInsensitive, .diacriticInsensitive]) != nil
            })
            filteredContactList = searchText.isEmpty ? allContactsList : allContactsList.filter({ contact -> Bool in
                return contact.name.capitalized.range(of: searchText.trim().capitalized, options: [.caseInsensitive, .diacriticInsensitive]) != nil
            })
            handleEmptyViewWhileSearch()
        } else {
            segmentControlView?.isHidden = false
            isSearchEnabled = false
            getRecentChatList()
            getContactList()
        }
        forwardTableView?.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        segmentControlView?.isHidden = false
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        refreshMessages()
        segmentControlView?.isHidden = false
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
        segmentControlView?.isHidden = true
    }
}

// getChatList Method
extension ForwardViewController {
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
                    weakSelf.allContactsList = weakSelf.allContactsList.sorted { $0.name.capitalized < $1.name.capitalized }
                    
                    weakSelf.allContactsList.enumerated().forEach { (index,contact) in
                        if  weakSelf.selectedMessages.filter({$0.jid == contact.jid}).count > 0 {
                            weakSelf.allContactsList[index].isSelected = (weakSelf.selectedMessages.filter({$0.jid == contact.jid}).first?.isSelected ?? false)
                        }
                    }
                    
                    weakSelf.filteredContactList.enumerated().forEach { (index,contact) in
                        if  weakSelf.selectedMessages.filter({$0.jid == contact.jid}).count > 0 {
                            weakSelf.filteredContactList[index].isSelected = (weakSelf.selectedMessages.filter({$0.jid == contact.jid}).first?.isSelected ?? false)
                        }
                    }
                    weakSelf.forwardTableView?.reloadData()
                    
                }
            }
        }
        handleEmptyViewWhileSearch()
    }
    
    func getRecentChatList() {
        recentChatViewModel?.getRecentChatList(isBackground: false, completionHandler: { [weak self] recentChatList in
            if let weakSelf = self {
                if weakSelf.isSearchEnabled == false {
                    weakSelf.getRecentChat = recentChatList ?? []
                    weakSelf.getAllRecentChat = weakSelf.getRecentChat
                    
                    weakSelf.getAllRecentChat.enumerated().forEach { (index,contact) in
                        if  weakSelf.selectedMessages.filter({$0.jid == contact.jid}).count > 0 {
                            weakSelf.getAllRecentChat[index].isSelected = (weakSelf.selectedMessages.filter({$0.jid == contact.jid}).first?.isSelected ?? false)
                        }
                    }
                    
                    weakSelf.getRecentChat.enumerated().forEach { (index,contact) in
                        if  weakSelf.selectedMessages.filter({$0.jid == contact.jid}).count > 0 {
                            weakSelf.getRecentChat[index].isSelected = (weakSelf.selectedMessages.filter({$0.jid == contact.jid}).first?.isSelected ?? false)
                        }
                    }
                }
            }
        })
        randomColors = AppUtils.shared.setRandomColors(totalCount: getRecentChat.count)
        if isSearchEnabled == false {
            forwardTableView?.reloadData()
        }
        handleEmptyViewWhileSearch()
    }
}

extension ForwardViewController : ProfileEventsDelegate {
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
    
    func userBlockedMe(jid: String) {
        
    }
    
    func userUnBlockedMe(jid: String) {
        
    }
    
    func hideUserLastSeen() {
        
    }
    
    func getUserLastSeen() {
        
    }
    
func userUpdatedTheirProfile(for jid: String, profileDetails: ProfileDetails) {
    print("userUpdatedTheirProfile \(jid)")
    switch segmentSelectedIndex {
    case 0:
        let profileDatas =  isSearchEnabled == true ? filteredContactList.filter({ ($0.jid.contains(jid)) }) : allContactsList.filter({ ($0.jid.contains(jid)) })
        if profileDatas.count > 0, let profileData = profileDatas.first  {
            if isSearchEnabled == true {
                if  let index = filteredContactList.firstIndex(of: profileData) {
                    filteredContactList[index].image = profileDetails.image
                    filteredContactList[index].name = profileDetails.name
                    filteredContactList[index].status = profileDetails.status
            }
            } else {
                    if  let index = allContactsList.firstIndex(of: profileData) {
                        allContactsList[index].image = profileDetails.image
                        allContactsList[index].name = profileDetails.name
                        allContactsList[index].status = profileDetails.status
                }
            }
                let profile = ["jid": profileDetails.jid, "name": profileDetails.name, "image": profileDetails.image, "status": profileDetails.status]
                NotificationCenter.default.post(name: Notification.Name(Identifiers.ncProfileUpdate), object: nil, userInfo: profile as [AnyHashable : Any])
                forwardTableView?.reloadData()
            }
    case 1:
        let profileDatas =  isSearchEnabled == true ? getRecentChat.filter({$0.profileType == .groupChat}).filter({ ($0.jid.contains(jid)) }) : getAllRecentChat.filter({$0.profileType == .groupChat}).filter({ ($0.jid.contains(jid)) })
        if profileDatas.count > 0, let profileData = profileDatas.first  {
            if isSearchEnabled == true {
                if  let index = getRecentChat.filter({$0.profileType == .groupChat}).firstIndex(of: profileData) {
                    getRecentChat.filter({$0.profileType == .groupChat})[index].profileImage = profileDetails.image
                    getRecentChat.filter({$0.profileType == .groupChat})[index].profileName = profileDetails.name
                }
            } else {
                    if  let index = getAllRecentChat.filter({$0.profileType == .groupChat}).firstIndex(of: profileData) {
                        getAllRecentChat.filter({$0.profileType == .groupChat})[index].profileImage = profileDetails.image
                        getAllRecentChat.filter({$0.profileType == .groupChat})[index].profileName = profileDetails.name
                }
            }
                let profile = ["jid": profileDetails.jid, "name": profileDetails.name, "image": profileDetails.image, "status": profileDetails.status]
                NotificationCenter.default.post(name: Notification.Name(Identifiers.ncProfileUpdate), object: nil, userInfo: profile as [AnyHashable : Any])
                forwardTableView?.reloadData()
            }
    case 3:
        let profileDatas =  isSearchEnabled == true ? getRecentChat : getAllRecentChat
        if profileDatas.count > 0, let profileData = profileDatas.first  {
            if isSearchEnabled == true {
                if  let index = getRecentChat.firstIndex(of: profileData) {
                    getRecentChat[index].profileImage = profileDetails.image
                    getRecentChat[index].profileName = profileDetails.name
                }
            } else {
                    if  let index = getAllRecentChat.firstIndex(of: profileData) {
                        getAllRecentChat[index].profileImage = profileDetails.image
                        getAllRecentChat[index].profileName = profileDetails.name
                }
            }
                let profile = ["jid": profileDetails.jid, "name": profileDetails.name, "image": profileDetails.image, "status": profileDetails.status]
                NotificationCenter.default.post(name: Notification.Name(Identifiers.ncProfileUpdate), object: nil, userInfo: profile as [AnyHashable : Any])
                forwardTableView?.reloadData()
            }
        default:
            break
        }
    }
}

extension ForwardViewController : GroupEventsDelegate {
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
    
    func didFetchGroups(groups: [ProfileDetails]) {
        
    }
    
    func didFetchGroupMembers(groupJid: String) {
        
    }
    
    func didReceiveGroupNotificationMessage(message: ChatMessage) {
        
    }
    
    func didFetchGroupProfile(groupJid: String) {
        print("RecentChatViewController didGroupProfileFetch \(groupJid)")
        DispatchQueue.main.async { [weak self] in
                self?.loadChatList()
        }
    }
    
    func didUpdateGroupProfile(groupJid: String) {
        let array = isSearchEnabled == true ? getRecentChat.filter({$0.profileType == .groupChat}) : getAllRecentChat.filter({$0.profileType == .groupChat})
        
        let group = GroupManager.shared.getAGroupFromLocal(groupJid: groupJid)
        DispatchQueue.main.async { [weak self] in
            array.enumerated().forEach { (index, element) in
                if element.jid == groupJid {
                    if self?.isSearchEnabled == true {
                        self?.getRecentChat[index].profileName = (group?.name ?? group?.nickName) ?? ""
                        self?.getRecentChat[index].profileImage = group?.image
                    } else {
                        self?.getAllRecentChat[index].profileName = (group?.name ?? group?.nickName) ?? ""
                        self?.getAllRecentChat[index].profileImage = group?.image
                    }
                    self?.forwardTableView?.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                }
            }
        }
    }
}

// MessageEventDelegate
extension ForwardViewController : MessageEventsDelegate {
    func onMessageStatusUpdated(messageId: String, chatJid: String, status: MessageStatus) {
        if isSearchEnabled == false {
            refreshMessages()
        }
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
        refreshMessages()
    }
}
