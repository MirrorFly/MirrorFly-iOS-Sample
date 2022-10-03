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

class AudioSender: BaseTableViewCell, AVAudioPlayerDelegate {
    @IBOutlet weak var uploadCancel: UIImageView?
    @IBOutlet weak var fwdViw: UIView?
    @IBOutlet weak var audioPlaySlider: UISlider?
    @IBOutlet weak var nicoProgressBar: NicoProgressBar?
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
    
    var message : ChatMessage?
    var sendMediaMessages: [ChatMessage]? = []
    var selectedForwardMessage: [SelectedForwardMessage]? = []
    var refreshDelegate: RefreshBubbleImageViewDelegate? = nil
    var uploadingMediaObjects: [ChatMessage]? = []
    var audioPlayer:AVAudioPlayer?
    var isShowAudioLoadingIcon: Bool? = false
    var updater : CADisplayLink! = nil
    typealias AudioCallBack = (_ sliderValue : Float) -> Void
        var audioCallBack: AudioCallBack? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        setupUI()
    }
    
    
    func setupUI() {
        sentTime?.font = UIFont.font9px_appLight()
        autioDuration?.font = UIFont.font8px_appLight()
        audioView?.roundCorners(corners: [.topLeft, .topRight], radius: 8.0)
        timeView?.roundCorners(corners: [.topLeft, .topRight, .bottomLeft], radius: 8.0)
        var thumbImage = UIImage(named: ImageConstant.ic_slider_white)
        let size = getCGSize(width: 15, height: 15)
        thumbImage = thumbImage?.scaleToSize(newSize: size)
        audioPlaySlider?.setThumbImage( thumbImage, for: UIControl.State.normal)
        audioPlaySlider?.minimumValue = 0
        audioPlaySlider?.maximumValue = 100
        audioSenderIcon?.image = UIImage(named: ImageConstant.ic_music)
        nicoProgressBar?.primaryColor = .white
        nicoProgressBar?.secondaryColor = .clear
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
    
    func getCellFor(_ message: ChatMessage?, at indexPath: IndexPath?,isPlaying: Bool,audioClosureCallBack : @escaping AudioCallBack,isShowForwardView: Bool?) -> AudioSender? {
        audioCallBack = audioClosureCallBack
        currentIndexPath = nil
        currentIndexPath = indexPath
        self.message = message
        let duration = Int(message?.mediaChatMessage?.mediaDuration ?? 0)
        autioDuration?.text = "\(duration.msToSeconds.minuteSecondMS)"
        
        // Forward view elements and its data
        forwardView?.isHidden = (isShowForwardView == true && message?.mediaChatMessage?.mediaUploadStatus == .uploaded) ? false : true
        forwardView?.makeCircleView(borderColor: Color.forwardCircleBorderColor.cgColor, borderWidth: 1.5)
        forwardLeadingCons?.constant = (isShowForwardView == true && message?.mediaChatMessage?.mediaUploadStatus == .uploaded) ? 20 : 0
        forwardButton?.isHidden = (isShowForwardView == true && message?.mediaChatMessage?.mediaUploadStatus == .uploaded) ? false : true
        
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
            if  (message?.mediaChatMessage?.mediaDownloadStatus == .not_downloaded || message?.mediaChatMessage?.mediaDownloadStatus == .failed || message?.mediaChatMessage?.mediaDownloadStatus == .downloading || message?.messageStatus == .notAcknowledged || isShowForwardView == true) {
                fwdViw?.isHidden = true
                fwdBtn?.isHidden = true
                isAllowSwipe = false
            } else {
                fwdViw?.isHidden = false
                fwdBtn?.isHidden = false
                isAllowSwipe = true
            }
        } else {
            if  (message?.mediaChatMessage?.mediaUploadStatus == .not_uploaded || message?.mediaChatMessage?.mediaUploadStatus == .failed || message?.mediaChatMessage?.mediaUploadStatus == .uploading || message?.messageStatus == .notAcknowledged || isShowForwardView == true) {
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
           mediaLocationMap?.isHidden = true
           userTextLabel?.text = getReplymessage
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
               case .video:
                   messageTypeIcon?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "senderVideo" : "video")
                   messageTypeIconView?.isHidden = false
                   if let thumImage = message?.replyParentChatMessage?.mediaChatMessage?.mediaThumbImage {
                       let converter = ImageConverter()
                       let image =  converter.base64ToImage(thumImage)
                       mediaImageView?.image = image
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
                nicoProgressBar?.isHidden = true
            } else if message?.mediaChatMessage?.mediaUploadStatus == .failed {
                uploadCancel?.isHidden = false
                playIcon?.isHidden = true
                playButton?.isHidden = true
                uploadCancel?.image = (isShowAudioLoadingIcon == true && indexPath == IndexPath(row: 0, section: 0)) ? UIImage(named: ImageConstant.ic_audioUploadCancel) : UIImage(named: ImageConstant.ic_upload)
                updateCancelButton?.isHidden = (isShowAudioLoadingIcon == true && indexPath == IndexPath(row: 0, section: 0)) ? true : false
                audioPlaySlider?.isUserInteractionEnabled = false
                nicoProgressBar?.isHidden = true
            } else if message?.mediaChatMessage?.mediaUploadStatus == .uploading {
                uploadCancel?.image = UIImage(named: ImageConstant.ic_audioUploadCancel)
                nicoProgressBar?.isHidden = false
                uploadCancel?.isHidden = false
                playIcon?.isHidden = true
                playButton?.isHidden = true
                updateCancelButton?.isHidden = false
                audioPlaySlider?.isUserInteractionEnabled = false
                uploadingMediaObjects?.forEach({ chatMessage in
                    if chatMessage.messageId == message?.messageId {
                        nicoProgressBar?.transition(to: .indeterminate)
                        nicoProgressBar?.isHidden = false
                    } else {
                        nicoProgressBar?.isHidden = false
                    }
                })
            } else if message?.mediaChatMessage?.mediaUploadStatus == .uploaded {
                playIcon?.image = isPlaying ? UIImage(named: ImageConstant.ic_audio_pause) : UIImage(named: ImageConstant.ic_play)
                playIcon?.isHidden = false
                uploadCancel?.isHidden = true
                nicoProgressBar?.isHidden = true
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
                nicoProgressBar?.isHidden = false
            } else if message?.mediaChatMessage?.mediaDownloadStatus == .failed {
                uploadCancel?.isHidden = false
                playIcon?.isHidden = true
                playButton?.isHidden = true
                uploadCancel?.image = (isShowAudioLoadingIcon == true && indexPath == IndexPath(row: 0, section: 0)) ? UIImage(named: ImageConstant.ic_audioUploadCancel) : UIImage(named: "download")
                updateCancelButton?.isHidden = (isShowAudioLoadingIcon == true && indexPath == IndexPath(row: 0, section: 0)) ? true : false
                audioPlaySlider?.isUserInteractionEnabled = false
                nicoProgressBar?.isHidden = true
            } else if message?.mediaChatMessage?.mediaDownloadStatus == .downloading {
                uploadCancel?.image = UIImage(named: ImageConstant.ic_audioUploadCancel)
                nicoProgressBar?.isHidden = false
                uploadCancel?.isHidden = false
                playIcon?.isHidden = true
                playButton?.isHidden = true
                updateCancelButton?.isHidden = false
                audioPlaySlider?.isUserInteractionEnabled = false
                uploadingMediaObjects?.forEach({ chatMessage in
                    if chatMessage.messageId == message?.messageId {
                        nicoProgressBar?.transition(to: .indeterminate)
                        nicoProgressBar?.isHidden = false
                    } else {
                        nicoProgressBar?.isHidden = false
                    }
                })
            } else if message?.mediaChatMessage?.mediaDownloadStatus == .downloaded {
                playIcon?.image = isPlaying ? UIImage(named: ImageConstant.ic_audio_pause) : UIImage(named: ImageConstant.ic_play)
                playIcon?.isHidden = false
                uploadCancel?.isHidden = true
                nicoProgressBar?.isHidden = true
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
        self.sentTime?.text = Utility.convertTime(timeStamp: timeStamp)
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

    func startUpload() {
        uploadCancel?.isHidden = false
        playIcon?.isHidden = true
        playButton?.isHidden = true
        uploadCancel?.image = UIImage(named: ImageConstant.ic_audioUploadCancel)
        updateCancelButton?.isHidden = false
        audioPlaySlider?.isUserInteractionEnabled = false
        nicoProgressBar?.isHidden = false
    }
    
    func stopUpload() {
        uploadCancel?.isHidden = false
        playIcon?.isHidden = true
        playButton?.isHidden = true
        uploadCancel?.image = UIImage(named: ImageConstant.ic_upload)
        updateCancelButton?.isHidden = false
        audioPlaySlider?.isUserInteractionEnabled = false
        nicoProgressBar?.isHidden = true
    }
    
    func stopDownload() {
        uploadCancel?.isHidden = false
        playIcon?.isHidden = true
        playButton?.isHidden = true
        uploadCancel?.image = UIImage(named: "Download")
        updateCancelButton?.isHidden = false
        audioPlaySlider?.isUserInteractionEnabled = false
        nicoProgressBar?.isHidden = true
    }
}


