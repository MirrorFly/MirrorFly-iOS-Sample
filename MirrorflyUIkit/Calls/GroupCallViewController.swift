//
//  GroupCallViewController.swift
//  MirrorFlyiOS-SDK
//
//  Created by User on 20/07/21.
//

import UIKit
import RealmSwift
import FlyCall
import FlyDatabase
import FlyCommon
import Alamofire
import FlyCore

class GroupCallViewController: UIViewController {
    
    @IBOutlet weak var imgOneLeading: NSLayoutConstraint!
    var callLog = RealmCallLog()
    let rosterManager = RosterManager()
    var callUserProfiles = [ProfileDetails]()
    var groupCallName = String()
    var callTime = String()
    var callDuration = String()
    let callLogManager = CallLogManager()
    @IBOutlet weak var groupCallNameLbl: UILabel!
    @IBOutlet weak var callDurationLbl: UILabel!
    @IBOutlet weak var callTimeLbl: UILabel!
    @IBOutlet weak var groupDetailTblView: UITableView!
    @IBOutlet weak var callStateImg: UIImageView!
    @IBOutlet weak var callInitiateBtn: UIButton!
    @IBOutlet weak var imgOne: UIImageView!
    @IBOutlet weak var imgTwo: UIImageView!
    @IBOutlet weak var imgThree: UIImageView!
    @IBOutlet weak var imgFour: UIImageView!
    @IBOutlet weak var plusCountLbl: UILabel!
    var contactJidArr = NSMutableArray()
    var isGroup = false
    @IBOutlet weak var imgeOneHeight: NSLayoutConstraint!
    @IBOutlet weak var imgOneWidth: NSLayoutConstraint!
    override func viewDidLoad() {
        super.viewDidLoad()
        print(callLog)
        let userString = callLog["userList"] as? String ?? ""
        var userList = userString.components(separatedBy: ",")
        userList.removeAll { jid in
            jid == FlyDefaults.myJid
        }
        let fullNameArr = userList
        for JID in fullNameArr{
            if let contact = rosterManager.getContact(jid: JID){
                callUserProfiles.append(contact)
                contactJidArr.add(JID)
            }
        }
        imgOne.layer.cornerRadius = imgOne.frame.size.height / 2
        imgOne.layer.masksToBounds = true
        
        imgThree.layer.cornerRadius = imgThree.frame.size.height / 2
        imgThree.layer.masksToBounds = true
        
        imgTwo.layer.cornerRadius = imgTwo.frame.size.height / 2
        imgTwo.layer.masksToBounds = true
        
        imgFour.layer.cornerRadius = imgFour.frame.size.height / 2
        imgFour.layer.masksToBounds = true
        
        
        if isGroup{
            imgOneWidth.constant = 60
            imgeOneHeight.constant = 60
            imgOne.layer.cornerRadius = 30
            imgOne.layer.masksToBounds = true
            imgTwo.isHidden = true
            imgThree.isHidden = true
            imgFour.isHidden = true
            plusCountLbl.isHidden = true
            if let contact = rosterManager.getContact(jid: callLog.groupId!){
                imgOne.loadFlyImage(imageURL: contact.image, name:  getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType), chatType: contact.profileChatType ,contactType: contact.contactType, jid: contact.jid)
            }
        }else{
            loadImagesForMutiUserCall()
        }
        
        if callLog["callType"] as! String == "audio"{
            callInitiateBtn.setImage(UIImage.init(named: "audio_call"), for: .normal)
        }else {
            callInitiateBtn.setImage(UIImage.init(named: "VideoType"), for: .normal)
        }
        if callLog["callState"] as! String == "Inco as! StringmingCall"{
            callStateImg.image = UIImage.init(named: "incomingCall")
        }else if callLog["callState"] as! String == "OutgoingCall"{
            callStateImg.image = UIImage.init(named: "outGoing")
        }else{
            callStateImg.image = UIImage.init(named: "missedCall")
        }
        groupCallNameLbl.text = groupCallName
        callDurationLbl.text = callDuration
        callTimeLbl.text = callTime
        groupDetailTblView.tableFooterView = UIView()
        groupDetailTblView.reloadData()
        callInitiateBtn.addTarget(self, action: #selector(buttonClicked(sender:)), for: .touchUpInside)
        // memberCell?.contactNamelabel.text = contactArr.componentsJoined(by: ",")
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        ContactManager.shared.profileDelegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        ContactManager.shared.profileDelegate = nil
    }
    
    @IBAction func backAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func deleteAction(_ sender: Any) {
        let url = Utility.appendBaseURL(restEnd: "users/callLogs")
        var headers: HTTPHeaders = ["Content-Type": "application/json", "Accept": "application/json"]
        var parametersDictionary: [String : Any]?
        
        parametersDictionary = [
            "roomId": [callLog["callId"]]
        ]
        
        let authToken = FlyCallUtils.sharedInstance.getConfigUserDefault(forKey: "token") as? String ?? ""
        if authToken.count > 0 {
            headers.add(name: "Authorization", value: authToken)
        }
        AF.request(URL(string: url)!,method: .delete,parameters:parametersDictionary ,encoding: JSONEncoding.default,headers: headers).validate(statusCode: 200..<300).responseJSON { [self] response in
            print(response.result)
            switch response.result {
            case .success(_):
                if response.response?.statusCode == 200 {
                    callLogManager.deleteSingleCallLogs(callLog:callLog)
                    self.navigationController?.popViewController(animated: true)
                }else {
                }
            case .failure(_) :
                let _ : String
                if let httpStatusCode = response.response?.statusCode {
                }
            }
        }
    }
    
    @objc func buttonClicked(sender: UIButton) {
        if CallManager.isAlreadyOnAnotherCall(){
            AppAlert.shared.showToast(message: "You’re already on call, can't make new Mirrorfly call")
            return
        }
        let userString = callLog["userList"] as? String ?? ""
        let fullNameArr = userString.components(separatedBy: ",")
        var callUserProfiles = [ProfileDetails]()
        for JID in fullNameArr{
            if let contact = rosterManager.getContact(jid: JID){
                if contact.contactType != .deleted{
                    callUserProfiles.append(contact)
                }
            }
        }
        if callLog["callType"] as! String == "audio"{
            RootViewController.sharedInstance.callViewController?.makeCall(usersList: callUserProfiles.compactMap{$0.jid}, callType: .Audio, groupId: callLog.groupId ?? emptyString())
        }
        else{
            RootViewController.sharedInstance.callViewController?.makeCall(usersList: callUserProfiles.compactMap{$0.jid}, callType: .Video, groupId: callLog.groupId ?? emptyString())
        }
    }
    
    func loadImagesForMutiUserCall(){
        let userString = callLog["userList"] as? String ?? ""
        var userList = userString.components(separatedBy: ",")
        userList.removeAll { jid in
            jid == FlyDefaults.myJid
        }
        
        if contactJidArr.count == 2{
            imgTwo.isHidden = true
            imgOneLeading.constant = 10
            imgThree.isHidden = true
            imgFour.isHidden = false
            plusCountLbl.isHidden = true
            for i in 0...contactJidArr.count - 1{
                if let contact = rosterManager.getContact(jid: contactJidArr[i] as! String){
                    if i == 0{
                        imgOne.loadFlyImage(imageURL: contact.image, name:  getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType), contactType: contact.contactType, jid: contact.jid)
                    }
                    if i == 1{
                        imgFour.loadFlyImage(imageURL: contact.image, name:  getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType), contactType: contact.contactType, jid: contact.jid)
                    }
                }
            }
            
        }else if contactJidArr.count == 3{
            for i in 0...contactJidArr.count - 1{
                if let contact = rosterManager.getContact(jid: contactJidArr[i] as! String){
                    if i == 0{
                        imgOne.loadFlyImage(imageURL: contact.image, name:  getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType), contactType: contact.contactType, jid: contact.jid)
                    }
                    if i == 1{
                        imgThree.loadFlyImage(imageURL: contact.image, name:  getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType), contactType: contact.contactType, jid: contact.jid)
                    }
                    if i == 2{
                        imgFour.loadFlyImage(imageURL: contact.image, name:  getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType), contactType: contact.contactType, jid: contact.jid)
                    }
                }
            }
            imgTwo.isHidden = true
            imgOneLeading.constant = 15
            imgThree.isHidden = false
            imgFour.isHidden = false
            plusCountLbl.isHidden = true
            
        }else if contactJidArr.count == 4{
            for i in 0...contactJidArr.count - 1{
                if let contact = rosterManager.getContact(jid: contactJidArr[i] as! String){
                    if i == 0{
                        imgOne.loadFlyImage(imageURL: contact.image, name:  getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType), contactType: contact.contactType, jid: contact.jid)
                    }
                    if i == 1{
                        imgTwo.loadFlyImage(imageURL: contact.image, name:  getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType), contactType: contact.contactType, jid: contact.jid)
                    }
                    if i == 2{
                        imgThree.loadFlyImage(imageURL: contact.image, name:  getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType), contactType: contact.contactType, jid: contact.jid)
                    }
                    if i == 3{
                        imgFour.loadFlyImage(imageURL: contact.image, name:  getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType), contactType: contact.contactType, jid: contact.jid)
                    }
                }
            }
            imgTwo.isHidden = false
            imgThree.isHidden = false
            imgFour.isHidden = false
            plusCountLbl.isHidden = true
            
        }else if contactJidArr.count != 0{
            imgOne.isHidden = false
            imgTwo.isHidden = false
            imgThree.isHidden = false
            imgFour.isHidden = false
            plusCountLbl.isHidden = false
            plusCountLbl.text =  "+ " + "\(userList.count - 4)"
            for i in 0...contactJidArr.count - 1{
                if let contact = rosterManager.getContact(jid: contactJidArr[i] as! String){
                    if i == 0{
                        imgOne.loadFlyImage(imageURL: contact.image, name: getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType), contactType: contact.contactType, jid: contact.jid)
                    }
                    if i == 1{
                        imgTwo.loadFlyImage(imageURL: contact.image, name:  getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType), contactType: contact.contactType, jid: contact.jid)
                    }
                    if i == 2{
                        imgThree.loadFlyImage(imageURL: contact.image, name:  getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType), contactType: contact.contactType, jid: contact.jid)
                    }
                    if i == 3{
                        imgFour.loadFlyImage(imageURL: contact.image, name:  getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType), contactType: contact.contactType, jid: contact.jid)
                    }
                }
            }
        }
    }
}

extension GroupCallViewController : UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return callUserProfiles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let memberCell = tableView.dequeueReusableCell(withIdentifier: "CCFGroupCallLogListCell") as? CCFGroupCallLogListCell
        let contact = callUserProfiles[indexPath.row]
        memberCell?.userImageView.layer.cornerRadius = (memberCell?.userImageView.frame.size.height)!/2
        memberCell?.userImageView.layer.masksToBounds = true
        memberCell?.userImageView.loadFlyImage(imageURL: contact.image, name: getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType), contactType: contact.contactType, jid: contact.jid)
        memberCell?.contactNamelabel.text = getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType)
        return memberCell!
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
    
}

extension GroupCallViewController : ProfileEventsDelegate {
    
    func userCameOnline(for jid: String) {
        
    }
    
    func userWentOffline(for jid: String) {
        
    }
    
    func userProfileFetched(for jid: String, profileDetails: ProfileDetails?) {
        
    }
    
    func myProfileUpdated() {
        
    }
    
    func usersProfilesFetched() {
        let userString = callLog["userList"] as? String ?? ""
        var userList = userString.components(separatedBy: ",")
        userList.removeAll { jid in
            jid == FlyDefaults.myJid
        }
        callUserProfiles.removeAll()
        for JID in userList{
            if let contact = rosterManager.getContact(jid: JID){
                callUserProfiles.append(contact)
            }
        }
        let contactArr = NSMutableArray()
        for contact in callUserProfiles{
            contactArr.add(getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType))
        }
        if isGroup{
            groupCallNameLbl.text = groupCallName
        }else{
            groupCallNameLbl.text = contactArr.componentsJoined(by: ",")
            loadImagesForMutiUserCall()
        }
        groupDetailTblView.reloadData()
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
        
    }
    
    func userBlockedMe(jid: String) {
        
    }
    
    func userUnBlockedMe(jid: String) {
        
    }
    
    func hideUserLastSeen() {
        
    }
    
    func getUserLastSeen() {
        
    }
    
    func userDeletedTheirProfile(for jid: String, profileDetails: ProfileDetails) {
        if let index = callUserProfiles.firstIndex(where: { pd in pd.jid == jid }) {
            callUserProfiles[index] = profileDetails
            let indexPath = IndexPath(item: index, section: 0)
            groupDetailTblView?.reloadRows(at: [indexPath], with: .fade)
            let contactArr = NSMutableArray()
            for contact in callUserProfiles{
                contactArr.add(getUserName(jid : contact.jid ,name: contact.name, nickName: contact.nickName, contactType: contact.contactType))
            }
            if !isGroup{
                groupCallNameLbl.text = contactArr.componentsJoined(by: ",")
                loadImagesForMutiUserCall()
            }
        }
    }
    
    
}

class CCFGroupCallLogListCell: UITableViewCell {
    ///  This object is used display the contact name in list
    @IBOutlet var contactNamelabel: UILabel!
    /// It is used to differentiate mail contact and phone contact
    ///  This object is used to display the contact profile image in list
    @IBOutlet var userImageView: UIImageView!
    ///  This object is used to make multiple selection from the listed contact
    @IBOutlet weak var callStatusBtn: UIImageView!
    @IBOutlet var callInitiateBtn: UIButton!
    ///  This object is used to make delete member from the listed contact
    @IBOutlet weak var callDateandTimeLabel: UILabel!
    
    @IBOutlet weak var callDurationLbl: UILabel!
    override class func awakeFromNib() {
        super.awakeFromNib()
        
    }
}

