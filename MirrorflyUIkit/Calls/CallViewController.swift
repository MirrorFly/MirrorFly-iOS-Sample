//
//  ViewController.swift
//  GroupCallUI
//
//  Created by Vasanth Kumar on 19/05/21.
//

import UIKit
import FlyCall
import FlyCommon
import FlyCore
import WebRTC
import FlyDatabase
import Alamofire
import PulsingHalo
import AVKit
import Toaster

enum CallMode : String{
    case Incoming
    case Outgoing
}

enum CallType : String{
    case Audio
    case Video
}

protocol CallViewControllerDelegate {
    func onVideoMute(status:Bool)
    func onAudioMute(status:Bool)
    func onSwitchCamera()
}

class CallViewController: UIViewController ,AVPictureInPictureControllerDelegate, UIAdaptivePresentationControllerDelegate{
    @IBOutlet var outgoingCallView: OutGoingCallXib!
    @IBOutlet var collectionView: UICollectionView!
    var bgcolor = UIColor(hexString: "#0D2852")
    var isTapped : Bool!
    var downloadResponse: DownloadRequest?
    var rosterManager = RosterManager()
    var userName = String()
    var callUsersProfiles = NSMutableArray()
    var delegate : CallViewControllerDelegate?
    var isAudioMuted = false {
        willSet {
            members.last?.isAudioMuted = newValue
        }
    }
    var isVideoMuted = false{
        willSet {
            members.last?.isVideoMuted = newValue
        }
    }
    var isBackCamera = false{
        willSet {
            members.last?.isOnBackCamera = newValue
        }
    }
    var myCallStatus : CallStatus = .calling {
        didSet {
            members.last?.callStatus = myCallStatus
        }
    }
    var panGesture  = UIPanGestureRecognizer()
    var tapGesture  = UITapGestureRecognizer()
    
    let colors = ["#3C9877","#2386CB","#A023CB","#CB2823","#23CB2B"]
    
    var callMode : CallMode = .Incoming
    var callType : CallType = .Audio
    var isCallConnected : Bool = false
    var audioPlayer : AVAudioPlayer?
    var myLocalVideoTrack : RTCVideoTrack? = nil
    
    var members : [CallMember] = []
    static var sharedInstance = CallViewController()
    var callDurationTimer : Timer?
    var seconds = -1
    var isCallConversionRequestedByMe = false
    var isCallConversionRequestedByRemote = false
    var alertController : UIAlertController?
    var VideoCallConversionTimer : Timer?
    var callViewOverlay = UIView()
    var returnToCall = UIImageView()
    
    var isOnCall = false
    
    var safeAreaHeight : CGFloat = 0.0
    var safeAraeWidth : CGFloat = 0.0
    var isAddParticipant = false
    var currentOutputDevice : OutputType = .receiver
    var audioDevicesAlertController : UIAlertController? = nil
    var speakingTimer : Timer? = nil
    var speakingDictionary  = Dictionary<String, Int>()
    var isLocalViewSwitched = false
    var groupId : String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("#lifecycle viewDidLoad")
        
        checkForUserBlockingByAdmin()
        
        isTapped = false
        outgoingCallView.addParticipantBtn.isHidden = true
        if let heightFormatter = NumberFormatter().number(from: Utility.getStringFromPreference(key: "safeAreaHeight")), let widthFormatter =  NumberFormatter().number(from: Utility.getStringFromPreference(key:  "safeAreaWidth")) {
            safeAreaHeight = CGFloat(truncating: heightFormatter)
            safeAraeWidth = CGFloat(truncating: widthFormatter)
        }
        updateUI()
    }
    
    func checkForUserBlockingByAdmin() {
        if members.count == 0 {
            return
        }
        var jidToCheck = ""
        if CallManager.isOneToOneCall() {
            let filteredJid = members.filter({$0.jid != FlyDefaults.myJid})
            if filteredJid.count > 0 {
                jidToCheck = filteredJid[0].jid
            }
        }else {
            jidToCheck = CallManager.getGroupID() ?? ""
        }
        
        
        if  ChatManager.isUserOrGroupBlockedByAdmin(jid: jidToCheck) {
            CallManager.disconnectCall()
            AppAlert.shared.showToast(message: CallManager.isOneToOneCall() ? thisUerIsNoLonger : groupNoLongerAvailable)
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard keyPath == "isPictureInPicturePossible" else {
            return
        }
        
        //#9 read the KVO notification for the property isPictureInPicturePossible
        if let pipController = object as? AVPictureInPictureController {
            if pipController.isPictureInPicturePossible {
                //Video can be played in PIP mode.
                pipController.startPictureInPicture()
            }
        }
    }
    
    func showOneToOneAudioCallUI() {
        print("#call showOneToOneAudioCallUI")
        outgoingCallView.isHidden = false
        collectionView.isHidden = true
        outgoingCallView.outGoingAudioCallImageView.isHidden = false
        outgoingCallView.OutgoingRingingStatusLabel.isHidden = false
        outgoingCallView.imageHeight.constant = 100
        outgoingCallView.viewHeight.constant = 190
        outgoingCallView.imageTop.constant = 8
        getContactNames()
        outgoingCallView.backBtn.addTarget(self, action: #selector(backAction(sender:)), for: .touchUpInside)
        outgoingCallView.localVideoView.isHidden = true
        outgoingCallView.remoteVideoView.isHidden = true
        outgoingCallView.cameraButton.isHidden = true
        outgoingCallView.OutGoingCallBG.isHidden = false
        outgoingCallView.OutGoingCallBG.image = UIImage(named: "call_bg")
        outgoingCallView.videoButton.setImage(UIImage(named: "VideoDisabled" ), for: .normal)
        isCallConversionRequestedByMe = false
    }
    
    func showOneToOneVideoCallUI() {
        print("#call showOneToOneVideoCallUI")
        outgoingCallView.localVideoView.isHidden = false
        outgoingCallView.remoteVideoView.isHidden = false
        collectionView.isHidden = CallManager.isOneToOneCall()
        outgoingCallView.outGoingAudioCallImageView.isHidden = true
        outgoingCallView.cameraButton.isHidden = false
        outgoingCallView.outGoingAudioCallImageView.isHidden = true
        outgoingCallView.timerLable.isHidden = true
        outgoingCallView.OutGoingCallBG.image = nil
        outgoingCallView.OutGoingCallBG.isHidden = true
        outgoingCallView.contentView.backgroundColor = .clear
        getContactNames()
        outgoingCallView.backBtn.addTarget(self, action: #selector(backAction(sender:)), for: .touchUpInside)
        outgoingCallView.viewHeight.constant = 100
        outgoingCallView.imageHeight.constant = 0
        if CallManager.isCallConnected() {
            outgoingCallView.addParticipantBtn.isHidden = false
        }
        if !isOnCall && CallManager.isOneToOneCall(){
            resetLocalVideCallUI()
        }
    }
    
    func showConnectedVideoCallOneToOneUI() {
        isCallConversionRequestedByMe = false
        outgoingCallView.localVideoViewHeight.constant =  160
        outgoingCallView.localVideoViewWidth.constant =  112
        outgoingCallView.localVideoViewTrailing.constant = -16
        outgoingCallView.localVideoViewBottom.constant = -(outgoingCallView.callActionsViewHeight.constant + 16)
        outgoingCallView.localVideoView.layer.cornerRadius = 12
        outgoingCallView.localVideoView.layer.masksToBounds = true
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(CallViewController.draggedView(_:)))
        outgoingCallView.localVideoView.isUserInteractionEnabled = true
        outgoingCallView.localVideoView.addGestureRecognizer(panGesture)
        outgoingCallView.timerLable.isHidden = false
        if CallManager.isCallConnected() {
            getContactNames()
            outgoingCallView.addParticipantBtn.isHidden = false
            let gesture = UIPanGestureRecognizer()
            gesture.state = .ended
            draggedView(gesture)
        }
        setVideoBtnIcon()
        UIView.animate(withDuration: 0.250) { [weak self] in
            self?.view?.layoutIfNeeded()
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(smallVideoTileTapped(_:)))
        outgoingCallView.localVideoView?.addGestureRecognizer(tap)
        
    }
    
    @objc func draggedView(_ sender:UIPanGestureRecognizer){
        
        let localView = outgoingCallView.localVideoView!
        let translation = sender.translation(in: view)
        
        switch sender.state {
        case .began, .changed :
            localView.center = CGPoint(x: localView.center.x + translation.x, y: localView.center.y + translation.y)
            sender.setTranslation(CGPoint.zero, in: view)
        case .ended :
            let minX = localView.frame.minX, maxX = localView.frame.maxX, minY = localView.frame.minY, maxY = localView.frame.maxY,viewMaxX = view.frame.maxX
            var viewMaxY = safeAreaHeight
            if isTapped {
                viewMaxY = safeAreaHeight
            } else {
                viewMaxY = safeAreaHeight - 172
            }
            var centerPoint : CGPoint = CGPoint(x: localView.center.x, y: localView.center.y)
            if minX < 0 && minY < 0 {
                centerPoint = CGPoint(x: localView.frame.width/2 + 12 , y: localView.frame.height/2 + 12)
            }else if minX < 0 && maxY > viewMaxY {
                centerPoint = CGPoint(x:localView.frame.width/2 + 12 , y: (viewMaxY - localView.frame.height/2) - 12)
            }else if minX < 0 {
                centerPoint = CGPoint(x: localView.frame.width/2 + 12 , y: localView.center.y)
            }else if minY < 0 && maxX > viewMaxX {
                centerPoint = CGPoint(x:(viewMaxX - localView.frame.width/2) - 12, y:  (localView.frame.height/2) + 12 )
            }else if minY < 0 {
                centerPoint = CGPoint(x:localView.center.x, y:  localView.frame.height/2 + 12)
            }else if maxX > viewMaxX && maxY > viewMaxY {
                centerPoint = CGPoint(x:(viewMaxX - localView.frame.width/2) - 12 , y: (viewMaxY - localView.frame.height/2) - 12)
            }else if maxX > viewMaxX {
                centerPoint = CGPoint(x:(viewMaxX - localView.frame.width/2) - 12, y:  localView.center.y)
            }else if maxY > viewMaxY {
                centerPoint = CGPoint(x:localView.center.x , y: (viewMaxY - localView.frame.height/2) - 12)
            }
            UIView.animate(withDuration: 0.250, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn) { [unowned self] in
                localView.center = centerPoint
                sender.setTranslation(CGPoint.zero, in: self.view)
            } completion: { _ in }

            break
        default:
            break
        }
    }
    
    
    func resetLocalVideCallUI() {
        outgoingCallView?.localVideoView.layer.cornerRadius = 0
        outgoingCallView?.localVideoView.layer.masksToBounds = true
        outgoingCallView?.localVideoViewHeight.constant = getControllerViewHeight()
        outgoingCallView?.localVideoViewWidth.constant =  getControllerViewWidth()
        outgoingCallView?.localVideoViewTrailing.constant = 0
        outgoingCallView?.localVideoViewBottom.constant = 0
    }
    
    func updateActionsUI() {
        enableDisableUserInteractionFor(view: outgoingCallView.AttendingBottomView, isDisable: false)
        outgoingCallView.videoButton.setImage(UIImage(named: isVideoMuted ? "VideoDisabled" :  "VideoEnabled" ), for: .normal)
        outgoingCallView.audioButton.setImage(UIImage(named: isAudioMuted ? "IconAudioOn" :  "IconAudioOff" ), for: .normal)
        outgoingCallView.cameraButton.setImage(UIImage(named: isBackCamera ? "IconCameraOn" :  "IconCameraOff" ), for: .normal)
    }
    
    @objc func backAction(sender: UIButton?) {
        showCallOverlay()
        dismiss(animated: true)
    }
    
    func showCallOverlay() {
        
        callViewOverlay = UIView(frame: CGRect(x: UIScreen.main.bounds.size.width - 150, y: 100, width: 150, height: 150))
        callViewOverlay.backgroundColor = UIColor.clear
        callViewOverlay.layer.cornerRadius = callViewOverlay.frame.size.height / 2
        callViewOverlay.alpha = 1.0
        callViewOverlay.tag = 1104
        
        let clearview = UIView(frame: CGRect(x: 20, y: 20, width: callViewOverlay.frame.size.width - 40, height: callViewOverlay.frame.size.height - 40))
        clearview.layer.cornerRadius = clearview.frame.size.height / 2
        clearview.layer.masksToBounds = true
        
        returnToCall = UIImageView(frame: CGRect(x: 0, y: 0, width: clearview.frame.size.width, height: clearview.frame.size.height))
        print(members)
        var membersJid = members.compactMap { $0.jid }
        
        if membersJid.contains(FlyDefaults.myJid){
            membersJid.removeAll(where: { $0 == FlyDefaults.myJid})
        }
        if membersJid.count == 1{
            returnToCall.image = UIImage(named: "Default Avatar_ic")
            if let contact = rosterManager.getContact(jid: membersJid[0].lowercased()){
                returnToCall.loadFlyImage(imageURL: contact.image, name: getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType))
            }
        }else{
            returnToCall.image = UIImage(named: "ic_groupPlaceHolder")
        }
        
        clearview.addSubview(returnToCall)
        
        let halo = PulsingHaloLayer()
        halo.position = CGPoint(x: 75, y: 75)
        halo.radius = 85
        halo.haloLayerNumber = 10
        halo.backgroundColor = UIColor.darkGray.cgColor
        halo.start()
        callViewOverlay.layer.addSublayer(halo)
        callViewOverlay.addSubview(clearview)
        
        self.view?.window?.addSubview(callViewOverlay)
        
        let callViewTap = UITapGestureRecognizer(target: self, action: #selector(callViewTapGestureAction(_:)))
        callViewTap.numberOfTapsRequired = 1
        clearview.addGestureRecognizer(callViewTap)
    }
    
    @objc func callViewTapGestureAction(_ tapGesture: UITapGestureRecognizer?) {
        callViewOverlay.removeFromSuperview()
        let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        if let rootVC = window?.rootViewController {
            let navigationStack = UINavigationController(rootViewController: self)
            navigationStack.setNavigationBarHidden(true, animated: true)
            navigationStack.modalPresentationStyle = .overFullScreen
            rootVC.present(navigationStack, animated: true, completion: nil)
        }
    }
    
    func updateUI () {
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
        if !isOnCall{
            myCallStatus = .calling
        }
        outgoingCallView?.localVideoView.removeGestureRecognizer(panGesture)
        print("#call updateUI")
        //enableButtons(buttons: outgoingCallView?.audioButton, isEnable: false)
        updateActionsUI()
        
        // configure UI of AudioPicker
        
        delegate = self
        outgoingCallView.addParticipantBtn.isHidden = true
        showHideCallAgainView(show: false, status: "Trying to connect")
        if CallManager.getCallDirection() == .Incoming {
            outgoingCallView?.OutgoingRingingStatusLabel.text =  "Connecting"
        } else {
            outgoingCallView?.OutgoingRingingStatusLabel.text =  "Trying to connect"
        }
        for (memberJid,status) in CallManager.getCallUsersWithStatus() {
            _ = validateAndAddMember(jid: memberJid, with: convertCallStatus(status: status))
        }
        if CallManager.isOneToOneCall() {
            if CallManager.getCallType() == .Audio {
                showOneToOneAudioCallUI()
            } else {
                showOneToOneVideoCallUI()
                renderLocalVideoView1to1()
                if CallManager.isCallConnected() {
                    renderRemoteVideoView1to1()
                    renderLocalVideoView1to1()
                    showConnectedVideoCallOneToOneUI()
                }
                outgoingCallView?.videoButton.setImage(UIImage(named: "VideoEnabled" ), for: .normal)
            }
        } else {
            for member in members {
                if member.callStatus == .connected && CallManager.getCallType() == .Video {
                    _ = requestForVideoTrack(jid: member.jid)
                }
            }
            showGroupCallUI()
        }
        if CallManager.getCallType() == .Video{
            outgoingCallView?.videoButton.setImage(UIImage(named: "VideoEnabled" ), for: .normal)
            if CallManager.getCallDirection() == .Incoming {
                _ = requestForVideoTrack()
            }
        }
        setMuteStatusText()
        if CallManager.isCallConnected(){
            isOnCall = true
            outgoingCallView.OutgoingRingingStatusLabel.text = "Connected"
            outgoingCallView.addParticipantBtn.isHidden = false
           enableButtons(buttons: outgoingCallView?.videoButton, isEnable: true)
        }else{
            outgoingCallView.addParticipantBtn.isHidden = true
            outgoingCallView.OutgoingRingingStatusLabel.text = CallManager.getCallDirection() == .Incoming ? "Connecting" : "Trying to connect"
            enableButtons(buttons: outgoingCallView?.videoButton, isEnable: false)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("#lifecycle viewWillAppear")
        navigationController?.setNavigationBarHidden(true, animated: false)
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
        ChatManager.shared.connectionDelegate = self
        CallManager.delegate = self
        AudioManager.shared().audioManagerDelegate = self
        outgoingCallView.OutgoingRingingStatusLabel.text = getCurrentCallStatusAsString()
        if isOnCall {
            outgoingCallView.localVideoView.addGestureRecognizer(panGesture)
        }else{
            outgoingCallView.localVideoView.removeGestureRecognizer(panGesture)
        }
        setTopViewsHeight()
        outgoingCallView?.addParticipantBtn.addTarget(self, action: #selector(addParticipant(sender:)), for: .touchUpInside)
        if isAddParticipant == false {
            self.collectionView.delegate = self
            self.collectionView.dataSource = self
            collectionView.backgroundColor = bgcolor
            getContactNames()
            if isOnCall{
                seconds = UserDefaults.standard.object(forKey: "seconds") as? Int ?? -1
                
                updateCallDuration()
            }else{
                UserDefaults.standard.removeObject(forKey: "seconds")
            }
            if CallManager.isCallConnected() && (myCallStatus == .connected || myCallStatus == .reconnected){
                self.outgoingCallView.addParticipantBtn.isHidden = false
            }else{
                self.outgoingCallView.addParticipantBtn.isHidden = true
            }
            outgoingCallView.callEndBtn.addTarget(self, action: #selector(callEndlBtnTapped(sender:)), for: .touchUpInside)
            outgoingCallView.videoButton.addTarget(self, action: #selector(videoButtonTapped(sender:)), for: .touchUpInside)
            outgoingCallView.audioButton.addTarget(self, action: #selector(AudioButtonTapped(sender:)), for: .touchUpInside)
            outgoingCallView.speakerButton.addTarget(self, action: #selector(showAudioActionSheet(sender:)), for: .touchUpInside)
            outgoingCallView.cameraButton.addTarget(self, action: #selector(CameraButtonTapped(sender:)), for: .touchUpInside)
            outgoingCallView.cancelButton.addTarget(self, action: #selector(cancelBtnTapped(sender:)), for: .touchUpInside)
            outgoingCallView.CallAgainButton.addTarget(self, action: #selector(callAgainBtnTapped(sender:)), for: .touchUpInside)
        }
        if CallManager.isOneToOneCall() {
            if CallManager.getCallType() == .Video && CallManager.isCallConnected() {
                showConnectedVideoCallOneToOneUI()
            }
        } else {
            for member in members {
                if member.callStatus == .connected && CallManager.getCallType() == .Video {
                    _ = requestForVideoTrack(jid: member.jid)
                }
            }
            if isOnCall{
                showGroupCallUI()
            }
        }
        if CallManager.isCallConnected() && (myCallStatus == .connected || myCallStatus == .reconnected){
            self.outgoingCallView.addParticipantBtn.isHidden = false
        }else{
            self.outgoingCallView.addParticipantBtn.isHidden = true
        }
        setActionIconsAfterMaximize()
        updateActionsUI()
        setMuteStatusText()
        setVideoBtnIcon()
        isAddParticipant = false
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(SingleTapGesturTapped(_:)))
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print("#lifecycle viewDidAppear")
        ContactManager.shared.profileDelegate = self
        isAudioMuted = CallManager.isAudioMuted()
        isVideoMuted = CallManager.isVideoMuted()
        updateActionsUI()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        print("#lifecycle viewWillDisappear")
        super.viewWillDisappear(animated)
        ContactManager.shared.profileDelegate = nil
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        print("#lifecycle viewDidDisappear")
        CallManager.delegate = RootViewController .sharedInstance
        if callDurationTimer != nil && isAddParticipant == false {
            callDurationTimer?.invalidate()
            callDurationTimer = nil
            seconds = -1
            clearViews()
        }
        ChatManager.shared.connectionDelegate = nil
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        AudioManager.shared().audioManagerDelegate = nil
    }
    
    func clearViews() {
        outgoingCallView.addParticipantBtn.isHidden = true
        outgoingCallView.OutgoingRingingStatusLabel.text = ""
        outgoingCallView.OutGoingPersonLabel.text = ""
        outgoingCallView.timerLable.isHidden = true
        outgoingCallView.audioMuteStackView.isHidden = true
        callDurationTimer?.invalidate()
        callDurationTimer = nil
        seconds = -1
        isCallConversionRequestedByMe = false
        isCallConversionRequestedByRemote = false
        print("#mute clearViews \(isAudioMuted) video \(isVideoMuted) ")
        updateActionsUI()
    }
    
    
    func showHideCallAgainView(show: Bool,status: String) {
        if let outgoingCallView = outgoingCallView{
            outgoingCallView.localVideoView.removeGestureRecognizer(panGesture)
            outgoingCallView.OutgoingRingingStatusLabel.isHidden = status.isEmpty
            outgoingCallView.OutgoingRingingStatusLabel.text = status
            if show {
                self.outgoingCallView.AttendingBottomView.isHidden = true
                self.outgoingCallView.callAgainView.isHidden = false
                if CallManager.getCallType() == .Audio{
                    self.outgoingCallView.CallAgainButton.setImage(UIImage(named: "callAgain"), for: .normal)
                }else{
                    self.outgoingCallView.CallAgainButton.setImage(UIImage(named: "call again_ic"), for: .normal)
                }
            } else {
                self.outgoingCallView.callAgainView.isHidden = true
                self.outgoingCallView.AttendingBottomView.isHidden = false
            }
        }
    }
    
    @objc func cancelBtnTapped(sender:UIButton) {
        CallManager.disconnectCall()
        self.dismiss()
    }
    
    @objc func callEndlBtnTapped(sender:UIButton) {
        CallManager.disconnectCall()
        self.dismissWithDelay()
    }
    
    @objc func videoButtonTapped(sender:UIButton) {
        print("isVideoMuted \(isVideoMuted)")
        
        if CallManager.isOneToOneCall() && CallManager.getCallType() == .Audio {
            callConversionPopup()
        } else {
            print("#mute videoButtonTapped else")
            isVideoMuted.toggle()
            if !CallManager.isOneToOneCall(){
                if members.last?.videoTrack == nil{
                    print("#mute videoButtonTapped if if isVideoMuted: false")
                    CallManager.enableVideo()
                }
            }
            delegate?.onVideoMute(status: isVideoMuted)
        }
    }
    
    func dismiss() {
        print("#lifecycle dismiss")
        callMode = .Incoming
        isCallConnected = false
        myCallStatus = .disconnected
        isLocalViewSwitched = false

        seconds = -1
        isBackCamera = false
        isVideoMuted = false
        isAudioMuted = false

        speakingDictionary.removeAll()
        removeAllMembers()
        isOnCall = false
        myCallStatus = .calling
        if outgoingCallView != nil { // check this condition if ui is presented
            clearViews()
            showHideCallAgainView(show: false, status: "Trying to connect")
            dismiss(animated: true, completion: nil)
        }
    }
    
    
    @objc func callAgainBtnTapped(sender:UIButton) {
        CallManager.disconnectCall()
        myCallStatus = .calling
        showHideCallAgainView(show: false, status: "Trying to connect")
        let callAgainaMembers = members.compactMap{$0.jid}
        removeAllMembers()
        makeCall(usersList: callAgainaMembers, callType: callType)
    }
    
    @objc func CameraButtonTapped(sender:UIButton) {
        isBackCamera.toggle()
        if isBackCamera{
            if CallManager.isOneToOneCall() {
                UIView.animate(withDuration: 0.6, delay: 0.0, options: [], animations: { [weak self] in
                    self?.oneToOneVideoViewTransforms()
                })
            }else{
                if let myCell = collectionView?.cellForItem(at: IndexPath(item: findIndexOfUser(jid: FlyDefaults.myJid) ?? members.count - 1, section: 0)) as? GroupCallCell{
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(600)) {
                        myCell.videoView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                    }
                }
            }
        }else{
            if CallManager.isOneToOneCall() {
                UIView.animate(withDuration: 0.6, delay: 0.0, options: [], animations: { [weak self] in
                    self?.oneToOneVideoViewTransforms()
                })
            }else{
                if let myCell = collectionView?.cellForItem(at: IndexPath(item: findIndexOfUser(jid: FlyDefaults.myJid) ?? members.count - 1, section: 0)) as? GroupCallCell{
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(600)) {
                        myCell.videoView.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
                    }
                }
            }
        }
        delegate?.onSwitchCamera()
    }
    
    @objc func AudioButtonTapped(sender:UIButton) {
        isAudioMuted.toggle()
        members.last?.isAudioMuted = isAudioMuted
        delegate?.onAudioMute(status: isAudioMuted)
    }
    
    @objc func SingleTapGesturTapped(_ sender: UITapGestureRecognizer) {
        // if members.count == 2 {
        
        print(self.outgoingCallView.localVideoView.frame.origin.y)
        
        if isTapped == false{
            isTapped = true
            let bottom = CGAffineTransform(translationX: 0, y: 200)
            let top = CGAffineTransform(translationX: 0, y: -400)
            
            UIView.animate(withDuration: 0.4, delay: 0.0, options: [], animations: {
                if !CallManager.isOneToOneCall() || CallManager.getCallType() == .Video{
                    self.outgoingCallView.AttendingBottomView.transform = bottom
                    self.outgoingCallView.OutGoingPersonLabel.transform = top
                    self.outgoingCallView.timerLable.transform = top
                    self.outgoingCallView.outGoingAudioCallImageView.transform = top
                    self.outgoingCallView.OutgoingRingingStatusLabel.transform = top
                }
            }, completion: nil)
        }else{
            isTapped = false
            let top = CGAffineTransform(translationX: 0, y: -20)
            let bottom = CGAffineTransform(translationX: 0, y: 0)
            
            let viewMaxY = safeAreaHeight - 172
            if let localView = self.outgoingCallView.localVideoView{
                if localView.frame.maxY > viewMaxY {
                    let gesture = UIPanGestureRecognizer()
                    gesture.state = .ended
                    if isOnCall{
                        draggedView(gesture)
                    }
                }
            }
            
            UIView.animate(withDuration: 0.4, delay: 0.0, options: [], animations: {
                if CallManager.getCallType() == .Video || !CallManager.isOneToOneCall() {
                    self.outgoingCallView.imageHeight.constant = 0
                    self.outgoingCallView.timerTop.constant = 0
                }else{
                    self.outgoingCallView.imageHeight.constant = 100
                    self.outgoingCallView.timerTop.constant = 8
                    self.outgoingCallView.outGoingAudioCallImageView.transform = bottom
                }
                self.outgoingCallView.AttendingBottomView.transform = top
                self.outgoingCallView.AttendingBottomView.transform = top
                self.outgoingCallView.OutGoingPersonLabel.transform = bottom
                self.outgoingCallView.timerLable.transform = bottom
                self.outgoingCallView.OutgoingRingingStatusLabel.transform = bottom
            }, completion: nil)
        }
        
        if self.outgoingCallView.localVideoView.frame.origin.y == 480.0 ||  self.outgoingCallView.localVideoView.frame.origin.y == 280.0 || self.outgoingCallView.localVideoView.frame.origin.y == 320.0{
            if isTapped == true{
                let bottom = CGAffineTransform(translationX: 0, y: 160)
                UIView.animate(withDuration: 0.4, delay: 0.0, options: [], animations: {
                    self.outgoingCallView.localVideoView.transform = bottom
                }, completion: nil)
            }else{
                let top = CGAffineTransform(translationX: 0, y: -40)
                UIView.animate(withDuration: 0.4, delay: 0.0, options: [], animations: {
                    self.outgoingCallView.localVideoView.transform = top
                }, completion: nil)
            }
            
            print(self.outgoingCallView.localVideoView.frame.origin.y)
            
        }
        
    }
    
    func setMemberIniitals(name : String , imageView: UIImageView)
    {
        let lblNameInitialize = UILabel()
        lblNameInitialize.frame.size = CGSize(width: 50, height: 50)
        lblNameInitialize.textColor = UIColor.white
        lblNameInitialize.font = AppFont.Medium.size(20)
        lblNameInitialize.text = name.getAcronyms()
        lblNameInitialize.textAlignment = NSTextAlignment.center
        lblNameInitialize.layer.cornerRadius = 50.0
        
        UIGraphicsBeginImageContext(lblNameInitialize.frame.size)
        lblNameInitialize.layer.render(in: UIGraphicsGetCurrentContext()!)
        imageView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    @objc func updateCallDuration() {
        getContactNames()
        if callDurationTimer == nil {
            callDurationTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateCallDuration), userInfo: nil, repeats: true)
            outgoingCallView?.timerLable.isHidden = false
        }
        seconds = seconds + 1
        UserDefaults.standard.set(seconds, forKey: "seconds")
        
        let duration: TimeInterval = TimeInterval(seconds) //seconds++
        
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional // Use the appropriate positioning for the current locale
        if seconds >= 3600 {
            formatter.allowedUnits = [ .hour, .minute, .second ] // Units to display in the formatted string
        }
        else {
            formatter.allowedUnits = [.minute, .second]
        }
        formatter.zeroFormattingBehavior = [ .pad] // Pad with zeroes where appropriate for the locale
        
        let formattedDuration = formatter.string(from: duration)
        outgoingCallView?.timerLable.text = formattedDuration
    }
    
    func updateOneToOneAudioCallUI() {
        showOneToOneAudioCallUI()
        outgoingCallView.imageHeight.constant = 100
        outgoingCallView.viewHeight.constant = 190
        outgoingCallView.imageTop.constant = 8
        outgoingCallView.timerLable.isHidden = false
        outgoingCallView.timerTop.constant = 8
        outgoingCallView.outGoingAudioCallImageView.transform = CGAffineTransform(translationX: 0, y: 0)
        getContactNames()
        if CallManager.isCallConnected() {
            setMuteStatusText()
            outgoingCallView.addParticipantBtn.isHidden = false
        }
    }
    
    func getContactNames(){
        var unknowGroupMembers = [String]()
        let membersJid = members.compactMap { $0.jid }.filter {$0 != FlyDefaults.myJid}
        if membersJid.count == 1 {
            if let contact = rosterManager.getContact(jid: membersJid[0].lowercased()){
                outgoingCallView?.outGoingAudioCallImageView.image = UIImage.init(named: "Default Avatar_ic")
                outgoingCallView?.OutGoingPersonLabel.text = getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType)
                outgoingCallView.outGoingAudioCallImageView.loadFlyImage(imageURL: contact.image, name: getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType))
            }else{
                outgoingCallView?.outGoingAudioCallImageView.image = UIImage.init(named: "Default Avatar_ic")
            }
        } else if membersJid.count == 2 {
            for i in 0...1{
                if let contact = rosterManager.getContact(jid: membersJid[i].lowercased()){
                    unknowGroupMembers.append(getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType))
                }
            }
            let groupMemberName = unknowGroupMembers.joined(separator: ",")
            outgoingCallView?.OutGoingPersonLabel.text = groupMemberName
            outgoingCallView?.outGoingAudioCallImageView.image = UIImage.init(named: "ic_groupPlaceHolder")
        } else if membersJid.count > 2{
            unknowGroupMembers.removeAll()
            for i in 0...1{
                if let contact = rosterManager.getContact(jid: membersJid[i].lowercased()){
                    unknowGroupMembers.append(getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType))
                }
            }
            let groupMemberName = unknowGroupMembers.joined(separator: ",")
            var nameString = groupMemberName
            if nameString.count > 32 {
                nameString = groupMemberName.substring(to: 31) + "..."
            }
            outgoingCallView?.OutGoingPersonLabel.text = String(format: "%@ and (+ %lu)", nameString, membersJid.count - 2)
            outgoingCallView?.outGoingAudioCallImageView.image = UIImage.init(named: "ic_groupPlaceHolder")
        }
        else {
            outgoingCallView?.OutGoingPersonLabel.text = ""
        }
    }
    
    func showGroupCallUI() {
        showOneToOneVideoCallUI()
        collectionView?.isHidden = false
        outgoingCallView.timerLable.isHidden = false
        outgoingCallView.imageHeight.constant = 0
        outgoingCallView.timerTop.constant = 0
        if CallManager.getCallType() == .Video && !isOnCall {
        }else {
            outgoingCallView.cameraButton.isHidden = isVideoMuted
        }
        outgoingCallView.OutgoingRingingStatusLabel.isHidden = false
        outgoingCallView?.localVideoView.isHidden = true
        outgoingCallView?.remoteVideoView.isHidden = true
        getContactNames()
        outgoingCallView?.audioMuteStackView.isHidden = true
        collectionView?.reloadData()
    }
    
    func updateOneToOneVideoCallUI() {
        showOneToOneVideoCallUI()
        outgoingCallView.timerLable.isHidden = false
        showConnectedVideoCallOneToOneUI()
    }
    
    func setMuteStatusText() {
        DispatchQueue.main.async { [weak self] in
            if CallManager.isOneToOneCall() {
                let isCallConnected = self?.isOnCall ?? false
                let remoteAudioMuted = self?.members.first?.isAudioMuted ?? false, remoteVideoMuted =  (self?.members.first?.isVideoMuted ?? false && isCallConnected)
                let myVideoMuted =  self?.isVideoMuted
                let showHideView = remoteAudioMuted || remoteVideoMuted
                self?.outgoingCallView?.audioMuteStackView.isHidden = !showHideView
                self?.outgoingCallView?.audioMuteStackView.arrangedSubviews[1].isHidden = !remoteAudioMuted
                self?.outgoingCallView?.audioMuteStackView.arrangedSubviews.first?.isHidden = true
                if (remoteVideoMuted && CallManager.getCallType() == .Video)  && remoteAudioMuted {
                    self?.outgoingCallView?.audioMuteStackView.arrangedSubviews.first?.isHidden = false
                    self?.outgoingCallView?.audioMutedLable.text = "\(self?.members.first?.name ?? "") muted audio and video"
                } else if remoteVideoMuted && CallManager.getCallType() == .Video {
                    self?.outgoingCallView?.audioMuteStackView.arrangedSubviews.first?.isHidden = false
                    self?.outgoingCallView?.audioMutedLable.text = "\(self?.members.first?.name ?? "")'s camera turned off"
                } else  if remoteAudioMuted{
                    self?.outgoingCallView?.audioMuteStackView.arrangedSubviews.first?.isHidden = true
                    self?.outgoingCallView?.audioMutedLable.text = "\(self?.members.first?.name ?? "")'s microphone turned off"
                }
                if (remoteVideoMuted == true) && (myVideoMuted == true){
                    self?.outgoingCallView?.audioMuteStackView.arrangedSubviews.first?.isHidden = true
                    if remoteAudioMuted {
                        self?.outgoingCallView?.audioMutedLable.text = "\(self?.members.first?.name ?? "")'s microphone turned off"
                    }else{
                        self?.outgoingCallView?.audioMuteStackView.isHidden = true
                    }
                    self?.outgoingCallView?.videoButton.setImage(UIImage(named: "VideoDisabled" ), for: .normal)
                }
            }else {
                self?.outgoingCallView?.audioMuteStackView.isHidden = true
            }
        }
    }
    
}


// MARK:- Call Switch pop up
extension CallViewController {
    
    // Show confirmation pop up for call Switching
    func callConversionPopup() {
        //showConfirmationAlertForCallSwitching
        alertController = UIAlertController.init(title: nil , message: "Are you sure you want to switch to Video Call", preferredStyle: .alert)
        let switchAction = UIAlertAction(title: "Switch", style: .default) { [weak self] (action) in
            self?.isCallConversionRequestedByMe = true
            self?.showAlertViewWithIndicator()
            CallManager.requestVideoCallSwitch()
            self?.VideoCallConversionTimer = Timer.scheduledTimer(timeInterval: 20, target: self ?? CallViewController.self, selector: #selector(self?.videoCallConversionTimer), userInfo: nil, repeats: false)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default) { [weak self] (action) in
            CallManager.setCallType(callType: .Audio)
            self?.isCallConversionRequestedByMe = false
            self?.resetConversionTimer()
        }
        alertController?.addAction(switchAction)
        alertController?.addAction(cancelAction)
        //  let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        DispatchQueue.main.async { [weak self] in
            if let alert = self?.alertController {
                self?.present(alert, animated: true, completion: {
                })
            }
            
        }
    }
    
    func showAlertViewWithIndicator() {
        if self.isCallConversionRequestedByMe && self.isCallConversionRequestedByRemote{
            CallManager.setCallType(callType: .Video)
            CallManager.acceptVideoCallSwitchRequest()
            CallManager.muteVideo(false)
            switchAudioToVideoCall()
            isCallConversionRequestedByMe = false
            isCallConversionRequestedByRemote = false
            resetConversionTimer()
            DispatchQueue.main.async  {  [weak self] in
                self?.alertController?.dismiss(animated: true, completion: nil)
            }
        }else {
            alertController = UIAlertController.init(title: "Requesting to switch to video call." , message: "", preferredStyle: .alert)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .default) { [weak self] (action) in
                // Cancel Request
                CallManager.cancelVideoCallSwitch()
                self?.resetConversionTimer()
                self?.isCallConversionRequestedByMe = false
                self?.updateOneToOneAudioCallUI()
            }
            alertController?.addAction(cancelAction)

            if CallManager.getCallType() == .Video {
                resetConversionTimer()
            }else{
                DispatchQueue.main.async  {  [weak self] in
                    if let alert = self?.alertController {
                        if !(self?.isCallConversionRequestedByRemote ?? false) && CallManager.getCallType() != .Video {
                            self?.present(alert, animated: true, completion: {
                                self?.isCallConversionRequestedByMe = true
                            })
                        }else{
                            self?.resetConversionTimer()
                        }
                    }
                }
            }
        }
    }
    
    func showCallConversionConfirmationRequest() {
        if self.isCallConversionRequestedByMe && self.isCallConversionRequestedByRemote{
            CallManager.setCallType(callType: .Video)
            CallManager.acceptVideoCallSwitchRequest()
            switchAudioToVideoCall()
            isCallConversionRequestedByMe = false
            isCallConversionRequestedByRemote = false
        }else {
            alertController = UIAlertController.init(title: "Requesting Video Call." , message: "", preferredStyle: .alert)
            let acceptAction = UIAlertAction(title: "Accept", style: .default) { [weak self] (action) in
                CallManager.acceptVideoCallSwitchRequest()
                self?.isCallConversionRequestedByMe = false
                self?.isCallConversionRequestedByRemote = false
                self?.switchAudioToVideoCall()
                CallManager.muteVideo(false)
                AudioManager.shared().routeToAvailableDevice(preferredDevice: self?.currentOutputDevice ?? .speaker)
            }
            
            let cancelAction = UIAlertAction(title: "Decline", style: .default) { [weak self] (action) in
                self?.alertController?.dismiss(animated: true, completion: nil)
                CallManager.setCallType(callType: .Audio)
                // Cancel Request
                CallManager.declineVideoCallSwitchRequest()
                self?.isCallConversionRequestedByMe = false
                self?.updateOneToOneAudioCallUI()
                self?.isCallConversionRequestedByRemote = false
            }
            alertController?.addAction(acceptAction)
            alertController?.addAction(cancelAction)
            
            if CallManager.getCallType() == .Video {
                resetConversionTimer()
            }else {
                DispatchQueue.main.async {  [weak self] in
                    if let alert = self?.alertController {
                        if !(self?.isCallConversionRequestedByMe ?? false) && CallManager.getCallType() != .Video {
                            self?.present(alert, animated: true, completion: nil)
                        }else{
                            self?.resetConversionTimer()
                        }
                    }
                }
            }
        }
    }
    
    @objc func videoCallConversionTimer() {
        alertController?.dismiss(animated: true, completion: nil)
        if CallManager.getCallType() != .Video {
            CallManager.setCallType(callType: .Audio)
            isCallConversionRequestedByMe = false
            updateOneToOneAudioCallUI()
            CallManager.cancelVideoCallSwitch()
        }
    }
    
    func resetConversionTimer(){
        VideoCallConversionTimer?.invalidate()
        VideoCallConversionTimer = nil
        alertController?.dismiss(animated: true, completion: nil)
        isCallConversionRequestedByRemote = false
    }
}


extension CallViewController : UICollectionViewDelegate , UICollectionViewDataSource , UICollectionViewDelegateFlowLayout{
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print(members.count)
        if (members.count == 8) {
            outgoingCallView.addParticipantBtn.isHidden = true
        }
        return members.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let groupCell = self.collectionView.dequeueReusableCell(withReuseIdentifier: GroupCallCell.identifier, for: indexPath) as! GroupCallCell
        let member = members[indexPath.row]
        let isLastRow = (indexPath.row == members.count - 1)
        let callStatus =  isLastRow ? .connected : convertCallStatus(status: CallManager.getCallStatus(userId: member.jid))
        groupCell.contentView.backgroundColor = UIColor(hexString: member.color)
        groupCell.profileImage.isHidden = false
        groupCell.profileImage.contentMode = .scaleAspectFill
        if callStatus == .connected {
            if CallManager.getCallType() == .Video ||  (member.videoTrack != nil && !member.isVideoMuted){
                groupCell.videoView.isHidden = member.isVideoMuted
                groupCell.profileImage.isHidden = !member.isVideoMuted
                releaseTrackViewBy(member: member)
                member.videoTrackView = groupCell.videoView
                if let memberTrack = member.videoTrack {
                    renderVideoView(view: member.videoTrackView, track: memberTrack)
                }
            } else{
                groupCell.videoView.renderFrame(nil)
                groupCell.videoView.isHidden = true
                groupCell.profileImage.isHidden = false
            }
            groupCell.audioIconImageView.isHidden = !member.isAudioMuted
            groupCell.foreGroundView.isHidden = true
            groupCell.callActionsView.isHidden = false
            groupCell.statusLable.textColor = UIColor(hexString: "#FFFFFF")
            groupCell.profileName.font = AppFont.Regular.size(14)
        }
        if isLastRow {
            groupCell.profileName.text = "You"
            groupCell.foreGroundView.isHidden = true
            groupCell.callActionsView.isHidden = false
            groupCell.audioIconImageView.isHidden = true
            print("my status allTpe: \(CallManager.getCallType()) isVideoMuted: \(member.isVideoMuted) videoTrack \(member.videoTrack != nil)")
            if  CallManager.getCallType() == .Video ||  (member.videoTrack != nil && !member.isVideoMuted){
                groupCell.videoView.isHidden = member.isVideoMuted
                groupCell.profileImage.isHidden = !member.isVideoMuted
                if isBackCamera {
                    groupCell.videoView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                }else {
                    groupCell.videoView.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
                }
            } else {
                groupCell.profileImage.isHidden = false
            }
        } else {
            groupCell.profileName.text = member.name
            groupCell.videoView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        }
        if (isLastRow  && member.callStatus == .reconnecting) || (!isLastRow && member.callStatus != .connected){
            groupCell.profileImage.isHidden = false
            groupCell.foreGroundView.isHidden = false
            groupCell.callActionsView.isHidden = true
            groupCell.statusLable.text = member.callStatus.rawValue.capitalized
        }else{
            groupCell.foreGroundView.isHidden = true
            groupCell.callActionsView.isHidden = false
            groupCell.statusLable.textColor = UIColor(hexString: "#FFFFFF")
            groupCell.profileName.font = AppFont.Regular.size(14)
        }
        if member.image.isEmpty {
            Utility.IntialLetter(name: member.name, imageView: groupCell.profileImage, colorCode: member.color,frameSize: 128,fontSize: 64)
        }else if let cachedImage = ImageCache.shared.object(forKey: member.image as NSString) {
            groupCell.profileImage.clipsToBounds = true
            groupCell.profileImage.contentMode = .scaleAspectFill
            groupCell.profileImage.image = cachedImage
        }else {
            Utility.IntialLetter(name: member.name, imageView: groupCell.profileImage, colorCode: member.color,frameSize: 128,fontSize: 64)
            Utility.download(token: member.image, profileImage: groupCell.profileImage, uniqueId: member.jid,name: member.name,colorCode: member.color,frameSize: 128,fontSize: 64,notify: true, completion: { [weak self] in
                self?.reloadCollectionViewForIndex(index: self?.findIndexOfUser(jid: member.jid))
            })
        }
        //        if (indexPath.row == 2 && members.count == 3) || (indexPath.row == 4 && members.count == 5) || (indexPath.row == 6 && members.count == 7) {
        //            print("#lastCell \(collectionView.frame.size.width) \(collectionView.frame.size.width / 4) \(member.name)")
        //            groupCell.profileImageLeading.constant = collectionView.frame.size.width / 5
        //            groupCell.profileImageTrailing.constant = collectionView.frame.size.width / 5
        //            groupCell.videoViewLeading.constant = collectionView.frame.size.width / 5
        //            groupCell.videoViewTrailing.constant = collectionView.frame.size.width / 5
        //            UIView.animate(withDuration: 0.100) {groupCell.contentView.layoutIfNeeded()}
        //        }else {
        //            groupCell.profileImageLeading.constant = 0
        //            groupCell.profileImageTrailing.constant = 0
        //            groupCell.videoViewLeading.constant = 0
        //            groupCell.videoViewTrailing.constant = 0
        //        }
        return groupCell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let lastRowIndex = collectionView.numberOfItems(inSection: collectionView.numberOfSections-1)
        switch members.count {
        case 1:
            return CGSize(width: (collectionView.frame.size.width), height: (collectionView.frame.size.height))
        case 2:
            return CGSize(width: (collectionView.frame.size.width ) , height: (collectionView.frame.size.height  ) )
        case 3:
            if collectionView.numberOfItems(inSection: 0) % 2 != 0 && indexPath.row == lastRowIndex - 1 {
                return CGSize(width: collectionView.frame.size.width  , height: (collectionView.frame.size.height  ) / 2 )
            }
            else
            {
                return CGSize(width: (collectionView.frame.size.width ) / 2, height: (collectionView.frame.size.height  ) / 2)
            }
        case 4:
            return CGSize(width: (collectionView.frame.size.width ) / 2, height: (collectionView.frame.size.height  ) / 2)
        case 5:
            if collectionView.numberOfItems(inSection: 0) % 2 != 0 && indexPath.row == lastRowIndex - 1 {
                return CGSize(width: collectionView.frame.size.width , height: (collectionView.frame.size.height ) / 3 )
            }
            else
            {
                return CGSize(width: (collectionView.frame.size.width ) / 2, height: (collectionView.frame.size.height ) / 3)
            }
        case 6:
            return CGSize(width: (collectionView.frame.size.width ) / 2, height: (collectionView.frame.size.height ) / 3)
        case 7:
            if collectionView.numberOfItems(inSection: 0) % 2 != 0 && indexPath.row == lastRowIndex - 1 {
                return CGSize(width: collectionView.frame.size.width , height: (collectionView.frame.size.height ) / 4 )
            }
            else
            {
                return CGSize(width: (collectionView.frame.size.width ) / 2, height: (collectionView.frame.size.height  ) / 4)
            }
        case 8:
            return CGSize(width: (collectionView.frame.size.width ) / 2, height: (collectionView.frame.size.height  ) / 4)
        default:
            print("more than 8 person")
            return CGSize(width: (collectionView.frame.size.width ), height: (collectionView.frame.size.height))
        }
    }
    
    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
    }
    
    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
    }
    
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        
    }
    
}

extension CallViewController : CallViewControllerDelegate {
    
    func onVideoMute(status:Bool) {
        print("#mute status \(status)")
        CallManager.muteVideo(status)
        members.last?.isVideoMuted = status
        if CallManager.isOneToOneCall() {
            setVideoBtnIcon()
            setMuteStatusText()
        } else {
            setVideoBtnIcon()
            outgoingCallView.cameraButton.isHidden = isVideoMuted
            if !isVideoMuted{
                _ = requestForVideoTrack(jid: FlyDefaults.myJid)
            }
            reloadCollectionViewForIndex(index: findIndexOfUser(jid:FlyDefaults.myJid))
            AudioManager.shared().routeToAvailableDevice(preferredDevice: currentOutputDevice)
        }
    }
    
    func onAudioMute(status:Bool) {
        outgoingCallView.audioButton.setImage(UIImage(named: isAudioMuted ? "IconAudioOn" :  "IconAudioOff" ), for: .normal)
        updateSpeakingUI(userId: FlyDefaults.myJid, isSpeaking: false)
        CallManager.muteAudio(status)
    }
    
    func setActionIconsAfterMaximize() {
        isAudioMuted = CallManager.isAudioMuted()
        isBackCamera = members.last?.isOnBackCamera ?? false
        isVideoMuted = CallManager.isVideoMuted()
        AudioManager.shared().getCurrentAudioInput()
    }
    
    func onSwitchCamera() {
        CallManager.switchCamera()
        outgoingCallView.cameraButton.setImage(UIImage(named: isBackCamera ? "IconCameraOn" :  "IconCameraOff" ), for: .normal)
    }
}


extension CallViewController {
    
    func makeCall(usersList : [String], callType: CallType, groupId : String = "") {
        CallManager.setMyInfo(name: FlyDefaults.myName, imageUrl: FlyDefaults.myImageUrl)
        self.groupId = groupId
        AudioManager.shared().audioManagerDelegate = self
        print("#lifecycle makeCall")
        if usersList.isEmpty{
            print("Cannot make call without a callee")
            return
        }
        self.callType = callType
        addMyInfoToMembersArray(requestTrack: false)
        for userJid in usersList where userJid != FlyDefaults.myJid {
            let _ = addRemoteMembers(for: rosterManager.getContact(jid: userJid.lowercased())!)
        }
        var membersJid = members.compactMap { $0.jid }
        if callType == .Audio {
            if members.count == 2 && groupId.isEmpty{
                try! CallManager.makeVoiceCall(members.first!.jid) { [weak self] (isSuccess , message)  in
                    if isSuccess == false {
                        AppAlert.shared.showAlert(view: self!, title: "", message: message, buttonTitle: "Okay")
                    }
                }
            } else {
                membersJid.remove(at: members.count - 1)
                try! CallManager.makeGroupVoiceCall(membersJid, groupID: groupId) {[weak self] isSuccess , message in
                    if isSuccess == false {
                        AppAlert.shared.showAlert(view: self!, title: "", message: message, buttonTitle: "Okay")
                    }
                }
            }
            if outgoingCallView != nil {
                updateUI()
            }
        } else {
            isVideoMuted = false
            if members.count == 2  && groupId.isEmpty {
                try! CallManager.makeVideoCall(members.first!.jid)  { [weak self]isSuccess, message in
                    if isSuccess == false {
                        AppAlert.shared.showAlert(view: self!, title: "", message: message, buttonTitle: "Okay")
                    }
                }
            } else {
                membersJid.remove(at: members.count - 1)
                try! CallManager.makeGroupVideoCall(membersJid, groupID: groupId) { [weak self] (isSuccess, message) in
                    if isSuccess == false {
                        AppAlert.shared.showAlert(view: self!, title: "", message: message, buttonTitle: "Okay")
                    }
                }
            }
            if outgoingCallView != nil {
                updateUI()
            }
        }
    }
    
    func getControllerViewHeight() -> CGFloat {
        return safeAreaHeight
    }
    
    func getControllerViewWidth() -> CGFloat {
        return safeAraeWidth
    }
    
}

extension CallViewController : CallManagerDelegate {
    func onVideoTrackAdded(userJid: String) {
        
    }
    
    func getDisplayName(IncomingUser :[String]) {
        var userString = [String]()
        if FlyDefaults.hideNotificationContent{
            userString.append(FlyDefaults.appName)
        }else{
            for JID in IncomingUser where JID != FlyDefaults.myJid{
                print("#jid \(JID)")
                if let contact = rosterManager.getContact(jid: JID.lowercased()){
                    if contact.contactType == .unknown{
                        userString.append((try? FlyUtils.getIdFromJid(jid: JID)) ?? "")
                    }else{
                        userString.append(getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType))
                    }
                }else {
                    let pd = ContactManager.shared.saveTempContact(userId: JID)
                    userString.append(pd?.name ?? "User")
                }
            }
            print("#names \(userString)")
        }
        CallManager.getContactNames(IncomingUserName: userString)
    }
    
    func getGroupName(_ groupId : String) {
        self.groupId = groupId
        if FlyDefaults.hideNotificationContent{
            CallManager.getContactNames(IncomingUserName: [FlyDefaults.appName])
        }else{
            if let groupContact =  rosterManager.getContact(jid: groupId.lowercased()){
                CallManager.getContactNames(IncomingUserName: [groupContact.name])
            }else{
                CallManager.getContactNames(IncomingUserName: ["Call from Group"])
            }
        }
    }
    
    func sendCallMessage( groupCallDetails : GroupCallDetails , users: [String], invitedUsers: [String]) {
        try? FlyMessenger.sendCallMessage(for: groupCallDetails, users : users , inviteUsers: invitedUsers) { isSuccess, flyError, flyData in
            var data  = flyData
            if isSuccess {
                print(data.getMessage() as? String ?? "")
            } else{
                print(data.getMessage() as! String)
            }
        }
    }
    
    func socketConnectionEstablished() {
        
    }
    
    func onCallStatusUpdated(callStatus: CALLSTATUS, userId: String) {
        print("STEP #call onCallStatusUpdated \(callStatus.rawValue) userJid : \(userId) memersCount : \(members.count)")
        
        DispatchQueue.main.async { [weak self] in
            
            if userId == FlyDefaults.myJid && (callStatus != .RECONNECTING && callStatus != .RECONNECTED) {
                return
            }
            
            switch callStatus {
            case .CALLING:
                if !(self?.isOnCall ?? true) {
                    self?.myCallStatus = .calling
                }
            case .CONNECTING:
                self?.outgoingCallView.timerLable.isHidden = true
                if !(self?.isOnCall ?? true){
                    self?.myCallStatus = .connecting
                }
                print("CONNECTING")
                
            case .RINGING:
                print("RINGING \(userId)")
                if !(self?.isOnCall ?? true){
                    self?.myCallStatus = .ringing
                    _ = self?.updateCallStatus(jid: userId, status: .ringing)
                }
                if !CallManager.isCallConnected(){
                    self?.outgoingCallView?.OutgoingRingingStatusLabel?.text = "Ringing"
                }
                if CallManager.isOneToOneCall() {
                    self?.outgoingCallView?.viewHeight.constant = 190
                    self?.outgoingCallView?.imageHeight.constant = 100
                    self?.outgoingCallView?.imageTop.constant = 8
                } else if (self?.isOnCall ?? false) {
                    self?.addUpdateCallUsersWithStatus(userJid: userId, status: .ringing, reload: true)
                }
                
            case .ATTENDED:
                if !(self?.isOnCall ?? true){
                    self?.myCallStatus = .attended
                }
                self?.showHideCallAgainView(show: false, status: "Connecting")
                self?.seconds = -1
                if CallManager.getCallDirection() == .Incoming {
                    for (memberJid,status) in CallManager.getCallUsersWithStatus() {
                        self?.addUpdateCallUsersWithStatus(userJid: memberJid, status: self?.convertCallStatus(status: status) ?? .calling)
                    }
                }
                if self?.outgoingCallView != nil {
                    if CallManager.isOneToOneCall()  {
                        if CallManager.getCallType() == .Audio {
                            self?.showOneToOneAudioCallUI()
                        } else {
                            self?.showOneToOneVideoCallUI()
                        }
                    }else{
                        self?.showGroupCallUI()
                    }
                    self!.outgoingCallView.removeGestureRecognizer(self!.tapGesture)
                    self!.outgoingCallView.addGestureRecognizer(self!.tapGesture)
                    self?.outgoingCallView.nameTop.constant = 8
                    self?.outgoingCallView.timerTop.constant = 0
                    self?.outgoingCallView.imageHeight.constant = 0
                }
            case .CONNECTED:
                if ((self?.audioPlayer) != nil) {
                    if ((self?.audioPlayer?.isPlaying) != nil) {
                        self?.audioPlayer?.stop()
                    }
                    self?.audioPlayer = nil
                }
                if !(self?.isOnCall ?? true){
                    if let vcSelf = self{
                        vcSelf.speakingTimer = Timer.scheduledTimer(timeInterval: 0.5, target: vcSelf, selector: #selector(vcSelf.validateSpeaking), userInfo: nil, repeats: true)
                    }
                }
                print("#call CONNECTED : \(userId)")
                self?.myCallStatus = .connected
                _ = self?.updateCallStatus(jid: FlyDefaults.myJid, status: .connected)
                self?.showHideCallAgainView(show: false, status: "Connected")

                self?.enableButtons(buttons:self?.outgoingCallView?.videoButton, isEnable: true)
                self?.outgoingCallView?.addParticipantBtn.isHidden = false
                self?.outgoingCallView?.OutgoingRingingStatusLabel.text =  "Connected"
                self?.outgoingCallView?.OutgoingRingingStatusLabel.isHidden = false
                self?.outgoingCallView?.OutGoingPersonLabel.isHidden = false
                self?.getContactNames()
                self?.outgoingCallView?.imageTop.constant = 8
                self?.outgoingCallView?.addParticipantBtn.addTarget(self, action: #selector(self?.addParticipant(sender:)), for: .touchUpInside)
                self?.enableDisableUserInteractionFor(view: self?.outgoingCallView.AttendingBottomView, isDisable: false)
                if CallManager.isOneToOneCall() {
                    _ = self?.validateAndAddMember(jid: userId, with: .connected)
                    if CallManager.getCallType() == .Video {
                        _ = self?.requestForVideoTrack(jid: userId)
                        self?.renderRemoteVideoView1to1()
                        self?.renderLocalVideoView1to1()
                        self?.updateOneToOneVideoCallUI()
                        self?.setVideoBtnIcon()
                    }else{
                        self?.updateOneToOneAudioCallUI()
                    }
                } else {
                    if self?.checkIfGroupCallUiIsVisible() ?? false { self?.showGroupCallUI() }
                    _ = self?.requestForVideoTrack(jid: userId)
                    _ = self?.updateMuteStatus(jid: userId, isMute: false, isAudio: CallManager.getCallType() == .Audio)
                    self?.addUpdateCallUsersWithStatus(userJid: userId, status: .connected, reload: true)
                    self?.outgoingCallView?.audioMuteStackView.isHidden = true
                }
                if let ocv = self?.outgoingCallView{
                    ocv.removeGestureRecognizer(self!.tapGesture)
                    ocv.addGestureRecognizer(self!.tapGesture)
                }
                self?.updateCallTimerDuration()
                self?.isOnCall = true
                let audioMuteStatus = CallManager.isRemoteAudioMuted(userId)
                let vidooMuteStatus = CallManager.isRemoteVideoMuted(userId)
                print("userJid mute status : \(userId)")
                self?.onMuteStatusUpdated(muteEvent: (audioMuteStatus == true) ? MuteEvent.ACTION_REMOTE_AUDIO_MUTE : MuteEvent.ACTION_REMOTE_AUDIO_UN_MUTE, userId: userId)
                self?.onMuteStatusUpdated(muteEvent: (vidooMuteStatus == true) ? MuteEvent.ACTION_REMOTE_VIDEO_MUTE : MuteEvent.ACTION_REMOTE_VIDEO_UN_MUTE , userId: userId)
            case .DISCONNECTED:
                self?.myCallStatus = .disconnected
                self?.isCallConnected = false
                if userId.isEmpty {
                    self?.dismissWithDelay()
                }else {
                    if let index = self?.findIndexOfUser(jid: userId) {
                        self?.removeDisConnectedUser(userIndex: index)
                    }
                }
            case .ON_HOLD:
                print("")
            case .ON_RESUME:
                print("")
            case .USER_JOINED:
                print("")
            case .USER_LEFT:
                print("")
            case .INVITE_CALL_TIME_OUT:
                print("")
            case .CALL_TIME_OUT:
                print("#call CALL_TIME_OUT  \(self?.isOnCall ?? false)")
                if self?.isOnCall ?? false {
                    let timedOutUsers = self?.getUnavailableUsers(isTimeOut: true) ?? []
                    if (self?.members.count ?? 0) - timedOutUsers.count > 1 {
                        self?.removeUnavailableUsers(removedUsers: timedOutUsers)
                    }else {
                        self?.dismissWithDelay()
                    }
                }else{
                    self?.myCallStatus = .tryagain
                    self?.showHideCallAgainView(show: true, status: "Unavailable, Try again later")
                }
            case .RECONNECTING:
                if (self?.isOnCall ?? false){
                    self?.myCallStatus = .reconnecting
                }
                self?.outgoingCallView?.addParticipantBtn?.isHidden = true
                self?.outgoingCallView?.OutgoingRingingStatusLabel.isHidden = !CallManager.isOneToOneCall()
                if CallManager.isOneToOneCall() {
                    self?.outgoingCallView?.OutgoingRingingStatusLabel.text = "Reconnecting"
                    self?.outgoingCallView?.OutgoingRingingStatusLabel.isHidden = false
                }else{
                    if let index = self?.updateCallStatus(jid: userId, status: .reconnecting) {
                        self?.reloadCollectionViewForIndex(index: index)
                    }
                }
            case .RECONNECTED:
                if (self?.isOnCall ?? false){
                    self?.myCallStatus = .reconnected
                }
                self?.outgoingCallView?.addParticipantBtn?.isHidden = !CallManager.isCallConnected()
                if CallManager.isOneToOneCall() {
                    if CallManager.isCallConnected(){
                        self?.outgoingCallView?.OutgoingRingingStatusLabel.isHidden = false
                        self?.outgoingCallView?.OutgoingRingingStatusLabel.text = "Connected"
                    }
                }else{
                    if let index = self?.updateCallStatus(jid: userId, status: .connected) {
                        self?.reloadCollectionViewForIndex(index: index)
                    }
                }
            case .CALLING_10S:
                print("")
            case .CALLING_AFTER_10S:
                print("")

            }
        }
    }
    
    
    @IBAction func addParticipant(sender: UIButton?){
        
        var controller: ContactViewController
        if #available(iOS 13.0, *) {
            controller = UIStoryboard(name: Storyboards.main, bundle: nil).instantiateViewController(identifier: Identifiers.contactViewController)
        } else {
            // Fallback on earlier versions
            controller = UIStoryboard(name: Storyboards.main, bundle: nil).instantiateViewController(withIdentifier: Identifiers.contactViewController) as! ContactViewController
        }
        controller.modalPresentationStyle = .fullScreen
        controller.makeCall = true
        controller.isMultiSelect = true
        controller.isInvite = true
        controller.hideNavigationbar = true
        controller.groupJid = self.groupId
        controller.refreshDelegate = self
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func showHideOutgoingCallView(isHide: Bool) {
        if outgoingCallView.isHidden != isHide {
            outgoingCallView.isHidden = isHide
        }
    }
    
    func findIndexOfUser(jid : String) -> Int? {
        return members.firstIndex { $0.jid == jid }
    }
    
    func onCallAction(callAction: CallAction, userId: String) {
        if userId == FlyDefaults.myJid {
            return
        }
        if callAction == CallAction.ACTION_REMOTE_VIDEO_ADDED {
            print("#call onCallAction() ACTION_REMOTE_VIDEO_ADDED : \(userId)")
            if let index = requestForVideoTrack(jid: userId) {
                if CallManager.isOneToOneCall(){
                    renderRemoteVideoView1to1()
                    members.first?.isVideoMuted = false
                    setMuteStatusText()
                }else {
                    members[index].isVideoMuted = false
                    reloadCollectionViewForIndex(index: index)
                    reloadCollectionViewForIndex(index: members.count - 1)
                }
            }
        } else if callAction == CallAction.ACTION_REMOTE_BUSY {
            // Cancel the call
//             if let contact = rosterManager.getContact(jid: userJid){
//               let toast = Toast.init(text: "User" + contact.name + "busy")
//               toast.show()
//             }
            
            let toast = Toast.init(text: "User is Busy")
            toast.show()
            
            if CallManager.getAllCallUsersList().count == 1{
                self.dismissWithDelay(callStatus: "User Busy")
            } else {
                if let index = findIndexOfUser(jid: userId) {
                    removeDisConnectedUser(userIndex: index)
                }
            }
            
        }
        else if callAction == CallAction.ACTION_VIDEO_CALL_CONVERSION_ACCEPTED {
            print("#switch ACTION_VIDEO_CALL_CONVERSION_ACCEPTED me :\(isCallConversionRequestedByMe) remote: \(isCallConversionRequestedByRemote)  isVideo: \(CallManager.getCallType().rawValue)")
            CallManager.setCallType(callType: .Video)
            CallManager.muteVideo(false)
            let _ = requestForVideoTrack(jid: nil)
            members.first?.isVideoMuted = false
            updateOneToOneVideoCallUI()
            renderLocalVideoView1to1()
            renderRemoteVideoView1to1()
            isVideoMuted = false
            setVideoBtnIcon()
            resetConversionTimer()
            AudioManager.shared().routeToAvailableDevice(preferredDevice: currentOutputDevice)
        }
        else if callAction == CallAction.ACTION_VIDEO_CALL_CONVERSION_REJECTED {
            print("#switch onCallAction \(callAction.rawValue)")
            // Call conversion is declined by the user
            isCallConversionRequestedByMe = false
            isCallConversionRequestedByRemote = false
            resetConversionTimer()
            CallManager.muteVideo(true)
            isVideoMuted = true
            setVideoBtnIcon()
            CallManager.setCallType(callType: .Audio)
            updateOneToOneAudioCallUI()
            releaseTrackViewBy(member: members[0])
            releaseTrackViewBy(member: members[1])
        }
        else if callAction == CallAction.ACTION_VIDEO_CALL_CONVERSION {
            print("#switch onCallAction \(callAction.rawValue) me :\(isCallConversionRequestedByMe) remote: \(isCallConversionRequestedByRemote)  isVideo: \(CallManager.getCallType().rawValue)")
            // Call conversion is requested to the user
            isCallConversionRequestedByRemote = true
            alertController?.dismiss(animated: true, completion:nil)
            showCallConversionConfirmationRequest()
            let _ = requestForVideoTrack(jid: nil)
        }
        else if callAction == CallAction.CHANGE_TO_AUDIO_CALL {
            print("#switch onCallAction \(callAction.rawValue) me :\(isCallConversionRequestedByMe) remote: \(isCallConversionRequestedByRemote)  isVideo: \(CallManager.getCallType().rawValue)")
            CallManager.setCallType(callType: .Audio)
            resetConversionTimer()
            updateOneToOneAudioCallUI()
            releaseTrackViewBy(member: members[0])
            releaseTrackViewBy(member: members[1])
            AudioManager.shared().routeToAvailableDevice(preferredDevice: currentOutputDevice)
        }
        else if callAction == CallAction.ACTION_INVITE_USERS {
            if checkIfGroupCallUiIsVisible() { showGroupCallUI() }
            for userJid in getInvitedUsers(){
                addUpdateCallUsersWithStatus(userJid: userJid, status: convertCallStatus(status: CallManager.getCallStatus(userId: userJid) ?? .CALLING), reload: true)
            }
            
        }
        else if callAction == CallAction.ACTION_REMOTE_ENGAGED {
//            if let contact = rosterManager.getContact(jid: userJid){
//              let toast = Toast.init(text: "User" + contact.name + "Engaged")
//              toast.show()
//            }
            let toast = Toast.init(text: "Call Engaged")
            toast.show()
            
            if CallManager.isOneToOneCall() && isOnCall {
                dismissWithDelay(callStatus: "Call Engaged")
            }else{
                if let index = findIndexOfUser(jid: userId){
                    removeDisConnectedUser(userIndex: index)
                }
            }
        }
    }
    
    func onLocalVideoTrackAdded(userId: String) {
        print("#call onLocalVideoTrackAdded() : \(userId)")
        if  CallManager.isOneToOneCall()  {
            outgoingCallView?.OutGoingCallBG.image = nil
            outgoingCallView?.contentView.backgroundColor = .clear
            addMyInfoToMembersArray(requestTrack: true)
            renderLocalVideoView1to1()
        } else {
            if let _ = findIndexOfUser(jid: userId) {
                _ = requestForVideoTrack(jid: userId)
            }else{
                addMyInfoToMembersArray(requestTrack: true)
            }
            if !isOnCall{
                renderLocalVideoView1to1()
            }
            reloadCollectionViewForIndex(index: findIndexOfUser(jid:FlyDefaults.myJid))
        }
    }
    
    func onMuteStatusUpdated(muteEvent: MuteEvent, userId: String) {
        print("#call onMuteStatusUpdated \(muteEvent) \(userId)")
        switch muteEvent {
        case .ACTION_REMOTE_AUDIO_MUTE:
            if CallManager.isOneToOneCall() {
                members.first?.isAudioMuted = true
                setMuteStatusText()
            } else {
                if let index = updateMuteStatus(jid: userId, isMute: true, isAudio: true){
                    reloadCollectionViewForIndex(index: index)
                }
            }
        case .ACTION_REMOTE_AUDIO_UN_MUTE:
            if CallManager.isOneToOneCall() {
                members.first?.isAudioMuted = false
                setMuteStatusText()
            } else {
                if let index = updateMuteStatus(jid: userId, isMute: false, isAudio: true){
                    reloadCollectionViewForIndex(index: index)
                }
            }
        case .ACTION_REMOTE_VIDEO_MUTE:
            
            if CallManager.isOneToOneCall() {
                if isLocalViewSwitched {
                    outgoingCallView?.localVideoView?.renderFrame(nil)
                }else{
                    outgoingCallView?.remoteVideoView?.renderFrame(nil)
                }
                members.first?.isVideoMuted = true
                setMuteStatusText()
            } else {
                if let index = updateMuteStatus(jid: userId, isMute: true, isAudio: false) {
                    
                    if CallManager.getCallType() == .Audio && members[index].videoTrack != nil{
                        releaseTrackViewBy(memberIndex: index)
                    }
                    reloadCollectionViewForIndex(index: index)
                }
            }
        case .ACTION_REMOTE_VIDEO_UN_MUTE:
            if CallManager.isOneToOneCall() {
                outgoingCallView?.contentView.backgroundColor = .clear
                members.first?.isVideoMuted = false
                setMuteStatusText()
            } else {
                if let index = updateMuteStatus(jid: userId, isMute: false, isAudio: false) {
                    if members[index].videoTrack == nil{ // CallManager.getCallType() == .Audio &&
                        _ = requestForVideoTrack(jid: userId)
                    }
                    reloadCollectionViewForIndex(index: index)
                }
            }
        case .ACTION_LOCAL_AUDIO_MUTE:
            isAudioMuted = true
            outgoingCallView.audioButton.setImage(UIImage(named: isAudioMuted ? "IconAudioOn" :  "IconAudioOff" ), for: .normal)
        case .ACTION_LOCAL_AUDIO_UN_MUTE:
            isAudioMuted = false
            outgoingCallView.audioButton.setImage(UIImage(named: isAudioMuted ? "IconAudioOn" :  "IconAudioOff" ), for: .normal)
        }
    }
    
    func switchAudioToVideoCall() {
        CallManager.setCallType(callType: .Video)
        let _ = requestForVideoTrack(jid: nil)
        updateOneToOneVideoCallUI()
        renderLocalVideoView1to1()
        renderRemoteVideoView1to1()
        isVideoMuted = false
        setVideoBtnIcon()
        resetConversionTimer()
    }
    
}

// Utility Method extensions

extension CallViewController {
    
    func validateAndAddMember(jid: String? = nil, with status: CallStatus = .calling) -> Bool {
        
        if members.isEmpty || !members.contains(where: {$0.jid == FlyDefaults.myJid}) {
            addMyInfoToMembersArray(requestTrack: CallManager.getCallType() == .Video)
        }
        
        if let jid = jid, jid != FlyDefaults.myJid {
            if !(members.contains{$0.jid == jid} ) {
                let profileDetails = ProfileDetails(jid: jid)
                _ = addRemoteMembers(for: profileDetails, with: status)
                if !CallManager.isOneToOneCall(){
                    collectionView?.reloadData()
                }
                return true
            }else {
                if let index = findIndexOfUser(jid: jid) {
                    members[index].callStatus = status
                }
            }
        }
        return false
    }
    
    func addRemoteMembers(for user : ProfileDetails, with status: CallStatus = .calling) -> Int  {
        print("#call addRemoteMembers \(user.name) \(user.colorCode)")
        var remoteUserProfile : ProfileDetails? = nil
        if let pd = rosterManager.getContact(jid: user.jid.lowercased()) {
            remoteUserProfile = pd
        }else{
            remoteUserProfile = ContactManager.shared.saveTempContact(userId: user.jid)
        }
        let callMember = CallMember()
        callMember.jid = user.jid
        callMember.callStatus = status
        let userId = user.jid.components(separatedBy: "@").first!
        callMember.name = getUserName(jid: remoteUserProfile?.jid ?? "",name: remoteUserProfile?.name ?? userId, nickName: remoteUserProfile?.nickName ?? userId,contactType: remoteUserProfile?.contactType ?? .unknown)
        callMember.image = remoteUserProfile?.image ?? user.image
        callMember.color = remoteUserProfile?.colorCode ?? "#00008B"
        callMember.isVideoMuted = CallManager.getCallType() == .Audio
        if let index = findIndexOfUser(jid: user.jid){
            return index
        }else {
            members.insert(callMember, at:  members.count >= 1 ? (members.count - 1) : 0 ) //0
            return 0
        }
    }
    
    func addMyInfoToMembersArray(requestTrack : Bool = false) {
        let callMember = CallMember()
        callMember.name = FlyDefaults.myName
        callMember.image = FlyDefaults.myImageUrl
        callMember.isCaller = CallManager.getCallDirection() == .Incoming ? false : true
        callMember.jid = FlyDefaults.myJid
        callMember.isVideoMuted = CallManager.getCallType() == .Audio
        callMember.callStatus = CallManager.getCallDirection() == .Incoming ? (CallManager.isCallConnected() ? .connected : .connecting) : (CallManager.isCallConnected() ? .connected : .calling)
        
        if findIndexOfUser(jid: FlyDefaults.myJid) == nil {
            isVideoMuted = callMember.isVideoMuted
            members.append(callMember)
        }
        if requestTrack {
            _ = requestForVideoTrack(jid: FlyDefaults.myJid)
        }
    }
    
    func requestForVideoTrack(jid : String? = nil) -> Int? {
        if let memberJid = jid {
            _ = validateAndAddMember(jid: memberJid, with: .connected)
            if let videTrack = CallManager.getRemoteVideoTrack(jid: memberJid) {
                if let index = findIndexOfUser(jid: memberJid) {
                    releaseTrackViewBy(memberIndex: index)
                    members[index].videoTrack = nil
                    members[index].videoTrack = videTrack
                    print("#mute Track available for : \(jid)")
                    return index
                }
            }else{
                print("#mute vTrack not available for : \(memberJid)")
                print("#call requestForVideoTrack() Track not available for : \(memberJid)")
            }
        } else {
            for member in members {
                if let videTrack = CallManager.getRemoteVideoTrack(jid: member.jid) {
                    if let index = findIndexOfUser(jid: member.jid) {
                        releaseTrackViewBy(memberIndex: index)
                        members[index].videoTrack = videTrack
                        print("#mute Track available for : \(member.jid)")
                    }
                }else{
                    print("#mute Track not available for : \(member.jid)")
                    print("#call requestForVideoTrack() Track not available for : \(member.jid)")
                }
            }
        }
        return nil
    }
    
    func clearAllTrackViews()  {
        for member in members{
            releaseTrackViewBy(member: member)
        }
        outgoingCallView?.localVideoView?.renderFrame(nil)
        outgoingCallView?.remoteVideoView?.renderFrame(nil)
    }
    
    func releaseTrackViewBy(memberIndex: Int) {
        if memberIndex < members.count && memberIndex >= 0 {
            if let trackView = members[memberIndex].videoTrackView, let track = members[memberIndex].videoTrack {
                track.remove(trackView)
                trackView.renderFrame(nil)
            }
        }
    }
    
    func releaseTrackViewBy(member: CallMember?) {
        if let member = member {
            if let trackView = member.videoTrackView, let track = member.videoTrack {
                track.remove(trackView)
                trackView.renderFrame(nil)
            }
        }
    }
    
    func removeAllMembers() {
        clearAllTrackViews()
        members.removeAll()
        collectionView?.reloadData()
    }
    
    func updateMuteStatus(jid : String, isMute : Bool, isAudio : Bool) -> Int? {
        if let index = findIndexOfUser(jid: jid) {
            if isAudio {
                members[index].isAudioMuted = isMute
            } else {
                members[index].isVideoMuted = isMute
            }
            return index
        }
        return nil
    }
    
    func updateCallStatus(jid: String, status : CallStatus) -> Int? {
        if let index = findIndexOfUser(jid: jid) {
            print("#call updateCallStatus \(jid) \(status.rawValue)")
            members[index].callStatus = status
            return index
        }
        return nil
    }
    
    func reloadCollectionViewForIndex(index: Int?) {
        DispatchQueue.main.async { [weak self] in
            if let itemIndex =  index, self?.collectionView?.numberOfItems(inSection: 0) ?? 0 > index ?? -1, self?.collectionView?.isHidden == false {
                print("#reloadCollectionViewForIndex \(index) \(self?.members[index!].jid)")
                let indexPath = IndexPath(item: itemIndex, section: 0)
                self?.collectionView?.reloadItems(at: [indexPath])
            }
        }
    }
    
    func convertCallStatus(status : CALLSTATUS?) -> CallStatus {
        if let status = status {
            if status == .RINGING {
                return .ringing
            }else if status == .CONNECTED {
                return .connected
            }else if status == .ATTENDED {
                return .connecting
            }else if status == .RECONNECTING {
                return .reconnecting
            }else if status == .RECONNECTED {
                return .reconnected
            } else {
                return .calling
            }
        }else {
            return .calling
        }
    }
    
    func shouldSwitchToOneToOneUI() -> Bool {
        return members.count - 1 == 2
    }
    
    func shouldSwitchToGroupUI() -> Bool {
        return members.count + 1 > 2
    }
    
    func removeDisConnectedUser(userIndex : Int){
        if !members.isEmpty && userIndex < members.count {
            if (collectionView?.numberOfItems(inSection: 0) ?? 0 > userIndex)  {
                var oneToOneUsers : [CallMember] = []
                releaseTrackViewBy(memberIndex: userIndex)
                members.remove(at: userIndex)
                print("#index \(userIndex) #count \(members.count)")
                collectionView?.deleteItems(at: [IndexPath(item: userIndex, section: 0)])
                outgoingCallView.addParticipantBtn.isHidden = !isOnCall
                if !isOnCall{
                   getContactNames()
                }else if members.count == 2 {
                    getContactNames()
                    if CallManager.getCallType() == .Video {
                        clearAllTrackViews()
                    }
                    oneToOneUsers.append(contentsOf: members)
                    removeAllMembers()
                    collectionView?.isHidden = true
                    members.append(contentsOf: oneToOneUsers)
                    if !members.first!.isVideoMuted &&  !members.last!.isVideoMuted {
                        CallManager.setCallType(callType: .Video)
                    }
                    if CallManager.getCallType() == .Audio {
                        CallManager.muteVideo(true)
                        updateOneToOneAudioCallUI()
                        outgoingCallView.OutgoingRingingStatusLabel.text = "Connected"
                        if isTapped{
                            SingleTapGesturTapped(UITapGestureRecognizer())
                        }
                    } else {
                        showConnectedVideoCallOneToOneUI()
                        renderRemoteVideoView1to1()
                        renderLocalVideoView1to1()
                    }
                    outgoingCallView.OutgoingRingingStatusLabel.text = CallManager.getCallStatus(userId: members.first!.jid)?.rawValue ?? "Trying to connect"
                    oneToOneUsers.removeAll()
                    setMuteStatusText()
                } else if members.count < 2{
                    self.dismissWithDelay()
                }
            }else if CallManager.getAllCallUsersList().count <= 1 {
                self.dismissWithDelay()
            }else{
                members.remove(at: userIndex)
                getContactNames()
            }
        }
    }
    
    func addUpdateCallUsersWithStatus(userJid: String, status : CallStatus, reload: Bool = false)  {
        print("#addUpdateCallUsersWithStatus \(userJid) \(status.rawValue)")
        let isNewUser = validateAndAddMember(jid: userJid, with: status)
        if (isOnCall || !(collectionView?.isHidden ?? false)) {
            if isNewUser {
                if reload { insertUsersToCollectionView(userIndex: (members.count - 1 )) } //add new user before local user
            } else {
                if let index = updateCallStatus(jid: userJid, status: status) {
                    if reload { reloadCollectionViewForIndex(index: index) }
                }
            }
        }
    }
    
    func insertUsersToCollectionView(userIndex: Int) {
        if collectionView?.numberOfItems(inSection: 0) == 0 {
            collectionView?.reloadData()
        }else {
            collectionView?.insertItems(at:  [IndexPath(item: userIndex, section: 0)])
        }
        outgoingCallView?.audioMuteStackView.isHidden = true
    }
    
    func renderLocalVideoView1to1() {
        
        DispatchQueue.main.async {  [weak self] in
            self?.outgoingCallView?.localVideoView.isHidden = false
            if let videoView = self?.outgoingCallView?.localVideoView {
                if self?.members.last?.videoTrack == nil {
                    _ = self?.requestForVideoTrack(jid: FlyDefaults.myJid)
                }
                self?.removeOneToOneCallTracks()
                self?.addAndRenderOneToOneCallTracks()
            }
        }
    }
    
    func renderRemoteVideoView1to1() {
        DispatchQueue.main.async { [weak self] in
            self?.outgoingCallView?.remoteVideoView.isHidden = false
            if let videoView = self?.outgoingCallView?.remoteVideoView {
                if self?.members.first?.videoTrack == nil {
                    _ = self?.requestForVideoTrack(jid: self?.members.first?.jid)
                }
                self?.members.first?.videoTrack?.add(videoView)
                self?.setVideoBtnIcon()
            }
        }
        
    }
    
    func renderVideoView(view: RTCMTLVideoView?, track : RTCVideoTrack?){
        if let memberTrack = track , let memberView = view {
            memberTrack.add(memberView)
        }
    }
    
    func getUnavailableUsers(isTimeOut : Bool) -> [String] {
        let currentUsers = isTimeOut ? CallManager.getTimeOutUsersList() ?? [] : CallManager.getCallUsersList() ?? []
        var localUsers = members.compactMap{$0.jid}
        if !members.isEmpty { localUsers.removeLast() }
        var userToBeRemoved : [String] = []
        for userJid in localUsers {
            if !currentUsers.contains(userJid) {
                print("removeUsers \(userJid)")
                userToBeRemoved.append(userJid)
            }
        }
        return userToBeRemoved
    }
    
    func removeUnavailableUsers(removedUsers: [String]) {
        for jid in removedUsers {
            if let index = findIndexOfUser(jid: jid) {
                removeDisConnectedUser(userIndex: index)
            }
        }
    }
    
    func checkIfGroupCallUiIsVisible() -> Bool {
        return collectionView?.isHidden ?? false
    }
    
    func getInvitedUsers()-> [String] {
        var invitedUsers = CallManager.getCallUsersList() ?? []
        let localUsers = members.map{$0.jid!}
        for userJid in localUsers {
            print("#invited \(userJid)")
            if invitedUsers.contains(userJid) {
                invitedUsers.removeAll { oldUser in
                    oldUser == userJid
                }
            }
        }
        return invitedUsers
    }
    
    func dismissWithDelay(callStatus : String = "Disconnected"){
        self.groupId = ""
        speakingTimer?.invalidate()
        speakingTimer = nil
        audioDevicesAlertController?.dismiss(animated: true, completion: {
            self.audioDevicesAlertController = nil
        })
        outgoingCallView?.localVideoView.removeGestureRecognizer(panGesture)
        alertController?.dismiss(animated: true, completion: nil)
        callDurationTimer?.invalidate()
        callDurationTimer = nil
        if ((audioPlayer) != nil) {
            if ((audioPlayer?.isPlaying) != nil) {
                audioPlayer?.stop()
            }
            audioPlayer = nil
        }
        enableButtons(buttons: outgoingCallView?.videoButton, isEnable: false)
        CallManager.incomingUserJidArr.removeAll()
        outgoingCallView?.OutgoingRingingStatusLabel?.isHidden = false
        outgoingCallView?.OutgoingRingingStatusLabel?.text = callStatus
        outgoingCallView?.addParticipantBtn.isHidden = true
        enableDisableUserInteractionFor(view: outgoingCallView?.AttendingBottomView, isDisable: true)
        //        outgoingCallView?.OutgoingRingingStatusLabel?.blink()
        CallManager.disconnectCall()
        DispatchQueue.main.asyncAfter(deadline: .now() +  2) { [weak self] in
            //            self?.outgoingCallView?.OutgoingRingingStatusLabel?.stopBlink()
            self?.resetLocalVideCallUI()
            self?.dismiss()
            self?.callViewOverlay.removeFromSuperview()
            UserDefaults.standard.removeObject(forKey: "seconds")
        }
    }
    
    func enableDisableUserInteractionFor(view : UIView?, isDisable : Bool)  {
        view?.isUserInteractionEnabled = !isDisable
    }
    
    func setVideoBtnIcon()  {
        var image = "VideoDisabled"
        if CallManager.isOneToOneCall() && CallManager.getCallType() == .Audio && (isVideoMuted && members.first?.isVideoMuted ?? false) {
            image = "VideoDisabled"
        }else{
            let isVideoTrackAvaialable = members.last?.videoTrack != nil
            if isVideoMuted && isVideoTrackAvaialable {
                image = "VideoDisabled"
            } else if isVideoTrackAvaialable && !isVideoMuted  {
                image = "VideoEnabled"
            }
        }
        outgoingCallView?.videoButton.setImage(UIImage(named: image ), for: .normal)
    }
    
    func enableButtons(buttons : UIButton?..., isEnable : Bool) {
        for button in buttons{
            button?.isEnabled = isEnable
        }
    }
    
    func checkForEmulator(block: () -> Void){
        #if targetEnvironment(simulator)
        print("Video Can't be rendered in simulator")
        #else
        block()
        #endif
    }
    
    func setTopViewsHeight(){
        if CallManager.getCallType() == .Audio && CallManager.isOneToOneCall() {
            outgoingCallView.viewHeight.constant = 190
            outgoingCallView.imageHeight.constant = 100
            outgoingCallView.timerTop.constant = 8
        } else {
            outgoingCallView.viewHeight.constant = 100
            outgoingCallView.timerTop.constant = 0
            outgoingCallView.imageHeight.constant = 0
        }
        outgoingCallView.nameTop.constant = 8
        outgoingCallView.imageTop.constant = 8
    }
    
    func getCurrentCallStatusAsString() -> String {
        var status = "Trying to connect"
        switch myCallStatus {
        case .attended :
            status = "Connecting"
        case .ringing :
            status = "Ringing"
        case .calling :
            status = "Trying to connect"
        case .connecting :
            status = "Connecting"
        case .connected :
            status = "Connected"
        case .disconnected :
            status = "Disconnected"
        case .reconnecting :
            status = "Reconnecting"
        case .reconnected :
            status = "Connected"
        default:
            status = "Unavailable, Try again later"
        }
        return status
    }
    
    func updateCallTimerDuration(){
        if CallManager.getCallDirection() == .Incoming{
            if isOnCall{
                updateCallDuration()
            }else {
                outgoingCallView?.timerLable.text = "00:00"
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                    self?.updateCallDuration()
                }
            }
        }else{
            updateCallDuration()
        }
    }
    
    func getCallStatusOf(userId : String) -> CallStatus {
        if let member = members.first {$0.jid == userId}{
            return member.callStatus ?? .calling
        }
        return .calling
    }
}

extension CallViewController : ConnectionEventDelegate{
    func onConnected() {
    }
    func onDisconnected() {
    }
    func onConnectionNotAuthorized() {
        CallManager.disconnectCall()
        dismiss()
        FlyDefaults.myMobileNumber = ""
        FlyDefaults.myXmppUsername = ""
        FlyDefaults.myXmppPassword = ""
        FlyDefaults.myXmppResource = ""
        FlyDefaults.xmppDomain = ""
        FlyDefaults.xmppPort = 0
        FlyDefaults.isLoggedIn = false
        let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        let controller : OTPViewController
        if #available(iOS 13.0, *) {
            controller = UIStoryboard(name: "Login", bundle: nil).instantiateViewController(identifier: "OTPViewController")
        } else {
            // Fallback on earlier versions
            controller = UIStoryboard(name: "Login", bundle: nil).instantiateViewController(withIdentifier: "OTPViewController") as! OTPViewController
        }
        if let navigationController = window?.rootViewController  as? UINavigationController {
            navigationController.popToRootViewController(animated: false)
            navigationController.pushViewController(controller, animated: false)
        }
    }
    
    @objc func copyLink(sender:UIButton){
        if let callLink = CallManager.getCallLink(){
            UIPasteboard.general.string = callLink
            Toast.init(text: "CallLink \(callLink) copied").show()
        }
    }
}


extension CallViewController : AudioManagerDelegate {
    
    func audioRoutedTo(deviceName: String, audioDeviceType: OutputType) {
        print("#audiomanager audioRoutedTo  CallViewController \(deviceName) \(audioDeviceType)")
        switch audioDeviceType {
        case .receiver:
            currentOutputDevice = .receiver
            outgoingCallView?.speakerButton.setImage(UIImage(named: "IconSpeakerOff" ), for: .normal)
        case .speaker:
            currentOutputDevice = .speaker
            outgoingCallView?.speakerButton.setImage(UIImage(named: "IconSpeakerOn" ), for: .normal)
        case .headset:
            currentOutputDevice = .headset
            outgoingCallView?.speakerButton.setImage(UIImage(named: "headset" ), for: .normal)
        case .bluetooth:
            currentOutputDevice = .bluetooth
            outgoingCallView?.speakerButton.setImage(UIImage(named: "bluetooth_headset" ), for: .normal)
        }
    }
    
    @objc func showAudioActionSheet(sender:UIButton){
        audioDevicesAlertController = UIAlertController(title: "Available Devices", message: nil, preferredStyle: .actionSheet)
        for item in AudioManager.shared().getAllAvailableAudioInput() {
            let action = UIAlertAction(title: item.name, style: .default) { _ in
                AudioManager.shared().routeAudioTo(device: item.type, force: true)
            }
            if item.type == currentOutputDevice{
                let image = UIImage(named: "selectedImg")
                action.setValue(image?.withRenderingMode(.alwaysOriginal), forKey: "image")
            }
            audioDevicesAlertController!.addAction(action)
        }
        audioDevicesAlertController!.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(audioDevicesAlertController!, animated: true)
    }
}

extension CallViewController {
    
    func onUserSpeaking(userId: String, audioLevel: Int) {
        print("#speak speaking \(userId) : \(audioLevel)")
        speakingDictionary[userId] = audioLevel
    }
    
    func onUserStoppedSpeaking(userId: String) {
        print("#speak stopped \(userId)")
        speakingDictionary[userId] = -1
    }
    
    func updateSpeakingUI(userId : String, isSpeaking : Bool, audioLevel : Int = 0 ){
        if !CallManager.isOneToOneCall()  {
            if userId == FlyDefaults.myJid && isAudioMuted == true && isSpeaking == true {
                updateSpeakingUI(userId: userId, isSpeaking: false)
            }
            if getCallStatusOf(userId: userId) != .connected{
                return
            }
            if let index = findIndexOfUser(jid: userId) {
                if let cell = collectionView?.cellForItem(at: IndexPath(item: index, section: 0)) as? GroupCallCell{
                    if isSpeaking {
                        cell.contentVIew.layer.borderWidth = 5
                        cell.contentVIew.layer.borderColor = UIColor(named: "PrimaryAppColor")?.cgColor ?? UIColor.systemBlue.cgColor
                    }else {
                        cell.contentVIew.layer.borderWidth = 0
                    }
                }
            }
        }
    }
    
    @objc func validateSpeaking() {
        var highAudioLevel = 0
        var highAudioUserId = ""
        var lastHighAudioUser = ""
        for (id, audioLevel) in speakingDictionary{
            if audioLevel > highAudioLevel{
                highAudioLevel = audioLevel
                highAudioUserId = id
            }
        }
        print("#validateSpeaking loudUser id \(highAudioUserId)")
        var notSpeakingUsers = Array(speakingDictionary.keys)
        notSpeakingUsers.removeAll{$0 == highAudioUserId}
        for userId in notSpeakingUsers{
            updateSpeakingUI(userId: userId, isSpeaking: false)
        }
        if !highAudioUserId.isEmpty {
            lastHighAudioUser = highAudioUserId
            updateSpeakingUI(userId: highAudioUserId, isSpeaking: true)
        }
       
    }
    
}

extension CallViewController {
    
    func removeOneToOneCallTracks(){
        if let localView = outgoingCallView.localVideoView, let remoteView = outgoingCallView.remoteVideoView {
            if let localTrack = members.last?.videoTrack {
                    localTrack.remove(localView)
                    localTrack.remove(remoteView)
                    localView.renderFrame(nil)
            }
            if let remoteTrack = members.first?.videoTrack {
                    remoteTrack.remove(remoteView)
                    remoteTrack.remove(localView)
                    remoteView.renderFrame(nil)
            }
        }
    }
    
    func addAndRenderOneToOneCallTracks(){
        if let localView = outgoingCallView.localVideoView, let remoteView = outgoingCallView.remoteVideoView{
            if let localTrack = members.last?.videoTrack{
                if isLocalViewSwitched{
                    localTrack.add(remoteView)
                }else{
                    localTrack.add(localView)
                }
            }
            if let remoteTrack = members.first?.videoTrack {
                if isLocalViewSwitched{
                    remoteTrack.add(localView)
                }else{
                    remoteTrack.add(remoteView)
                }
            }
        }
    }
    
    func oneToOneVideoViewTransforms(){
        if let localView = outgoingCallView.localVideoView, let remoteView = outgoingCallView.remoteVideoView {
            if isBackCamera {
                if isLocalViewSwitched{
                    remoteView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                }else{
                    localView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                }
            }else{
                if isLocalViewSwitched{
                    remoteView.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
                }else{
                    localView.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
                }
            }
        }
    }
    
    @objc func smallVideoTileTapped(_ sender: UITapGestureRecognizer) {
        if CallManager.isOneToOneCall() && CallManager.isCallConnected(){
            removeOneToOneCallTracks()
            isLocalViewSwitched = !isLocalViewSwitched
            oneToOneVideoViewTransforms()
            addAndRenderOneToOneCallTracks()
        }
    }
}

extension CallViewController : ProfileEventsDelegate{
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
        if CallManager.isOneToOneCall() && CallManager.getAllCallUsersList().contains(jid){
            dismissWithDelay()
        }else{
            onCallStatusUpdated(callStatus: .DISCONNECTED, userId: jid)
        }
    }
    
    
}

extension CallViewController : RefreshProfileInfo {
    
    func refreshProfileDetails(profileDetails: ProfileDetails?) {
        if let jid = profileDetails?.jid{
            if CallManager.isOneToOneCall() && CallManager.getAllCallUsersList().contains(jid){
                dismissWithDelay()
            }else{
                onCallStatusUpdated(callStatus: .DISCONNECTED, userId: jid)
            }
        }
    }
}
