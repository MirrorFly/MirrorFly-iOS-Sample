//
//  ChatViewVideoOutgoingCell.swift
//  MirrorflyUIkit
//
//  Created by User on 24/09/21.
//

import UIKit
import FlyCommon
import FlyCore
import AVKit
import MapKit
import GoogleMaps
import NicoProgress

class ChatViewVideoOutgoingCell: BaseTableViewCell {
    
    @IBOutlet weak var timeOverlay: UIImageView?
    @IBOutlet weak var uploadImage: UIImageView!
    @IBOutlet weak var uploadView: UIView!
    @IBOutlet weak var retryLabel: UILabel!
    @IBOutlet weak var cancelUploadButton: UIButton!
    @IBOutlet weak var videoTimeLabel: UILabel!
    @IBOutlet weak var downloadLabel: UILabel?
    @IBOutlet weak var downloadImage: UIImageView?
    @IBOutlet weak var downloadView: UIView?
    @IBOutlet weak var cellView: UIView!
    @IBOutlet weak var imageContainer: UIImageView!
    @IBOutlet weak var sentTime: UILabel!
    @IBOutlet weak var msgStatus: UIImageView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var progressLoader: NicoProgressBar!
    @IBOutlet weak var progressView: UIView!
    @IBOutlet weak var captionLabel: UILabel!
    @IBOutlet weak var downloadButton: UIButton?
    
    // Reply Message Outlet
    @IBOutlet weak var mediaMessageImageView: UIImageView?
    @IBOutlet weak var replyTextLabel: UILabel?
    @IBOutlet weak var messageTypeIcon: UIImageView?
    @IBOutlet weak var messageTypeIconView: UIView?
    @IBOutlet weak var userTitleLabel: UILabel?
    @IBOutlet weak var bubbleImageView: UIImageView?
    @IBOutlet weak var retryButton: UIButton?
    @IBOutlet weak var replyView: UIView?
    @IBOutlet weak var mediaLocationMapView: GMSMapView?
    @IBOutlet weak var replyWithoutMediaCons: NSLayoutConstraint?
    @IBOutlet weak var replyWithMediaCOns: NSLayoutConstraint?
    // Forward Outlet
    @IBOutlet weak var forwardImageView: UIImageView?
    @IBOutlet weak var forwardView: UIView?
    @IBOutlet weak var forwardLeadingCOns: NSLayoutConstraint?
    @IBOutlet weak var quickfwdView: UIView?
    @IBOutlet weak var forwardButton: UIButton?
    @IBOutlet weak var quickFwdBtn: UIButton?
    
    @IBOutlet weak var captionHolder: UIView!
    var message : ChatMessage?
    var refreshDelegate: RefreshBubbleImageViewDelegate? = nil
    var selectedForwardMessage: [SelectedForwardMessage]? = []
    var sendMediaMessages: [ChatMessage]? = []
    
    @IBOutlet weak var captionLabelTime: UILabel!
    @IBOutlet weak var captionStatus: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        setupUI()
    }
    func setupUI() {
        retryLabel.text = retry
        uploadView.isHidden = true
        captionLabel.font = UIFont.font12px_appRegular()
        progressView.layer.cornerRadius = 4
        uploadView.layer.cornerRadius = 4
        cellView.roundCorners(corners: [.topLeft, .topRight], radius: 5.0)
        imageContainer.layer.cornerRadius = 5.0
        imageContainer.clipsToBounds = true
        ChatUtils.setSenderBubbleBackground(imageView: bubbleImageView)
        replyView?.roundCorners(corners: [.topLeft,.topRight], radius: 10)
        progressLoader?.primaryColor = .white
        progressLoader?.secondaryColor = .clear
        progressLoader?.determinateAnimationDuration = 0
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    func setSelectView(selected: Bool) {
         if selected {
         self.backgroundColor = .lightGray
         }else {
             self.backgroundColor = .clear
         }
    }
    
    func getCellFor(_ message: ChatMessage?, at indexPath: IndexPath?,isShowForwardView: Bool?) -> ChatViewVideoOutgoingCell? {
        currentIndexPath = nil
        currentIndexPath = indexPath
        
        // Forward view elements and its data
        forwardView?.isHidden = (isShowForwardView == true && message?.mediaChatMessage?.mediaUploadStatus == .uploaded) ? false : true
        forwardView?.makeCircleView(borderColor: Color.forwardCircleBorderColor.cgColor, borderWidth: 1.5)
        forwardLeadingCOns?.constant = (isShowForwardView == true && message?.mediaChatMessage?.mediaUploadStatus == .uploaded) ? 20 : 0
        forwardButton?.isHidden = (isShowForwardView == true && message?.mediaChatMessage?.mediaUploadStatus == .uploaded) ? false : true
    
        if selectedForwardMessage?.filter({$0.chatMessage.messageId == message?.messageId}).first?.isSelected == true {
            forwardImageView?.image = UIImage(named: "forwardSelected")
            forwardImageView?.isHidden = false
            forwardView?.makeCircleView(borderColor: Color.forwardCircleBorderColor.cgColor, borderWidth: 0.0)
        } else {
            forwardImageView?.image = UIImage(named: "")
            forwardImageView?.isHidden = true
            forwardView?.makeCircleView(borderColor: Color.forwardCircleBorderColor.cgColor, borderWidth: 1.5)
        }
        
        if  (message?.mediaChatMessage?.mediaUploadStatus == .not_uploaded || message?.mediaChatMessage?.mediaUploadStatus == .uploading || message?.messageStatus == .notAcknowledged || isShowForwardView == true) {
            quickfwdView?.isHidden = true
            quickFwdBtn?.isHidden = true
            isAllowSwipe = false
        } else {
            quickfwdView?.isHidden = false
            quickFwdBtn?.isHidden = false
            isAllowSwipe = true
        }
        
        // Reply view elements and its data
       if(message!.isReplyMessage) {
            replyView?.isHidden = false
           let getReplymessage =  message?.replyParentChatMessage?.messageTextContent
           let replyMessage = FlyMessenger.getMessageOfId(messageId: message?.replyParentChatMessage?.messageId ?? "")
           messageTypeIconView?.isHidden = true
           replyTextLabel?.text = getReplymessage
           mediaLocationMapView?.isHidden = true
           if replyMessage?.mediaChatMessage != nil {
               messageTypeIcon?.isHidden = false
              
               switch replyMessage?.mediaChatMessage?.messageType {
               case .image:
                   messageTypeIcon?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "senderCamera" : "receiverCamera")
                   if let thumImage = replyMessage?.mediaChatMessage?.mediaThumbImage {
                       let converter = ImageConverter()
                       let image =  converter.base64ToImage(thumImage)
                       mediaMessageImageView?.image = image
                       replyTextLabel?.text = !(replyMessage?.mediaChatMessage?.mediaCaptionText.isEmpty ?? false) ? replyMessage?.mediaChatMessage?.mediaCaptionText : "Photo"
                   }
                   replyWithoutMediaCons?.isActive = false
                   replyWithMediaCOns?.isActive = true
               case .audio:
                   messageTypeIcon?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "senderAudio" : "receiverAudio")
                   let duration = Int(replyMessage?.mediaChatMessage?.mediaDuration ?? 0)
                   replyTextLabel?.text = !(replyMessage?.mediaChatMessage?.mediaCaptionText.isEmpty ?? false) ? replyMessage?.mediaChatMessage?.mediaCaptionText : replyMessage?.mediaChatMessage?.messageType.rawValue.capitalized.appending(" (\(duration.msToSeconds.minuteSecondMS))")
                   replyWithoutMediaCons?.isActive = true
                   replyWithMediaCOns?.isActive = false
               case .video:
                   messageTypeIcon?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "senderVideo" : "video")
                   if let thumImage = replyMessage?.mediaChatMessage?.mediaThumbImage {
                       let converter = ImageConverter()
                       let image =  converter.base64ToImage(thumImage)
                       mediaMessageImageView?.image = image
                       replyTextLabel?.text = !(replyMessage?.mediaChatMessage?.mediaCaptionText.isEmpty ?? false) ? replyMessage?.mediaChatMessage?.mediaCaptionText : replyMessage?.mediaChatMessage?.messageType.rawValue.capitalized
                   }
                   replyWithoutMediaCons?.isActive = false
                   replyWithMediaCOns?.isActive = true
               default:
                   messageTypeIconView?.isHidden = true
                   replyWithoutMediaCons?.isActive = true
                   replyWithMediaCOns?.isActive = false
               }
               
           } else if replyMessage?.locationChatMessage != nil {
               mediaLocationMapView?.isHidden = false
               replyTextLabel?.text = "Location"
               mediaLocationMapView?.isUserInteractionEnabled = false
               messageTypeIcon?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "map" : "receivedMap")
               guard let latitude = replyMessage?.locationChatMessage?.latitude else {
                   return nil
               }
               guard let longitude = replyMessage?.locationChatMessage?.longitude  else {
                   return nil
               }
               
               mediaLocationMapView?.camera = GMSCameraPosition.camera(withLatitude: latitude, longitude: longitude, zoom: 16.0, bearing: 360.0, viewingAngle: 15.0)
      
               DispatchQueue.main.async
               { [self] in
                   // 2. Perform UI Operations.
                   let position = CLLocationCoordinate2DMake(latitude,longitude)
                   let marker = GMSMarker(position: position)
                   marker.map = mediaLocationMapView
               }
               messageTypeIconView?.isHidden = false
               replyWithoutMediaCons?.isActive = false
               replyWithMediaCOns?.isActive = true
           } else if replyMessage?.contactChatMessage != nil {
               let replyTextMessage = "Contact: \(replyMessage?.contactChatMessage?.contactName ?? "")"
                   replyTextLabel?.attributedText = ChatUtils.setAttributeString(name: replyMessage?.contactChatMessage?.contactName)
               messageTypeIcon?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "senderContact" : "receiverContact")
               messageTypeIconView?.isHidden = false
               replyWithoutMediaCons?.isActive = true
               replyWithMediaCOns?.isActive = false
           } else {
               replyWithoutMediaCons?.isActive = true
               replyWithMediaCOns?.isActive = false
           }
        if(replyMessage!.isMessageSentByMe) {
            userTitleLabel?.text = you.localized
        }
        else {
            userTitleLabel?.text = replyMessage?.senderUserName
        }
    }
        else {
            replyView?.isHidden = true
        }
        
        
        self.message = message

        if let captionTxt = message?.mediaChatMessage?.mediaCaptionText, captionTxt == "" {
            captionHolder.isHidden = true
            cellView.roundCorners(corners: [.topLeft, .bottomLeft, .topRight], radius: 5.0)
            captionHolder.roundCorners(corners: [.bottomLeft], radius: 5.0)
            sentTime.isHidden = false
            timeOverlay?.isHidden = false
            msgStatus.isHidden = false
        }else {
            let captionTxt = message?.mediaChatMessage?.mediaCaptionText ?? ""
            captionHolder.isHidden = false
            captionLabel.text = captionTxt
            captionHolder.roundCorners(corners: [.bottomLeft], radius: 5.0)
            cellView.roundCorners(corners: [.topLeft, .topRight], radius: 5.0)
            sentTime.isHidden = true
            timeOverlay?.isHidden = true
            msgStatus.isHidden = true

        }
        
        if let duration = message?.mediaChatMessage?.mediaDuration {
            videoTimeLabel.text = Int(duration).msToSeconds.minuteSecondMS
        } else {
            videoTimeLabel.text = ""
        }
        
        if let thumImage = message?.mediaChatMessage?.mediaThumbImage {
            ChatUtils.setThumbnail(imageContainer: imageContainer, base64String: thumImage)
        }
        
        mediaStatus(message: message)
        
        messageStatus(message: message)
        
        // Message time
        guard let timeStamp =  message?.messageSentTime else {
            return self
        }
        let time = DateFormatterUtility.shared.convertMillisecondsToTime(milliSeconds: timeStamp).getTimeFormat()
        self.sentTime.text = time
        self.captionLabelTime.text = time
        return self
    }
    
    func mediaStatus(message: ChatMessage?) {
        switch message?.mediaChatMessage?.mediaUploadStatus {
        case .not_uploaded:
            playButton.isHidden = true
            progressLoader?.isHidden = true
            retryButton?.isHidden = false
            uploadView?.isHidden = false
            progressView?.isHidden = true
        case .uploading:
            let progrss = message?.mediaChatMessage?.mediaProgressStatus ?? 0
            print("Video Upload mediaStatus \(message?.mediaChatMessage?.mediaUploadStatus)")
            print("video Upload mediaStatus \(progrss)")
            progressLoader.isHidden = false
            progressView.isHidden = false
            uploadView.isHidden = true
            playButton.isHidden = true
            retryButton?.isHidden = true
            if progrss == 100 || progrss == 0 {
                progressLoader.transition(to: .indeterminate)
            } else {
                progressLoader?.transition(to: .determinate(percentage: CGFloat(progrss/100)))
            }
        case .uploaded:
            progressLoader.transition(to: .indeterminate)
            progressView.isHidden = true
            uploadView.isHidden = true
            playButton.isHidden = false
            retryButton?.isHidden = true
            if(message?.messageStatus == .sent) {
                playButton.isHidden = true
                uploadView.isHidden = false
                retryButton?.isHidden = false
                progressView.isHidden = true
            }
        default:
            progressView.isHidden = true
            uploadView.isHidden = false
            playButton.isHidden = true
            retryButton?.isHidden = false
        }
    }
    
    func messageStatus(message: ChatMessage?) {
        switch message?.messageStatus {
        case .notAcknowledged:
        self.msgStatus.image = UIImage.init(named: ImageConstant.ic_hour)
        self.msgStatus.accessibilityLabel = notAcknowledged.localized
        break
        case .sent:
            self.msgStatus.image = UIImage.init(named: ImageConstant.ic_hour)
            self.msgStatus.accessibilityLabel = sent.localized
            self.captionStatus.image = UIImage.init(named: ImageConstant.ic_hour)
            self.captionStatus.accessibilityLabel = sent.localized
            break
        case .acknowledged:
            self.msgStatus.image = UIImage.init(named: ImageConstant.ic_sent)
            self.msgStatus.accessibilityLabel = acknowledged.localized
            self.captionStatus.image = UIImage.init(named: ImageConstant.ic_sent)
            self.captionStatus.accessibilityLabel = acknowledged.localized
            break
        case .delivered:
            self.msgStatus.image = UIImage.init(named: ImageConstant.ic_delivered)
            self.msgStatus.accessibilityLabel = delivered.localized
            self.captionStatus.image = UIImage.init(named: ImageConstant.ic_delivered)
            self.captionStatus.accessibilityLabel = delivered.localized
            break
        case .seen:
            self.msgStatus.image = UIImage.init(named: ImageConstant.ic_seen)
            self.msgStatus.accessibilityLabel = seen.localized
            self.captionStatus.image = UIImage.init(named: ImageConstant.ic_seen)
            self.captionStatus.accessibilityLabel = seen.localized
            break
        case .received:
            self.msgStatus.image = UIImage.init(named: ImageConstant.ic_delivered)
            self.msgStatus.accessibilityLabel = delivered.localized
            self.captionStatus.image = UIImage.init(named: ImageConstant.ic_delivered)
            self.captionStatus.accessibilityLabel = delivered.localized
            break
        default:
            self.msgStatus.image = UIImage.init(named: ImageConstant.ic_hour)
            self.msgStatus.accessibilityLabel = notAcknowledged.localized
            self.captionStatus.image = UIImage.init(named: ImageConstant.ic_hour)
            self.captionStatus.accessibilityLabel = notAcknowledged.localized
            break
        }
    }
    
    // Get Thumbnail Image from URL
    fileprivate func getThumbnailFromUrl(_ url: String?, _ completion: @escaping ((_ image: UIImage?)->Void)) {

        guard let url = URL(string: url ?? "") else { return }
        DispatchQueue.main.async {
            let asset = AVAsset(url: url)
            let assetImgGenerate = AVAssetImageGenerator(asset: asset)
            assetImgGenerate.appliesPreferredTrackTransform = true

            let time = CMTimeMake(value: 2, timescale: 1)
            do {
                let img = try assetImgGenerate.copyCGImage(at: time, actualTime: nil)
                let thumbnail = UIImage(cgImage: img)
                completion(thumbnail)
            } catch {
                print("Error :: ", error.localizedDescription)
                completion(nil)
            }
        }
    }
}

