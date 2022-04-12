//
//  callLogViewController.swift
//  MirrorFlyiOS-SDK
//
//  Created by User on 14/07/21.
//

import UIKit
import FlyCall
import FlyCommon
import FlyCore
import FlyDatabase
import Alamofire
import RealmSwift
import Floaty

class callLogViewController: UIViewController, RequestInterceptor {
    
    @IBOutlet weak var callLogTableView: UITableView!
    let callLogManager = CallLogManager()
    var CallLogArray = [Any]()
    let rosterManager = RosterManager()
    var callLog = RealmCallLog()
    let button = UIButton(type: UIButton.ButtonType.custom) as UIButton
    var isClearAll = Bool()
    @IBOutlet weak var deleteAllBtn: UIButton!
    fileprivate var shownImagesCount = 4
    var layoutNumberOfColomn: Int = 2
    let imageArr = NSMutableArray()
    var groupCallViewController : GroupCallViewController?
    var callLogRealm = RealmCallLog()
    var floaty : Floaty? = nil

    @IBOutlet weak var noCallLogView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(updateCallCount), name: NSNotification.Name("updateCallCount"), object: nil)
        noCallLogView.isHidden = false
        // Do any additional setup after loading the view.
    }
   
    override func viewWillAppear(_ animated: Bool) {
        getsyncedLogs()
        postUnSyncedLogs()
        CallLogArray = CallLogManager.getCallLogs()
        deleteAllBtn.isHidden = CallLogArray.count > 0 ? false : true
        floaty = Floaty(frame:  CGRect(x: (view.bounds.maxX - 68), y:  (view.bounds.maxY - 160), width: 56, height: 56))
        floaty?.addItem("", icon: UIImage(named: "audio_call")!, handler: { item in
            let storyboard = UIStoryboard.init(name: Storyboards.main, bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: Identifiers.contactViewController) as! ContactViewController
            controller.modalPresentationStyle = .fullScreen
            controller.makeCall = true
            controller.isMultiSelect = true
            controller.callType = .Audio
            controller.hideNavigationbar = true
            self.navigationController?.pushViewController(controller, animated: true)
            self.floaty?.close()
        })
        floaty?.addItem("", icon: UIImage(named: "VideoType")!, handler: { item in
            let storyboard = UIStoryboard.init(name: Storyboards.main, bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: Identifiers.contactViewController) as! ContactViewController
            controller.modalPresentationStyle = .fullScreen
            controller.makeCall = true
            controller.isMultiSelect = true
            controller.callType = .Video
            controller.hideNavigationbar = true
            self.navigationController?.pushViewController(controller, animated: true)
            self.floaty?.close()
        })
        if let floaty = floaty {
            view.addSubview(floaty)
        }
        callLogTableView.tableFooterView = UIView()
        callLogTableView.reloadData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if let floaty = floaty {
            floaty.removeFromSuperview()
        }
    }
   
    @objc func appDidBecomeActive(){
        getsyncedLogs()
        // postUnSyncedLogs()
    }
    
    @objc func updateCallCount(){
        //postUnSyncedLogs()
        CallLogArray = CallLogManager.getCallLogs()
        let lastCallLog = CallLogArray.first as? RealmCallLog
        if let callTime = lastCallLog?["callTime"] {
            FlyCallUtils.sharedInstance.setConfigUserDefaults(callTime, withKey: "LastMissedCallTime")
        }
        self.setMissedCallCount()
    }
    
    @IBAction func deleteAllCallLogs(_ sender: Any) {
        isClearAll = true
        deleteCallLogs()
    }
}

// MARK: Table View Methods
extension callLogViewController : UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        CallLogArray = CallLogManager.getCallLogs()
        print("calllog array issss" , CallLogArray)
//        if CallLogArray.count == 0{
//            let noDataLabel: UILabel  = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
//            noDataLabel.text          = "No call log history found \n Any new calls will appear here "
//            noDataLabel.textColor     = UIColor.black
//            noDataLabel.numberOfLines = 0
//            noDataLabel.textAlignment = .center
//            noDataLabel.lineBreakMode = .byWordWrapping
//            tableView.backgroundView  = noDataLabel
//            tableView.separatorStyle  = .none
//        }
        return CallLogArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let memberCell = tableView.dequeueReusableCell(withIdentifier: "CCFCallLogListCell") as? CCFCallLogListCell
        memberCell?.callInitiateBtn.isUserInteractionEnabled = true
        memberCell?.callInitiateBtn.tag = indexPath.row
        memberCell?.callInitiateBtn.addTarget(self, action: #selector(buttonClicked(sender:)), for: .touchUpInside)
        if let callLog = CallLogArray[indexPath.row] as? RealmCallLog{
            if callLog["callMode"] as? String == "onetoone" || callLog["callMode"] as? String == ""{
                memberCell?.groupView.isHidden = true
                memberCell?.userImageView.isHidden = false
                var jidString = String()
                if callLog["fromUser"] as! String == FlyDefaults.myJid{
                    jidString = callLog["toUser"] as! String
                }else{
                    jidString = callLog["fromUser"] as! String
                }
                if let contact = rosterManager.getContact(jid: jidString){
                    memberCell?.contactNamelabel.text = getUserName(name: contact.name, nickName: contact.nickName)
                    memberCell?.userImageView.layer.cornerRadius = (memberCell?.userImageView.frame.size.height)!/2
                    memberCell?.userImageView.layer.masksToBounds = true
                    
                    Utility.download(token: contact.image, profileImage: (memberCell?.userImageView)!, uniqueId:jidString,name :contact.name,colorCode: contact.colorCode,frameSize:50,fontSize:18, completion: {})
                }
            }else{
                memberCell?.imgOne.layer.cornerRadius = (memberCell?.imgOne.frame.size.height)! / 2
                memberCell?.imgOne.layer.masksToBounds = true
                
                memberCell?.imgThree.layer.cornerRadius = (memberCell?.imgThree.frame.size.height)! / 2
                memberCell?.imgThree.layer.masksToBounds = true
                
                memberCell?.imgTwo.layer.cornerRadius = (memberCell?.imgTwo.frame.size.height)! / 2
                memberCell?.imgTwo.layer.masksToBounds = true
                
                memberCell?.imgFour.layer.cornerRadius = (memberCell?.imgFour.frame.size.height)! / 2
                memberCell?.imgFour.layer.masksToBounds = true
                
                memberCell?.groupView.isHidden = false
                memberCell?.userImageView.isHidden = true
                let userString = callLog["userList"] as? String ?? ""
                var userList = userString.components(separatedBy: ",")
                userList.removeAll { jid in
                    jid == FlyDefaults.myJid
                }
                let fullNameArr = userList
                let contactArr = NSMutableArray()
                let contactJidArr = NSMutableArray()
                for JID in fullNameArr{
                    if let contact = rosterManager.getContact(jid: JID){
                        contactArr.add(getUserName(name: contact.name, nickName: contact.nickName))
                        contactJidArr.add(JID)
                    }
                }
                if callLog.groupId?.count ?? 0 > 0 {
                    memberCell?.contactNamelabel.text = rosterManager.getGroupName(jid: callLog.groupId!)
                }
                else {
                memberCell?.contactNamelabel.text = contactArr.componentsJoined(by: ",")
                }
                if contactJidArr.count == 1{
                    
                }
                else if contactJidArr.count == 2{
                    memberCell?.imgTwo.isHidden = true
                    memberCell?.leadingConstant.constant = 10
                    memberCell?.imgThree.isHidden = true
                    memberCell?.imgFour.isHidden = false
                    memberCell?.plusCountLbl.isHidden = true
                    for i in 0...contactJidArr.count - 1{
                        if let contact = rosterManager.getContact(jid: contactJidArr[i] as! String){
                            if i == 0{
                               
                                Utility.download(token: contact.image, profileImage: (memberCell?.imgOne)!, uniqueId: contactJidArr[i] as! String,name :contact.name,colorCode: contact.colorCode,frameSize:50,fontSize:14, completion: {})
                                
                            }
                            if i == 1{
                               
                                Utility.download(token: contact.image, profileImage: (memberCell?.imgFour)!, uniqueId: contactJidArr[i] as! String,name :contact.name,colorCode: contact.colorCode,frameSize:50,fontSize:14, completion: {})
                               
                            }
                        }
                    }
                      
                }else if contactJidArr.count == 3{
                    for i in 0...contactJidArr.count - 1{
                        if let contact = rosterManager.getContact(jid: contactJidArr[i] as! String){
                            if i == 0{
                                Utility.download(token: contact.image, profileImage: (memberCell?.imgOne)!, uniqueId: contactJidArr[i] as! String,name :contact.name,colorCode: contact.colorCode,frameSize:50,fontSize:14, completion: {})
                            }
                            if i == 1{
                                Utility.download(token: contact.image, profileImage: (memberCell?.imgThree)!, uniqueId: contactJidArr[i] as! String,name :contact.name,colorCode: contact.colorCode,frameSize:50,fontSize:14, completion: {})
                            }
                            
                            if i == 2{
                                Utility.download(token: contact.image, profileImage: (memberCell?.imgFour)!, uniqueId: contactJidArr[i] as! String,name :contact.name,colorCode: contact.colorCode,frameSize:50,fontSize:14, completion: {})
                            }
                        }
                    }
                    memberCell?.imgTwo.isHidden = true
                    memberCell?.leadingConstant.constant = 15
                    memberCell?.imgThree.isHidden = false
                    memberCell?.imgFour.isHidden = false
                    memberCell?.plusCountLbl.isHidden = true

                }else if contactJidArr.count == 4{
                    for i in 0...contactJidArr.count - 1{
                        if let contact = rosterManager.getContact(jid: contactJidArr[i] as! String){
                            if i == 0{
                                Utility.download(token: contact.image, profileImage: (memberCell?.imgOne)!, uniqueId: contactJidArr[i] as! String,name :contact.name,colorCode: contact.colorCode,frameSize:50,fontSize:14, completion: {})
                            }
                            else if i == 1{
                                Utility.download(token: contact.image, profileImage: (memberCell?.imgTwo)!, uniqueId: contactJidArr[i] as! String,name :contact.name,colorCode: contact.colorCode,frameSize:50,fontSize:14, completion: {})
                            }
                            
                            else if i == 2{
                                Utility.download(token: contact.image, profileImage: (memberCell?.imgThree)!, uniqueId: contactJidArr[i] as! String,name :contact.name,colorCode: contact.colorCode,frameSize:50,fontSize:14, completion: {})
                            }
                            else if i == 3{
                                Utility.download(token: contact.image, profileImage: (memberCell?.imgFour)!, uniqueId: contactJidArr[i] as! String,name :contact.name,colorCode: contact.colorCode,frameSize:50,fontSize:14, completion: {})
                            }
                            else {
                                break
                            }
                        }
                    }
                    memberCell?.imgTwo.isHidden = false
                    memberCell?.leadingConstant.constant = 0
                    memberCell?.imgThree.isHidden = false
                    memberCell?.imgFour.isHidden = false
                    memberCell?.plusCountLbl.isHidden = true

                }else if contactJidArr.count != 0{
                    memberCell?.imgOne.isHidden = false
                    memberCell?.imgTwo.isHidden = false
                    memberCell?.imgThree.isHidden = false
                    memberCell?.imgFour.isHidden = false
                    memberCell?.leadingConstant.constant = 0
                    memberCell?.plusCountLbl.isHidden = false
                    memberCell?.plusCountLbl.text =  "+ " + "\(fullNameArr.count - 4)"
                    for i in 0...contactJidArr.count - 1{
                        if let contact = rosterManager.getContact(jid: contactJidArr[i] as! String){
                            if i == 0{
                                Utility.download(token: contact.image, profileImage: (memberCell?.imgOne)!, uniqueId: contactJidArr[i] as! String,name :contact.name,colorCode: contact.colorCode,frameSize:50,fontSize:14, completion: {})
                            }
                            else if i == 1{
                                Utility.download(token: contact.image, profileImage: (memberCell?.imgTwo)!, uniqueId: contactJidArr[i] as! String,name :contact.name,colorCode: contact.colorCode,frameSize:50,fontSize:14, completion: {})
                            }
                            
                            else if i == 2{
                                Utility.download(token: contact.image, profileImage: (memberCell?.imgThree)!, uniqueId: contactJidArr[i] as! String,name :contact.name,colorCode: contact.colorCode,frameSize:50,fontSize:14, completion: {})
                            }
                            else if i == 3{
                                Utility.download(token: contact.image, profileImage: (memberCell?.imgFour)!, uniqueId: contactJidArr[i] as! String,name :contact.name,colorCode: contact.colorCode,frameSize:50,fontSize:14, completion: {})
                            }
                            else {
                                break
                            }
                        }
                    }
                }
                
            }
            let time = callLog["callTime"] as! Double
            let todayTimeStamp = FlyCallUtils.generateTimestamp()
            memberCell?.callDateandTimeLabel.text = self.callLogTime(time, currentTime: todayTimeStamp)
            memberCell?.callDurationLbl.text = self.callLogDuration(callLog["startTime"] as! Double, endTime: callLog["endTime"] as! Double)
            print(callLog["startTime"] as! Double)
            print(callLog["endTime"] as! Double)

            if callLog["callType"] as! String == "audio"{
                memberCell?.callInitiateBtn.setImage(UIImage.init(named: "audio_call"), for: .normal)
            }else {
                memberCell?.callInitiateBtn.setImage(UIImage.init(named: "VideoType"), for: .normal)
            }
            if callLog["callState"] as! String == "IncomingCall"{
                memberCell?.callStatusBtn.image = UIImage.init(named: "incomingCall")
            }else if callLog["callState"] as! String == "OutgoingCall"{
                memberCell?.callStatusBtn.image = UIImage.init(named: "outGoing")
            }else{
                memberCell?.callStatusBtn.image = UIImage.init(named: "missedCall")
            }
        }
        return memberCell!
    }
    
    @objc func buttonClicked(sender: UIButton) {
        let buttonRow = sender.tag
        print(buttonRow)
        if let callLog = CallLogArray[buttonRow] as? RealmCallLog{
            if callLog["callMode"] as? String == "onetoone"{
                var jidString = String()
                if callLog["fromUser"] as! String == FlyDefaults.myJid{
                    jidString = callLog["toUser"] as! String
                }else{
                    jidString = callLog["fromUser"] as! String
                }
                var callUserProfiles = [ProfileDetails]()
                
                if let contact = rosterManager.getContact(jid: jidString)
                {
                    callUserProfiles.append(contact)
                }
                if callLog["callType"] as! String == "audio"{
                    RootViewController.sharedInstance.callViewController?.makeCall(usersList: callUserProfiles.compactMap{$0.jid}, callType: .Audio)
                }
                else{
                    RootViewController.sharedInstance.callViewController?.makeCall(usersList: callUserProfiles.compactMap{$0.jid}, callType: .Video)
                }
            }else{
                let userString = callLog["userList"] as? String ?? ""
                let fullNameArr = userString.components(separatedBy: ",")
                var callUserProfiles = [ProfileDetails]()
                for JID in fullNameArr{
                    if let contact = rosterManager.getContact(jid: JID){
                        callUserProfiles.append(contact)
                    }
                }
                if callLog["callType"] as! String == "audio"{
                    RootViewController.sharedInstance.callViewController?.makeCall(usersList: callUserProfiles.compactMap{$0.jid}, callType: .Audio)
                }
                else{
                    RootViewController.sharedInstance.callViewController?.makeCall(usersList: callUserProfiles.compactMap{$0.jid}, callType: .Video)
                }
            }
        }
    }
    
    func callLogTime(_ callTime: Double, currentTime: String?) -> String? {
        let aDateFormatter = DateFormatter()
        aDateFormatter.dateFormat = "yyyy-MM-dd"
        aDateFormatter.timeZone = NSTimeZone(abbreviation: "GMT") as TimeZone?
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd hh:mm:ss a"
        df.timeZone = NSTimeZone.local
        df.dateStyle = .medium
        df.timeStyle = .short
        df.doesRelativeDateFormatting = true
        let timeInterval = TimeInterval(callTime / 1000000)
        let date = Date(timeIntervalSince1970: timeInterval)
        let dateString = "\( self.getOnlyDateOrTime(from: date, withTime: false) ?? ""), \(self.getOnlyDateOrTime(from: date, withTime: true) ?? "")"
        return dateString
    }
    
    func getOnlyDateOrTime(from date: Date?, withTime: Bool) -> String? {
        // set last message date/time
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = NSTimeZone.local
        if withTime {
            dateFormatter.dateFormat = "HH:mm"
            dateFormatter.timeStyle = .short
        } else {
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.dateStyle = .medium
        }
        dateFormatter.doesRelativeDateFormatting = true
        var dateString: String? = nil
        if let date = date {
            dateString = dateFormatter.string(from: date)
        }
        return dateString
    }
    
    func callLogDuration(_ startTime: Double, endTime: Double) -> String? {
        if startTime > 1 && endTime > 1 {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd hh:mm:ss a"
            df.timeZone = NSTimeZone.local
            df.dateStyle = .medium
            df.timeStyle = .short
            df.doesRelativeDateFormatting = true
            let timeInterval = TimeInterval(startTime / 1000000)
            let startdate = Date(timeIntervalSince1970: timeInterval)
            let timeInterval1 = TimeInterval(endTime / 1000000)
            let enddate = Date(timeIntervalSince1970: timeInterval1)
            var distanceBetweenDates: TimeInterval? = nil
            if let startdate = startdate as? Date{
                distanceBetweenDates = enddate.timeIntervalSince(startdate)
            }
            return string(from: distanceBetweenDates ?? 0.0)
        } else {
            return ""
        }
    }
    
    func string(from interval: TimeInterval) -> String? {
        let ti = Int(interval)
        let seconds = ti % 60
        let minutes = (ti / 60) % 60
        let hours = ti / 3600
        if hours > 0 {
            return String(format: "%02ld:%02ld:%02ld", hours, minutes, seconds)
        } else {
            return String(format: "%02ld:%02ld", minutes, seconds)
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return YES if you want the specified item to be editable.
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCell.EditingStyle.delete {
            callLog = CallLogArray[indexPath.row] as! RealmCallLog
            isClearAll = false
            print(callLog)
            deleteCallLogs()
            callLogTableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        callLog = CallLogArray[indexPath.row] as! RealmCallLog
        if callLog["callMode"] as? String == "onetoone"{
            
        }else{
            let storyboard = UIStoryboard(name: "Call", bundle: nil)
            groupCallViewController = storyboard.instantiateViewController(withIdentifier: "GroupCallViewController") as? GroupCallViewController
            groupCallViewController?.callLog = callLog
            let userString = callLog["userList"] as? String ?? ""
            let fullNameArr = userString.components(separatedBy: ",")
            let contactArr = NSMutableArray()
            for JID in fullNameArr{
                if let contact = rosterManager.getContact(jid: JID){
                    contactArr.add(getUserName(name: contact.name, nickName: contact.nickName))
                }
            }
            groupCallViewController?.groupCallName = contactArr.componentsJoined(by: ",")
            let time = callLog["callTime"] as! Double
            let todayTimeStamp = FlyCallUtils.generateTimestamp()
            groupCallViewController?.callTime = self.callLogTime(time, currentTime: todayTimeStamp)!
            groupCallViewController?.callDuration = self.callLogDuration(callLog["startTime"] as! Double, endTime: callLog["endTime"] as! Double)!
            self.navigationController?.pushViewController(groupCallViewController!, animated: true)
        }
    }
}

extension callLogViewController{
    
    func deleteCallLogs() {
        let url = Utility.appendBaseURL(restEnd: "users/callLogs")
        var headers: HTTPHeaders = ["Content-Type": "application/json", "Accept": "application/json"]
        var parametersDictionary: [String : Any]?
        if isClearAll{
            parametersDictionary = [
                "roomId": []
            ]
        }else{
            parametersDictionary = [
                "roomId": [callLog["callId"]]
            ]
        }
        let authToken = FlyCallUtils.sharedInstance.getConfigUserDefault(forKey: "token") as? String ?? ""
        if authToken.count > 0 {
            headers.add(name: "Authorization", value: authToken)
        }
        AF.request(URL(string: url)!,method: .delete,parameters:parametersDictionary ,encoding: JSONEncoding.default,headers: headers).validate(statusCode: 200..<300).responseJSON { [self] response in
            print(response.result)
            switch response.result {
            case .success(_):
                if response.response?.statusCode == 200 {
                    if self.isClearAll{
                        callLogManager.deleteCallLogs()
                        CallLogArray.removeAll()
                        deleteAllBtn.isHidden = true
                    }else{
                        callLogManager.deleteSingleCallLogs(callLog:callLog)
                        deleteAllBtn.isHidden = false
                    }
                    CallLogArray = CallLogManager.getCallLogs()
                    noCallLogView.isHidden = CallLogArray.count > 0
                    callLogTableView.reloadData()
                }else {
                }
            case .failure(_) :
                let _ : String
                if let httpStatusCode = response.response?.statusCode {
                    if(httpStatusCode == 401){
                        self.refreshToken { isSuccess in
                            if isSuccess {
                                self.deleteCallLogs()
                            }
                        }
                    } else {
                    }
                }
            }
        }
    }
    
    func getsyncedLogs(){
        let SyncedArray = callLogManager.getCallLogsWithSync(isLogSync: true)
        let callLog = SyncedArray.first as? RealmCallLog
        var parametersDictionary: [String : Any]?
        if (callLog != nil) {
            parametersDictionary = [
                "lastSyncDate": callLog?["callTime"] as Any
            ]
        } else {
            parametersDictionary = [:]
       }
        let url = Utility.appendBaseURL(restEnd: "users/callLogs")
        var headers: HTTPHeaders = ["Content-Type": "application/json", "Accept": "application/json"]
        let authToken = FlyCallUtils.sharedInstance.getConfigUserDefault(forKey: "token") as? String ?? ""
        if authToken.count > 0 {
            headers.add(name: "Authorization", value: authToken)
        }
        AF.request(URL(string: url)!,method: .get,parameters:parametersDictionary ,encoding: URLEncoding.default,headers: headers).validate(statusCode: 200..<300).responseJSON { [self] response in
            switch response.result
            {
            case .success(_) :do {
                print("success")
                let data = response.value
                let responseObject = data as? NSDictionary
                print("response object isssss ",responseObject as Any)
                if let callLogArr = responseObject?.value(forKeyPath: "data.callLogs") as? NSArray{
                    let callLogs = NSMutableArray()
                    for dict in callLogArr{
                        let roomID = (dict as AnyObject).value(forKey: "roomId") as? String
                        let existingLog = callLog?.getCallLog(forCallID: roomID)
                        var newLog: RealmCallLog?
                        if existingLog != nil {
                            newLog = RealmCallLog(value: existingLog as Any)
                            let callStart = (dict as AnyObject).value(forKey: "startTime") as? Int
                            let callEnd = (dict as AnyObject).value(forKey: "endTime") as? Int
                            let callStartDouble = Double(callStart ?? 0)
                            let callEndDouble = Double(callEnd ?? 0)
                            newLog?["callTime"] = ((dict as AnyObject).value(forKey: "callTime") as? NSNumber)?.doubleValue ?? 0.0
                            newLog?["startTime"] = callStartDouble
                            newLog?["endTime"] = callEndDouble
                        } else if !(roomID == nil) {
                            let callState = (dict as AnyObject).value(forKey: "callState") as? Int
                            let callStart = (dict as AnyObject).value(forKey: "startTime") as? Int
                            let callEnd = (dict as AnyObject).value(forKey: "endTime") as? Int
                            print(Double(callStart ?? 0))

                            let callStartDouble = Double(callStart ?? 0)
                            let callEndDouble = Double(callEnd ?? 0)

                            var callStateFinal = String()
                            if callState == 0{
                                callStateFinal = CallState.IncomingCall.rawValue
                            }else if callState == 1{
                                callStateFinal = CallState.OutgoingCall.rawValue
                            }else{
                                callStateFinal = CallState.MissedCall.rawValue
                            }
                            print(callStartDouble)
                            print(callEndDouble)
                            newLog = callLogRealm.initWithCallID(roomID, fromJID: (dict as AnyObject).value(forKey: "fromUser") as? String , toJID: (dict as AnyObject).value(forKey: "toUser") as? String, callerDevice: "ios", callType: (dict as AnyObject).value(forKey: "callType") as? String , callingTime: (dict as AnyObject).value(forKey: "callTime") as! Double, callStartTime: callStartDouble, callEndTime: callEndDouble, callState: callStateFinal, callMode: (dict as AnyObject).value(forKey: "callMode") as! String , usersList: (dict as AnyObject).value(forKey: "userList") as! String, groupId: (dict as AnyObject).value(forKey: "group_id") as? String)
                        }
                        // TODO: have to insert sessionStatus, inviteUserList
                        newLog?["isLogSync"] = true
                        callLogs.add(newLog as Any)
                    }
                    callLogManager.saveRealmArray(callLogs as! [RealmCallLog])
                    CallLogArray = CallLogManager.getCallLogs()
                    noCallLogView.isHidden = CallLogArray.count > 0
                    callLogTableView.reloadData()
                }
            }
            case .failure(let error):
                print("failure(error)",error)
                if let httpStatusCode = response.response?.statusCode {
                    if(httpStatusCode == 401){
                        self.refreshToken { isSuccess in
                            if isSuccess {
                                self.getsyncedLogs()
                            }
                        }
                    } else {
                    }
                }
                break
            }
        }
    }
    
    func setMissedCallCount(){
        let missedCallCount = self.getMissedCallCount()
        if (missedCallCount != 0){
            print(missedCallCount)
        }else{
            print("No missed calls")
        }
        NotificationCenter.default.post(name: NSNotification.Name("missedCallCount"), object: missedCallCount)
        callLogTableView.reloadData()
    }
    
    func getMissedCallCount() -> Int {
        var lastValue = FlyCallUtils.sharedInstance.getUserDefaultsValue(forKey: "LastMissedCallTime")
        let countString: String?
        lastValue = lastValue as? Double != 0.0 ? lastValue : 0
        let MissedCallsArray = CallLogManager.getAllMissedCallList()
        var count = 0
        for callLog in MissedCallsArray {
            guard let callLog = callLog as? RealmCallLog else {
                continue
            }
            if callLog["callTime"] as? Double ?? 0.0 >= lastValue as? Double ?? 0.0{
                count = count + 1
            }
        }
        if count != 0 {
            countString = "\(count)"
        }
        return count
    }
    
    func getBadgeCount() -> NSNumber? {
        let missedCount = self.getMissedCallCount()
        let badge = missedCount
        return badge as NSNumber
    }
    
    func postUnSyncedLogs(){
        var callLogs: [Any] = []
        let unSyncedArray = callLogManager.getCallLogsWithSync(isLogSync: false)
        for log in unSyncedArray {
            guard let log = log as? RealmCallLog else {
                continue
            }
            if (log["callId"] == nil) {
                return
            }
            var dict: [AnyHashable : Any] = [:]
            dict["roomId"] = log["callId"]
            if log["callType"] == nil {
                let precicate = NSPredicate(format: "SELF.callId == %@", log["callId"] as! CVarArg)
                let resultArray = try? Realm().objects(RealmCallLog.self).filter(precicate)
                CallLogArray = CallLogArray.filter({ !(resultArray?.contains($0 as! RealmCallLog))! })
                callLogManager.deleteSingleCallLogs(callLog:log)
                continue
            }
            var callState = Int()
            if log["callState"] as! String == "IncomingCall"{
                callState = 0
            }else if log["callState"] as! String == "OutgoingCall"{
                callState = 1
            }else{
                callState = 2
            }
            dict["callType"] = log["callType"]
            dict["callerDevice"] = log["callerDevice"] ?? "ios"
            dict["fromUser"] = log["fromUser"] ?? ""
            dict["toUser"] = log["toUser"] ?? ""
            dict["callState"] = callState
            dict["callTime"] = log["callTime"] ?? 0.0
            dict["endTime"] = log["endTime"] ?? 0.0
            dict["startTime"] = log["startTime"] ?? 0.0
            dict["callMode"] = log["callMode"] ?? ""
            dict["userList"] = log["userList"] ?? ""
            dict["sessionStatus"] = "Closed"
            dict["groupId"] = ""
            dict["inviteUserList"] = ""
            callLogs.append(dict)
        }
        if callLogs.count == 0 {
            return
        }
        let url = Utility.appendBaseURL(restEnd: "users/callLogs")
        var headers: HTTPHeaders = ["Content-Type": "application/json", "Accept": "application/json"]
        let authToken = FlyCallUtils.sharedInstance.getConfigUserDefault(forKey: "token") as? String ?? ""
        if authToken.count > 0 {
            headers.add(name: "Authorization", value: authToken)
        }
        let parameters = ["callLogs":callLogs]
        AF.request(url, method: .post, parameters: parameters , encoding: JSONEncoding.default, headers: headers, interceptor: self, requestModifier: nil).validate().responseJSON { [self]  response in
            print(response.result)
            switch response.result {
            case .success(_):
                if response.response?.statusCode == 200 {
                  print("success")
                    callLogManager.updatecallLog(callLogs: callLogs)
                   
                    callLogTableView.reloadData()
                }else {
                }
                
            case .failure(_) :
                let _ : String
                if let httpStatusCode = response.response?.statusCode {
                    if(httpStatusCode == 401){
                        self.refreshToken { isSuccess in
                            if isSuccess {
                                self.postUnSyncedLogs()
                            }
                        }
                    } else {
                    }
                }
            }
        }
    }
    
    func refreshToken(onCompletion: @escaping (_ isSuccess: Bool) -> Void) {
        let username = FlyDefaults.myXmppUsername
        let password = FlyDefaults.myXmppPassword
        if username.count == 0 || password.count == 0 {
            return
        }
        let parameters = ["username" : username,
                          "password": password];
        let url = Utility.appendBaseURL(restEnd: "login")
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: nil, interceptor: self, requestModifier: nil).validate().responseJSON { response in
            print(response.result)
            switch response.result {
            case .success(let result):
                if response.response?.statusCode == 200 {
                    guard let responseDictionary = result as? [String : Any]  else{
                        return
                    }
                    let data = responseDictionary["data"] as? [String: String] ?? [:]
                    let token = data["token"] ?? ""
                    FlyCallUtils.sharedInstance.setConfigUserDefaults(token, withKey: "token")
                }
                onCompletion(true)
            case .failure(_) :
                onCompletion(false)
            }
        }
    }
}


class CCFCallLogListCell: UITableViewCell {
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
    
    @IBOutlet weak var leadingConstant: NSLayoutConstraint!
    @IBOutlet weak var plusCountLbl: UILabel!
    @IBOutlet weak var groupView: UIView!
    @IBOutlet weak var imgFour: UIImageView!
    @IBOutlet weak var imgThree: UIImageView!
    @IBOutlet weak var imgTwo: UIImageView!
    @IBOutlet weak var imgOne: UIImageView!
    @IBOutlet weak var callDurationLbl: UILabel!
    override class func awakeFromNib() {
        super.awakeFromNib()
       
    }
}

