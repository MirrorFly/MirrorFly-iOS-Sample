//  AudioSender.swift
//  MirrorflyUIkit
//  Created by User on 31/08/21.

import UIKit
import FlyCommon
import AVFoundation
import NicoProgress
import MapKit
import GoogleMaps
import FlyCore
import SDWebImage

class AudioSender: BaseTableViewCell, AVAudioPlayerDelegate {
    @IBOutlet weak var uploadCancel: UIImageView?
    @IBOutlet weak var fwdViw: UIView?
    @IBOutlet weak var audioPlaySlider: UISlider?
    @IBOutlet var nicoProgressBar: UIView!
    @IBOutlet weak var updateCancelButton: UIButton?
    @IBOutlet weak var fwdBtn: UIButton?
    @IBOutlet weak var fwdIcon: UIImageView?
    @IBOutlet weak var sentTime: UILabel?
    @IBOutlet weak var autioDuration: UILabel?
    @IBOutlet weak var playIcon: UIImageView?
    @IBOutlet weak var progressBar: UIView?
    @IBOutlet weak var status: UIImageView?
    @IBOutlet weak var playButton: UIButton?
    @IBOutlet weak var audioView: UIView?
    @IBOutlet weak var timeView: UIView?
    @IBOutlet weak var audioSenderIcon: UIImageView?
    
    // Starred Messages Outlet
    @IBOutlet weak var favImageView: UIImageView?
    @IBOutlet weak var senderStackView: UIStackView?
    @IBOutlet weak var senderToLabel: UILabel?
    @IBOutlet weak var senderTimeLabel: UILabel?
    @IBOutlet weak var senderProfileImageView: UIImageView?
    @IBOutlet weak var bubbleImageBottomCons: NSLayoutConstraint?
    @IBOutlet weak var bubbleImageTopCons: NSLayoutConstraint?
    @IBOutlet weak var starredMessageView: UIView?
    @IBOutlet weak var senderFromLabel: UILabel?
    
    // Reply View Outlet
    @IBOutlet weak var mediaLocationMap: GMSMapView?
    @IBOutlet weak var bubbleImageView: UIImageView?
    @IBOutlet weak var mediaImageView: UIImageView?
    @IBOutlet weak var userTextLabel: UILabel?
    @IBOutlet weak var messageTypeIcon: UIImageView?
    @IBOutlet weak var messageTypeIconView: UIView?
    @IBOutlet weak var replyUserLabel: UILabel?
    @IBOutlet weak var replyView: UIView?
    @IBOutlet weak var replyWithoutMediaCons: NSLayoutConstraint?
    @IBOutlet weak var replyWithMediaCons: NSLayoutConstraint?
    
    // Forward Outlet
    @IBOutlet weak var forwardImageView: UIImageView?
    @IBOutlet weak var forwardView: UIView?
    @IBOutlet weak var forwardLeadingCons: NSLayoutConstraint?
    @IBOutlet weak var forwardButton: UIButton?
    
    // Starred Messages Outlet
    @IBOutlet weak var starredMessagesView: UIView?
    
    var message : ChatMessage?
    var sendMediaMessages: [ChatMessage]? = []
    var selectedForwardMessage: [SelectedMessages]? = []
    var refreshDelegate: RefreshBubbleImageViewDelegate? = nil
    var uploadingMediaObjects: [ChatMessage]? = []
    var audioPlayer:AVAudioPlayer?
    var isShowAudioLoadingIcon: Bool? = false
    var updater : CADisplayLink! = nil
    typealias AudioCallBack = (_ sliderValue : Float) -> Void
    var audioCallBack: AudioCallBack? = nil
    var isStarredMessagePage: Bool? = false
    var newProgressBar: ProgressBar!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        setupUI()
    }
    
    func setupUI() {
        sentTime?.font = UIFont.font9px_appLight()
        autioDuration?.font = UIFont.font8px_appLight()
        starredMessageView?.roundCorners(corners: [.topLeft, .bottomLeft, .topRight], radius: 5.0)
        audioView?.roundCorners(corners: [.topLeft, .topRight], radius: 8.0)
        timeView?.roundCorners(corners: [.topLeft, .topRight, .bottomLeft], radius: 8.0)
        var thumbImage = UIImage(named: ImageConstant.ic_slider_white)
        let size = getCGSize(width: 15, height: 15)
        thumbImage = thumbImage?.scaleToSize(newSize: size)
        audioPlaySlider?.setThumbImage( thumbImage, for: UIControl.State.normal)
        audioPlaySlider?.minimumValue = 0
        audioPlaySlider?.maximumValue = 100
        audioSenderIcon?.image = UIImage(named: ImageConstant.ic_music)
        newProgressBar = ProgressBar(frame: CGRect(x: 0, y: 0, width: nicoProgressBar.frame.width, height: nicoProgressBar.frame.height))
        newProgressBar.primaryColor = .white
        newProgressBar.bgColor = .clear
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    @IBAction func fwd(_ sender: Any) {
        print("called")
    }
   
    @objc func trackAudio() {
        if let curnTime = audioPlayer?.currentTime {
            if let duration = audioPlayer?.duration {
      let normalizedTime = Float(curnTime * 100.0 / duration)
                audioPlaySlider?.value = normalizedTime
        print(normalizedTime)
                print(curnTime)
                    let min = Int(curnTime / 60)
                    let sec = Int(curnTime.truncatingRemainder(dividingBy: 60))
                    let totalTimeString = String(format: "%02d:%02d", min, sec)
                autioDuration?.text = totalTimeString
                   print(totalTimeString)
            }
        }
    }
    
    func showHideStarredMessageView() {
        starredMessageView?.isHidden = isStarredMessagePage == true ? false : true
        bubbleImageTopCons?.isActive = isStarredMessagePage == true ? false : true
        senderStackView?.isHidden = isStarredMessagePage == true ? false : true
        bubbleImageBottomCons?.constant = isStarredMessagePage == true ? 10 : 3
    }
    
    func setUserProfileInfo(message: ChatMessage?,isBlocked: Bool) {
        let getProfileDetails = ChatManager.profileDetaisFor(jid: message?.chatUserJid ?? "")
        let senderProfileDetails = ChatManager.profileDetaisFor(jid: message?.senderUserJid ?? "")
        senderFromLabel?.text = "You"
        senderToLabel?.text = getUserName(jid : getProfileDetails?.jid ?? "" ,name: getProfileDetails?.name ?? "", nickName: getProfileDetails?.nickName ?? "", contactType: getProfileDetails?.contactType ?? .local)
    
        let timeStamp =  message?.messageSentTime
        senderTimeLabel?.text = String(describing: DateFormatterUtility.shared.convertMillisecondsToSentTime(milliSeconds: timeStamp ?? 0.0))
        senderProfileImageView?.makeRounded()
        let contactColor = getColor(userName: getUserName(jid: senderProfileDetails?.jid ?? "",name: senderProfileDetails?.name ?? "", nickName: senderProfileDetails?.nickName ?? "", contactType: senderProfileDetails?.contactType ?? .local))
        setImage(imageURL: senderProfileDetails?.image ?? "", name: getUserName(jid: senderProfileDetails?.jid ?? "", name: senderProfileDetails?.name ?? "", nickName: senderProfileDetails?.nickName ?? "", contactType: senderProfileDetails?.contactType ?? .local), color: contactColor, chatType: senderProfileDetails?.profileChatType ?? .singleChat, jid: senderProfileDetails?.jid ?? "")
    }
    
    private func getisBlockedMe(jid: String) -> Bool {
        return ChatManager.getContact(jid: jid)?.isBlockedMe ?? false
    }
    
    func setImage(imageURL: String, name: String, color: UIColor, chatType : ChatType,jid: String) {
        if !getisBlockedMe(jid: jid) {
            senderProfileImageView?.loadFlyImage(imageURL: imageURL, name: name, chatType: chatType, jid: jid)
        } else if chatType == .groupChat {
            senderProfileImageView?.image = UIImage(named: ImageConstant.ic_group_small_placeholder)!
        }  else {
            senderProfileImageView?.image = UIImage(named: ImageConstant.ic_profile_placeholder)!
        }
    }
    
    func getCellFor(_ message: ChatMessage?, at indexPath: IndexPath?,isPlaying: Bool,audioClosureCallBack : @escaping AudioCallBack,isShowForwardView: Bool?,isDeleteMessageSelected: Bool?, fromChat: Bool = false, isMessageSearch: Bool = false, searchText: String = "") -> AudioSender? {
        audioCallBack = audioClosureCallBack
        currentIndexPath = nil
        currentIndexPath = indexPath
        self.message = message
        let duration = Int(message?.mediaChatMessage?.mediaDuration ?? 0)
        autioDuration?.text = "\(duration.msToSeconds.minuteSecondMS)"
        // Starred Messages
        favImageView?.isHidden =  message!.isMessageStarred ? false : true
        showHideForwardView(message: message, isShowForwardView: isShowForwardView, isDeleteMessageSelected: isDeleteMessageSelected)
        if selectedForwardMessage?.filter({$0.chatMessage.messageId == message?.messageId}).first?.isSelected == true {
            forwardImageView?.image = UIImage(named: "forwardSelected")
            forwardImageView?.isHidden = false
            forwardView?.makeCircleView(borderColor: Color.forwardCircleBorderColor.cgColor, borderWidth: 0.0)
        } else {
           // forwardImageView?.image = UIImage(named: "")
            forwardImageView?.isHidden = true
            forwardView?.makeCircleView(borderColor: Color.forwardCircleBorderColor.cgColor, borderWidth: 1.5)
        }
        if message?.isCarbonMessage == true {
            if  (message?.mediaChatMessage?.mediaDownloadStatus == .not_downloaded || message?.mediaChatMessage?.mediaDownloadStatus == .failed || message?.mediaChatMessage?.mediaDownloadStatus == .downloading || message?.messageStatus == .notAcknowledged || isShowForwardView == true || isStarredMessagePage == true) {
                fwdViw?.isHidden = true
                fwdBtn?.isHidden = true
                isAllowSwipe = false
            } else {
                fwdViw?.isHidden = false
                fwdBtn?.isHidden = false
                isAllowSwipe = true
            }
        } else {
            if  (message?.mediaChatMessage?.mediaUploadStatus == .not_uploaded || message?.mediaChatMessage?.mediaUploadStatus == .failed || message?.mediaChatMessage?.mediaUploadStatus == .uploading || message?.messageStatus == .notAcknowledged || isShowForwardView == true || isStarredMessagePage == true) {
                fwdViw?.isHidden = true
                fwdBtn?.isHidden = true
                isAllowSwipe = false
            } else {
                fwdViw?.isHidden = false
                fwdBtn?.isHidden = false
                isAllowSwipe = true
            }
        }
        
        if message?.mediaChatMessage?.audioType == AudioType.recording {
            audioSenderIcon?.image = UIImage(named: ImageConstant.ic_audio_recorded)
        } else {
            audioSenderIcon?.image = UIImage(named: ImageConstant.ic_music)
        }
        
        // Reply view elements and its data
       if(message!.isReplyMessage) {
           replyView?.isHidden = false
            let getReplymessage =  message?.replyParentChatMessage?.messageTextContent
           let replyMessage = FlyMessenger.getMessageOfId(messageId: message?.replyParentChatMessage?.messageId ?? "")
           if message?.replyParentChatMessage?.isMessageDeleted == true || message?.replyParentChatMessage?.isMessageRecalled == true || replyMessage == nil {
               userTextLabel?.text = "Original message not available"
               messageTypeIconView?.isHidden = true
               mediaLocationMap?.isHidden = true
               mediaImageView?.isHidden = true
           } else {
               mediaLocationMap?.isHidden = true
               userTextLabel?.attributedText = ChatUtils.getAttributedMessage(message: getReplymessage ?? "", searchText: searchText, isMessageSearch: isMessageSearch, isSystemBlue: false)
               if replyMessage?.mediaChatMessage?.messageType == .document {
                   mediaImageView?.contentMode = .scaleAspectFit
               } else {
                   mediaImageView?.contentMode = .scaleAspectFill
               }
               if replyMessage?.mediaChatMessage != nil {
                   switch replyMessage?.mediaChatMessage?.messageType {
                   case .image:
                       messageTypeIcon?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "senderCamera" : "receiverCamera")
                       if let thumImage = message?.replyParentChatMessage?.mediaChatMessage?.mediaThumbImage {
                           let converter = ImageConverter()
                           let image =  converter.base64ToImage(thumImage)
                           mediaImageView?.image = image
                           mediaImageView?.isHidden = false
                           messageTypeIconView?.isHidden = false
                           userTextLabel?.text = (!(message?.replyParentChatMessage?.mediaChatMessage?.mediaCaptionText.isEmpty ?? false)) ? message?.replyParentChatMessage?.mediaChatMessage?.mediaCaptionText : "Photo"
                       }
                       replyWithMediaCons?.isActive = true
                       replyWithoutMediaCons?.isActive = false
                   case .audio:
                       let duration = Int(message?.replyParentChatMessage?.mediaChatMessage?.mediaDuration ?? 0)
                       ChatUtils.setIconForAudio(imageView: messageTypeIcon, chatMessage: nil, replyParentMessage: message?.replyParentChatMessage)
                       userTextLabel?.text = (!(message?.replyParentChatMessage?.mediaChatMessage?.mediaCaptionText.isEmpty ?? false)) ? message?.replyParentChatMessage?.mediaChatMessage?.mediaCaptionText : message?.replyParentChatMessage?.mediaChatMessage?.messageType.rawValue.capitalized.appending(" (\(duration.msToSeconds.minuteSecondMS))")
                       messageTypeIconView?.isHidden = false
                       replyWithMediaCons?.isActive = false
                       replyWithoutMediaCons?.isActive = true
                       mediaImageView?.isHidden = true
                   case .video:
                       messageTypeIcon?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "senderVideo" : "video")
                       messageTypeIconView?.isHidden = false
                       if let thumImage = message?.replyParentChatMessage?.mediaChatMessage?.mediaThumbImage {
                           let converter = ImageConverter()
                           let image =  converter.base64ToImage(thumImage)
                           mediaImageView?.image = image
                           mediaImageView?.isHidden = false
                           userTextLabel?.text = (!(message?.replyParentChatMessage?.mediaChatMessage?.mediaCaptionText.isEmpty ?? false)) ? message?.replyParentChatMessage?.mediaChatMessage?.mediaCaptionText : message?.replyParentChatMessage?.mediaChatMessage?.messageType.rawValue.capitalized
                       }
                       replyWithMediaCons?.isActive = true
                       replyWithoutMediaCons?.isActive = false
                   case .document:
                       messageTypeIcon?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "document" : "document")
                       userTextLabel?.text = replyMessage?.mediaChatMessage?.mediaFileName.capitalized
                       replyWithMediaCons?.isActive = true
                       replyWithoutMediaCons?.isActive = false
                       checkFileType(url: replyMessage?.mediaChatMessage?.mediaFileUrl ?? "", typeImageView: mediaImageView)
                       mediaImageView?.isHidden = false
                       replyWithMediaCons?.isActive = true
                       replyWithoutMediaCons?.isActive = false
                   default:
                       messageTypeIconView?.isHidden = true
                       replyWithMediaCons?.isActive = false
                       replyWithoutMediaCons?.isActive = true
                   }
                   
               } else if replyMessage?.locationChatMessage != nil {
                   mediaLocationMap?.isHidden = false
                   userTextLabel?.text = "Location"
                   messageTypeIcon?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "map" : "receivedMap")
                   messageTypeIconView?.isHidden = false
                   guard let latitude = message?.replyParentChatMessage?.locationChatMessage?.latitude else {
                       return nil
                   }
                   guard let longitude = message?.replyParentChatMessage?.locationChatMessage?.longitude  else {
                       return nil
                   }
                   mediaLocationMap?.isUserInteractionEnabled = false
                   mediaLocationMap?.camera = GMSCameraPosition.camera(withLatitude: latitude, longitude: longitude, zoom: 16.0, bearing: 360.0, viewingAngle: 15.0)
                   replyWithMediaCons?.isActive = true
                   replyWithoutMediaCons?.isActive = false
                   DispatchQueue.main.async
                   { [self] in
                       // 2. Perform UI Operations.
                       var position = CLLocationCoordinate2DMake(latitude,longitude)
                       var marker = GMSMarker(position: position)
                       marker.map = mediaLocationMap
                   }
               } else if replyMessage?.contactChatMessage != nil {
                   let replyTextMessage = "Contact: \(message?.replyParentChatMessage?.contactChatMessage?.contactName ?? "")"
                   userTextLabel?.attributedText = ChatUtils.setAttributeString(name: message?.replyParentChatMessage?.contactChatMessage?.contactName)
                   messageTypeIcon?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "senderContact" : "receiverContact")
                   messageTypeIconView?.isHidden = false
                   replyWithMediaCons?.isActive = false
                   replyWithoutMediaCons?.isActive = true
               } else {
                   replyWithMediaCons?.isActive = false
                   replyWithoutMediaCons?.isActive = true
                   messageTypeIconView?.isHidden = true
               }
           }
        if(message!.replyParentChatMessage!.isMessageSentByMe) {
            replyUserLabel?.text = you.localized
        }
        else {
            replyUserLabel?.text = getUserName(jid: replyMessage?.senderUserJid ?? "" ,name: replyMessage?.senderUserName ?? "",
                                               nickName: replyMessage?.senderNickName ?? "", contactType: (replyMessage?.isDeletedUser ?? false) ? .deleted : (replyMessage?.isSavedContact ?? false) ? .live : .unknown)
        }
    } else {
            replyView?.isHidden = true
        }
        
        ChatUtils.setSenderBubbleBackground(imageView: bubbleImageView)
        if message?.isCarbonMessage == false {
            if message?.mediaChatMessage?.mediaUploadStatus == .not_uploaded {
                uploadCancel?.isHidden = false
                playIcon?.isHidden = true
                playButton?.isHidden = true
                uploadCancel?.image = (isShowAudioLoadingIcon == true && indexPath == IndexPath(row: 0, section: 0)) ? UIImage(named: ImageConstant.ic_audioUploadCancel) : UIImage(named: ImageConstant.ic_upload)
                updateCancelButton?.isHidden = (isShowAudioLoadingIcon == true && indexPath == IndexPath(row: 0, section: 0)) ? true : false
                audioPlaySlider?.isUserInteractionEnabled = false
                newProgressBar.removeFromSuperview()
            } else if message?.mediaChatMessage?.mediaUploadStatus == .failed {
                uploadCancel?.isHidden = false
                playIcon?.isHidden = true
                playButton?.isHidden = true
                uploadCancel?.image = (isShowAudioLoadingIcon == true && indexPath == IndexPath(row: 0, section: 0)) ? UIImage(named: ImageConstant.ic_audioUploadCancel) : UIImage(named: ImageConstant.ic_upload)
                updateCancelButton?.isHidden = (isShowAudioLoadingIcon == true && indexPath == IndexPath(row: 0, section: 0)) ? true : false
                audioPlaySlider?.isUserInteractionEnabled = false
                newProgressBar.removeFromSuperview()
            } else if message?.mediaChatMessage?.mediaUploadStatus == .uploading {
                uploadCancel?.image = UIImage(named: ImageConstant.ic_audioUploadCancel)
                nicoProgressBar.addSubview(newProgressBar)
                uploadCancel?.isHidden = false
                playIcon?.isHidden = true
                playButton?.isHidden = true
                updateCancelButton?.isHidden = false
                audioPlaySlider?.isUserInteractionEnabled = false
                uploadingMediaObjects?.forEach({ chatMessage in
                    if chatMessage.messageId == message?.messageId {
//                        nicoProgressBar?.transition(to: .indeterminate)
                        nicoProgressBar.addSubview(newProgressBar)
                    } else {
                        nicoProgressBar.addSubview(newProgressBar)
                    }
                })
            } else if message?.mediaChatMessage?.mediaUploadStatus == .uploaded {
                playIcon?.image = isPlaying ? UIImage(named: ImageConstant.ic_audio_pause) : UIImage(named: ImageConstant.ic_play)
                playIcon?.isHidden = false
                uploadCancel?.isHidden = true
                newProgressBar.removeFromSuperview()
                audioPlaySlider?.isUserInteractionEnabled = true
                playButton?.isHidden = false
            } else {
                audioPlaySlider?.isUserInteractionEnabled = false
            }
        } else {
            if message?.mediaChatMessage?.mediaDownloadStatus == .not_downloaded {
                uploadCancel?.isHidden = false
                playIcon?.isHidden = true
                playButton?.isHidden = true
                uploadCancel?.image = (isShowAudioLoadingIcon == true && indexPath == IndexPath(row: 0, section: 0)) ? UIImage(named: ImageConstant.ic_audioUploadCancel) : UIImage(named: "download")
                updateCancelButton?.isHidden = (isShowAudioLoadingIcon == true && indexPath == IndexPath(row: 0, section: 0)) ? true : false
                audioPlaySlider?.isUserInteractionEnabled = false
                newProgressBar.removeFromSuperview()
            } else if message?.mediaChatMessage?.mediaDownloadStatus == .failed {
                uploadCancel?.isHidden = false
                playIcon?.isHidden = true
                playButton?.isHidden = true
                uploadCancel?.image = (isShowAudioLoadingIcon == true && indexPath == IndexPath(row: 0, section: 0)) ? UIImage(named: ImageConstant.ic_audioUploadCancel) : UIImage(named: "download")
                updateCancelButton?.isHidden = (isShowAudioLoadingIcon == true && indexPath == IndexPath(row: 0, section: 0)) ? true : false
                audioPlaySlider?.isUserInteractionEnabled = false
                newProgressBar.removeFromSuperview()
            } else if message?.mediaChatMessage?.mediaDownloadStatus == .downloading {
                uploadCancel?.image = UIImage(named: ImageConstant.ic_audioUploadCancel)
                nicoProgressBar.addSubview(newProgressBar)
//                nicoProgressBar?.transition(to: .indeterminate)
                uploadCancel?.isHidden = false
                playIcon?.isHidden = true
                playButton?.isHidden = true
                updateCancelButton?.isHidden = false
                audioPlaySlider?.isUserInteractionEnabled = false
//                uploadingMediaObjects?.forEach({ chatMessage in
//                    if chatMessage.messageId == message?.messageId {
//                        nicoProgressBar?.transition(to: .indeterminate)
//                        nicoProgressBar?.startInit()
//                    } else {
//                        nicoProgressBar?.startInit()
//                    }
//                })
            } else if message?.mediaChatMessage?.mediaDownloadStatus == .downloaded {
                playIcon?.image = isPlaying ? UIImage(named: ImageConstant.ic_audio_pause) : UIImage(named: ImageConstant.ic_play)
                playIcon?.isHidden = false
                uploadCancel?.isHidden = true
                newProgressBar.removeFromSuperview()
                audioPlaySlider?.isUserInteractionEnabled = true
                playButton?.isHidden = false
            } else {
                audioPlaySlider?.isUserInteractionEnabled = false
            }
        }
        switch message?.messageStatus {
        case .notAcknowledged:
            status?.image = UIImage(named: ImageConstant.ic_hour)
            status?.accessibilityLabel = notAcknowledged.localized
            break
        case .sent:
            status?.image = UIImage(named: ImageConstant.ic_hour)
            status?.accessibilityLabel = sent.localized
            break
        case .acknowledged:
            status?.image = UIImage(named: ImageConstant.ic_sent)
            status?.accessibilityLabel = acknowledged.localized
            break
        case .delivered:
            status?.image = UIImage(named: ImageConstant.ic_delivered)
            status?.accessibilityLabel = delivered.localized
            break
        case .seen:
            status?.image = UIImage(named: ImageConstant.ic_seen)
            status?.accessibilityLabel = seen.localized
            break
        case .received:
            status?.image = UIImage(named: ImageConstant.ic_delivered)
            status?.accessibilityLabel = delivered.localized
            break
        default:
            status?.image = UIImage(named: ImageConstant.ic_hour)
            status?.accessibilityLabel = notAcknowledged.localized
            break
        }
        guard let timeStamp =  message?.messageSentTime else {
            return self
        }
        self.sentTime?.text = DateFormatterUtility.shared.currentMillisecondsToLocalTime(milliSec: timeStamp)
        return self
    }
    
    func stopDisplayLink() {
        updater?.invalidate()
        updater = nil
     }
    
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playIcon?.image = UIImage(named: ImageConstant.ic_play)
        player.stop()
        stopDisplayLink()
    }
    
    func showHideForwardView(message: ChatMessage?,isShowForwardView: Bool?,isDeleteMessageSelected: Bool?) {
        if isDeleteMessageSelected ?? false || isStarredMessagePage == true {
            // Forward view elements and its data
            forwardView?.isHidden = (isShowForwardView == false || message?.mediaChatMessage?.mediaUploadStatus == .uploading)  || (message?.isMessageRecalled == true) ? true : false
            forwardView?.makeCircleView(borderColor: Color.forwardCircleBorderColor.cgColor, borderWidth: 1.5)
            forwardLeadingCons?.constant = (isShowForwardView == false || message?.mediaChatMessage?.mediaUploadStatus == .uploading)  || (message?.isMessageRecalled == true) ? 0 : 20
            forwardButton?.isHidden = (isShowForwardView == false || message?.mediaChatMessage?.mediaUploadStatus == .uploading)  || (message?.isMessageRecalled == true) ? true : false
        } else {
            // Forward view elements and its data
            forwardView?.isHidden = (isShowForwardView == true && message?.mediaChatMessage?.mediaUploadStatus == .uploaded && message?.isMessageRecalled == false) ? false : true
            forwardView?.makeCircleView(borderColor: Color.forwardCircleBorderColor.cgColor, borderWidth: 1.5)
            forwardLeadingCons?.constant = (isShowForwardView == true && message?.mediaChatMessage?.mediaUploadStatus == .uploaded && message?.isMessageRecalled == false) ? 20 : 0
            forwardButton?.isHidden = (isShowForwardView == true && message?.mediaChatMessage?.mediaUploadStatus == .uploaded && message?.isMessageRecalled == false) ? false : true
        }
    }

    func startUpload() {
        uploadCancel?.isHidden = false
        playIcon?.isHidden = true
        playButton?.isHidden = true
        uploadCancel?.image = UIImage(named: ImageConstant.ic_audioUploadCancel)
        updateCancelButton?.isHidden = false
        audioPlaySlider?.isUserInteractionEnabled = false
        nicoProgressBar.addSubview(newProgressBar)
    }
    
    func stopUpload() {
        uploadCancel?.isHidden = false
        playIcon?.isHidden = true
        playButton?.isHidden = true
        uploadCancel?.image = UIImage(named: ImageConstant.ic_upload)
        updateCancelButton?.isHidden = false
        audioPlaySlider?.isUserInteractionEnabled = false
        newProgressBar.removeFromSuperview()
    }
    
    func stopDownload() {
        uploadCancel?.isHidden = false
        playIcon?.isHidden = true
        playButton?.isHidden = true
        uploadCancel?.image = UIImage(named: "download")
        updateCancelButton?.isHidden = false
        audioPlaySlider?.isUserInteractionEnabled = false
        newProgressBar.removeFromSuperview()
    }
    
//    func showProgress(percentage: CGFloat) {
//        executeOnMainThread { [weak self] in
//            guard let self else {return}
//            self.newProgressBar.setProg(per: percentage)
//        }
//    }
}


