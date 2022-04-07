//
//  AudioReceiver.swift
//  MirrorflyUIkit
//
//  Created by User on 31/08/21.

import UIKit
import FlyCommon
import FlyCore
import AVFoundation
import NicoProgress
import GoogleMaps
import MapKit

class AudioReceiver: BaseTableViewCell, AVAudioPlayerDelegate {
    @IBOutlet weak var timeView: UIView?
    @IBOutlet weak var audioView: UIView?
    @IBOutlet weak var fwdViw: UIView?
    @IBOutlet weak var fwdIcon: UIImageView?
    @IBOutlet weak var fwdBtn: UIButton?
    @IBOutlet weak var slider: UISlider?
    @IBOutlet weak var audioDuration: UILabel?
    @IBOutlet weak var playBtn: UIButton?
    @IBOutlet weak var recvTime: UILabel?
    @IBOutlet weak var playView: UIView?
    @IBOutlet weak var nicoProgressBar: NicoProgressBar?
    @IBOutlet weak var audioReceiverImage: UIImageView?
    @IBOutlet weak var playImage: UIImageView?
    @IBOutlet weak var download: UIImageView?
    @IBOutlet weak var downloadButton: UIButton?
    
    // Reply Outlet
    @IBOutlet weak var mapView: GMSMapView?
    @IBOutlet weak var mediaMessageImageView: UIImageView?
    @IBOutlet weak var messageTypeIconView: UIView?
    @IBOutlet weak var messageTypeIcon: UIImageView?
    @IBOutlet weak var replyUserLabel: UILabel?
    @IBOutlet weak var replyView: UIView?
    @IBOutlet weak var bubbleImageView: UIImageView?
    @IBOutlet weak var replyTextLabel: UILabel?
    
    // Forward Outlet
    @IBOutlet weak var forwardImageView: UIImageView?
    @IBOutlet weak var forwardView: UIView?
    @IBOutlet weak var forwardLeadingCons: NSLayoutConstraint?
    @IBOutlet weak var bubbleLeadingCons: NSLayoutConstraint?
    @IBOutlet weak var forwardButton: UIButton?

    var selectedForwardMessage: [SelectedForwardMessage]? = []
    var message : ChatMessage?
    var refreshDelegate: RefreshBubbleImageViewDelegate?
    var audioPlayer:AVAudioPlayer?
    var updater : CADisplayLink! = nil
    typealias AudioCallBack = (_ sliderValue : Float) -> Void
        var audioCallBack: AudioCallBack? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        setupUI()
    }

    
    func setupUI() {
        recvTime?.font = UIFont.font9px_appLight()
        audioDuration?.font = UIFont.font8px_appLight()
        contentView.clipsToBounds = true
        audioView?.clipsToBounds = true
        timeView?.clipsToBounds = true
        audioView?.roundCorners(corners: [.topLeft, .topRight], radius: 8.0)
        timeView?.roundCorners(corners: [.topLeft, .topRight, .bottomRight], radius: 8.0)
        slider?.setThumbImage( UIImage(named: ImageConstant.ic_slider), for: UIControl.State.normal)
        slider?.minimumValue = 0
        slider?.maximumValue = 100
        audioReceiverImage?.image = UIImage(named: ImageConstant.ic_music)
        nicoProgressBar?.primaryColor = .gray
        nicoProgressBar?.secondaryColor = .clear
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @objc func trackAudio() {
        if let curnTime = audioPlayer?.currentTime {
            if let duration = audioPlayer?.duration {
      let normalizedTime = Float(curnTime * 100.0 / duration)
                slider?.value = normalizedTime
                print(normalizedTime)
                print(curnTime)
                print(duration)
                    let min = Int(curnTime / 60)
                    let sec = Int(curnTime.truncatingRemainder(dividingBy: 60))
                    let totalTimeString = String(format: "%02d:%02d", min, sec)
                audioDuration?.text = totalTimeString
                   print(totalTimeString)
            }
        }
    }
    
    @IBAction func fwdAction(_ sender: Any) {
        
    }
    
    func getCellFor(_ message: ChatMessage?, at indexPath: IndexPath?,isPlaying: Bool,audioClosureCallBack : @escaping AudioCallBack,isShowForwardView: Bool?) -> AudioReceiver? {
        currentIndexPath = nil
        currentIndexPath = indexPath
        audioCallBack = audioClosureCallBack
        
        // Forward view elements and its data
        forwardView?.isHidden = (isShowForwardView == true && message?.mediaChatMessage?.mediaDownloadStatus == .downloaded) ? false : true
        forwardView?.makeCircleView(borderColor: Color.forwardCircleBorderColor.cgColor, borderWidth: 1.5)
        forwardLeadingCons?.constant = (isShowForwardView == true && message?.mediaChatMessage?.mediaDownloadStatus == .downloaded) ? 20 : 0
        bubbleLeadingCons?.constant = (isShowForwardView == true && message?.mediaChatMessage?.mediaDownloadStatus == .downloaded) ? 10 : 0
        forwardButton?.isHidden = (isShowForwardView == true && message?.mediaChatMessage?.mediaDownloadStatus == .downloaded) ? false : true
        
        if selectedForwardMessage?.filter({$0.chatMessage.messageId == message?.messageId}).first?.isSelected == true {
            forwardImageView?.image = UIImage(named: "forwardSelected")
            forwardImageView?.isHidden = false
            forwardView?.makeCircleView(borderColor: Color.forwardCircleBorderColor.cgColor, borderWidth: 0.0)
        } else {
            forwardImageView?.image = UIImage(named: "")
            forwardImageView?.isHidden = true
            forwardView?.makeCircleView(borderColor: Color.forwardCircleBorderColor.cgColor, borderWidth: 1.5)
        }
        
    if  (message?.mediaChatMessage?.mediaDownloadStatus == .not_downloaded || message?.mediaChatMessage?.mediaDownloadStatus == .downloading || message?.messageStatus == .notAcknowledged || isShowForwardView == true) {
            fwdViw?.isHidden = true
            fwdBtn?.isHidden = true
        } else {
            fwdViw?.isHidden = false
            fwdBtn?.isHidden = false
        }
        
        // Reply view elements and its data
       if(message?.isReplyMessage ?? false) {
           replyView?.isHidden = false
            let getReplymessage =  message?.replyParentChatMessage?.messageTextContent
           mapView?.isHidden = true
           replyTextLabel?.text = getReplymessage
           if message?.replyParentChatMessage?.mediaChatMessage != nil {
               switch message?.replyParentChatMessage?.mediaChatMessage?.messageType {
               case .image:
                   messageTypeIcon?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "senderCamera" : "receiverCamera")
                   if let thumImage = message?.replyParentChatMessage?.mediaChatMessage?.mediaThumbImage {
                       let converter = ImageConverter()
                       let image =  converter.base64ToImage(thumImage)
                       mediaMessageImageView?.image = image
                       messageTypeIconView?.isHidden = false
                       replyTextLabel?.text = (!(message?.replyParentChatMessage?.mediaChatMessage?.mediaCaptionText.isEmpty ?? false)) ? message?.replyParentChatMessage?.mediaChatMessage?.mediaCaptionText : "Photo"
                   }
               case .audio:
                   messageTypeIcon?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "senderAudio" : "receiverAudio")
                   let duration = Int(message?.replyParentChatMessage?.mediaChatMessage?.mediaDuration ?? 0)
                   replyTextLabel?.text = (!(message?.replyParentChatMessage?.mediaChatMessage?.mediaCaptionText.isEmpty ?? false)) ? message?.replyParentChatMessage?.mediaChatMessage?.mediaCaptionText : message?.replyParentChatMessage?.mediaChatMessage?.messageType.rawValue.capitalized.appending(" (\(duration.msToSeconds.minuteSecondMS))")
                   messageTypeIconView?.isHidden = false
               case .video:
                   messageTypeIcon?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "senderVideo" : "video")
                   messageTypeIconView?.isHidden = false
                   if let thumImage = message?.replyParentChatMessage?.mediaChatMessage?.mediaThumbImage {
                       let converter = ImageConverter()
                       let image =  converter.base64ToImage(thumImage)
                       mediaMessageImageView?.image = image
                       replyTextLabel?.text = (!(message?.replyParentChatMessage?.mediaChatMessage?.mediaCaptionText.isEmpty ?? false)) ? message?.replyParentChatMessage?.mediaChatMessage?.mediaCaptionText : message?.replyParentChatMessage?.mediaChatMessage?.messageType.rawValue.capitalized
                   }
               default:
                   messageTypeIconView?.isHidden = true
               }
               
           } else if message?.replyParentChatMessage?.locationChatMessage != nil {
               mapView?.isHidden = false
               replyTextLabel?.text = "Location"
               messageTypeIcon?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "map" : "receivedMap")
               messageTypeIconView?.isHidden = false
               guard let latitude = message?.replyParentChatMessage?.locationChatMessage?.latitude else {
                   return nil
               }
               guard let longitude = message?.replyParentChatMessage?.locationChatMessage?.longitude  else {
                   return nil
               }
               
               mapView?.camera = GMSCameraPosition.camera(withLatitude: latitude, longitude: longitude, zoom: 16.0, bearing: 360.0, viewingAngle: 15.0)
      
               DispatchQueue.main.async
               { [self] in
                   // 2. Perform UI Operations.
                   var position = CLLocationCoordinate2DMake(latitude,longitude)
                   var marker = GMSMarker(position: position)
                   marker.map = mapView
               }
           } else if message?.replyParentChatMessage?.contactChatMessage != nil {
               replyTextLabel?.text = "Contact"
               messageTypeIcon?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "senderContact" : "receiverContact")
               messageTypeIconView?.isHidden = false
           } else {
               messageTypeIconView?.isHidden = true
           }
        if(message?.replyParentChatMessage?.isMessageSentByMe ?? false) {
            replyUserLabel?.text = you.localized
        }
        else {
            replyUserLabel?.text = message!.replyParentChatMessage?.senderUserName
        }
    }
        else {
            replyView?.isHidden = true
        }
        
        ChatUtils.setReceiverBubbleBackground(imageView: bubbleImageView)
        
        self.message = message
        self.currentIndexPath = indexPath
        let duration = Int(message?.mediaChatMessage?.mediaDuration ?? 0)
        DispatchQueue.main.async { [weak self] in
            self?.audioDuration?.text = "\(duration.msToSeconds.minuteSecondMS)"
        }
        switch message?.mediaChatMessage?.mediaDownloadStatus {
        case .not_downloaded:
            download?.image = UIImage(named: ImageConstant.ic_download)
            download?.isHidden = false
            playImage?.isHidden = true
            nicoProgressBar?.isHidden = true
            playBtn?.isHidden = true
            downloadButton?.isHidden = false
            slider?.isUserInteractionEnabled = false
        case .downloading:
            download?.image = UIImage(named: ImageConstant.ic_download_cancel)
            playBtn?.isHidden = false
            downloadButton?.isHidden = true
            download?.isHidden = false
            playImage?.isHidden = true
            nicoProgressBar?.isHidden = false
            slider?.isUserInteractionEnabled = false
        case .downloaded:
            playImage?.image = isPlaying ? UIImage(named: ImageConstant.ic_audio_pause_gray) : UIImage(named: ImageConstant.ic_play_dark)
            download?.image = UIImage(named: ImageConstant.ic_download_cancel)
            download?.isHidden = true
            playBtn?.isHidden = false
            downloadButton?.isHidden = true
            playImage?.isHidden = false
            nicoProgressBar?.isHidden = true
            slider?.isUserInteractionEnabled = true
        default:
            download?.image = UIImage(named: ImageConstant.ic_download)
            download?.isHidden = false
            playImage?.isHidden = true
            playBtn?.isHidden = true
            downloadButton?.isHidden = false
            nicoProgressBar?.isHidden = true
            slider?.isUserInteractionEnabled = false
        }
        guard let timeStamp =  message?.messageSentTime else {
            return self
        }
        self.recvTime?.text = Utility.convertTime(timeStamp: timeStamp)

        return self
    }
    
    func stopDisplayLink() {
        updater?.invalidate()
        updater = nil
     }
    
    @IBAction func sliderButtonAction(_ sender: Any) {
        print("sliderValueChanged \(slider?.value ?? 0)")
                if audioCallBack != nil {
                    audioCallBack!(slider?.value ?? 0)
                }
    }
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
           playImage?.image = UIImage(named: ImageConstant.ic_play_dark)
        player.stop()
        stopDisplayLink()
}
}
