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
    // Starred Message Outlet
    @IBOutlet weak var favImageView: UIImageView?
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
    
    @IBOutlet weak var videoTimeStackView: UIStackView!
    @IBOutlet weak var captionHolder: UIView!
    var message : ChatMessage?
    var refreshDelegate: RefreshBubbleImageViewDelegate? = nil
    var selectedForwardMessage: [SelectedMessages]? = []
    var sendMediaMessages: [ChatMessage]? = []
    var imageGeasture: UITapGestureRecognizer!
    
    
    @IBOutlet weak var captionLabelTime: UILabel!
    @IBOutlet weak var captionStatus: UIImageView!
    
    var isFromBack: Bool = false
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
        
        imageGeasture = UITapGestureRecognizer()
        imageContainer?.addGestureRecognizer(imageGeasture)
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
    
    func getCellFor(_ message: ChatMessage?, at indexPath: IndexPath?,isShowForwardView: Bool?,isDeleteMessageSelected: Bool?) -> ChatViewVideoOutgoingCell? {
        currentIndexPath = nil
        currentIndexPath = indexPath
        
        // Starred Messages
        favImageView?.isHidden =  message!.isMessageStarred ? false : true
        
        showHideForwardView(message: message, isShowForwardView: isShowForwardView, isDeleteMessageSelected: isDeleteMessageSelected)

        if selectedForwardMessage?.filter({$0.chatMessage.messageId == message?.messageId}).first?.isSelected == true {
            forwardImageView?.image = UIImage(named: "forwardSelected")
            forwardImageView?.isHidden = false
            forwardView?.makeCircleView(borderColor: Color.forwardCircleBorderColor.cgColor, borderWidth: 0.0)
        } else {
          //  forwardImageView?.image = UIImage(named: "")
            forwardImageView?.isHidden = true
            forwardView?.makeCircleView(borderColor: Color.forwardCircleBorderColor.cgColor, borderWidth: 1.5)
        }
        
        if  (message?.mediaChatMessage?.mediaUploadStatus == .not_uploaded || message?.mediaChatMessage?.mediaUploadStatus == .failed || message?.mediaChatMessage?.mediaUploadStatus == .uploading || message?.messageStatus == .notAcknowledged || isShowForwardView == true) {
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
           
           //For hide view for text messages
           mediaMessageImageView?.isHidden = true
           mediaLocationMapView?.isHidden = true
           messageTypeIconView?.isHidden = true
           let getReplymessage =  message?.replyParentChatMessage?.messageTextContent
           let replyMessage = FlyMessenger.getMessageOfId(messageId: message?.replyParentChatMessage?.messageId ?? "")
           if replyMessage?.isMessageDeleted == true || replyMessage?.isMessageRecalled == true {
               replyTextLabel?.text = "Original message not available"
               mediaMessageImageView?.isHidden = true
               mediaLocationMapView?.isHidden = true
               messageTypeIconView?.isHidden = true
           } else {
               messageTypeIconView?.isHidden = true
               replyTextLabel?.text = getReplymessage
               if replyMessage?.mediaChatMessage != nil {
                   switch replyMessage?.mediaChatMessage?.messageType {
                   case .image:
                       messageTypeIcon?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "senderCamera" : "receiverCamera")
                       if let thumImage = replyMessage?.mediaChatMessage?.mediaThumbImage {
                           let converter = ImageConverter()
                           let image =  converter.base64ToImage(thumImage)
                           mediaMessageImageView?.image = image
                           replyTextLabel?.text = !(replyMessage?.mediaChatMessage?.mediaCaptionText.isEmpty ?? false) ? replyMessage?.mediaChatMessage?.mediaCaptionText : "Photo"
                       }
                       messageTypeIconView?.isHidden = false
                       mediaMessageImageView?.isHidden = false
                       mediaLocationMapView?.isHidden = true
                       replyWithoutMediaCons?.isActive = false
                       replyWithMediaCOns?.isActive = true
                   case .audio:
                       messageTypeIconView?.isHidden = false
                       ChatUtils.setIconForAudio(imageView: messageTypeIcon, chatMessage: message)
                       let duration = Int(replyMessage?.mediaChatMessage?.mediaDuration ?? 0)
                       replyTextLabel?.text = !(replyMessage?.mediaChatMessage?.mediaCaptionText.isEmpty ?? false) ? replyMessage?.mediaChatMessage?.mediaCaptionText : replyMessage?.mediaChatMessage?.messageType.rawValue.capitalized.appending(" (\(duration.msToSeconds.minuteSecondMS))")
                       replyWithoutMediaCons?.isActive = true
                       replyWithMediaCOns?.isActive = false
                       mediaMessageImageView?.isHidden = true
                       mediaLocationMapView?.isHidden = true
                   case .video:
                       messageTypeIconView?.isHidden = false
                       messageTypeIcon?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "senderVideo" : "video")
                       if let thumImage = replyMessage?.mediaChatMessage?.mediaThumbImage {
                           let converter = ImageConverter()
                           let image =  converter.base64ToImage(thumImage)
                           mediaMessageImageView?.image = image
                           mediaMessageImageView?.isHidden = false
                           mediaLocationMapView?.isHidden = true
                           replyTextLabel?.text = !(replyMessage?.mediaChatMessage?.mediaCaptionText.isEmpty ?? false) ? replyMessage?.mediaChatMessage?.mediaCaptionText : replyMessage?.mediaChatMessage?.messageType.rawValue.capitalized
                       }
                       replyWithoutMediaCons?.isActive = false
                       replyWithMediaCOns?.isActive = true
                   case .document:
                       messageTypeIconView?.isHidden = false
                       messageTypeIcon?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "document" : "document")
                       checkFileType(url: replyMessage?.mediaChatMessage?.mediaFileUrl ?? "", typeImageView: mediaMessageImageView)
                       replyTextLabel?.text = !(replyMessage?.mediaChatMessage?.mediaCaptionText.isEmpty ?? false) ? replyMessage?.mediaChatMessage?.mediaCaptionText : replyMessage?.mediaChatMessage?.messageType.rawValue.capitalized
                       replyWithoutMediaCons?.isActive = false
                       replyWithMediaCOns?.isActive = true
                       mediaMessageImageView?.isHidden = false
                       mediaLocationMapView?.isHidden = true
                   default:
                       messageTypeIconView?.isHidden = true
                       replyWithoutMediaCons?.isActive = true
                       replyWithMediaCOns?.isActive = false
                       mediaLocationMapView?.isHidden = true
                       mediaMessageImageView?.isHidden = true
                   }
                   
               } else if replyMessage?.locationChatMessage != nil {
                   replyTextLabel?.text = "Location"
                   mediaLocationMapView?.isUserInteractionEnabled = false
                   messageTypeIcon?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "map" : "receivedMap")
                   guard let latitude = replyMessage?.locationChatMessage?.latitude else {
                       return nil
                   }
                   guard let longitude = replyMessage?.locationChatMessage?.longitude  else {
                       return nil
                   }
                   mediaMessageImageView?.isHidden = true
                   mediaLocationMapView?.isHidden = false
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
                   mediaMessageImageView?.isHidden = true
                   mediaLocationMapView?.isHidden = true
               } else {
                   replyWithoutMediaCons?.isActive = true
                   replyWithMediaCOns?.isActive = false
               }
           }
        if(replyMessage!.isMessageSentByMe) {
            userTitleLabel?.text = you.localized
        }
        else {
            userTitleLabel?.text = getUserName(jid: replyMessage?.senderUserJid ?? "" ,name: replyMessage?.senderUserName ?? "",
                                               nickName: replyMessage?.senderNickName ?? "", contactType: (replyMessage?.isDeletedUser ?? false) ? .deleted : (replyMessage?.isSavedContact ?? false) ? .live : .unknown)
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
        
        if (message?.messageType == .image && message?.mediaChatMessage?.mediaUploadStatus == .uploaded) {
            if let localPath = message?.mediaChatMessage?.mediaFileName {
                let directoryURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let folderPath: URL = directoryURL.appendingPathComponent("FlyMedia/Image", isDirectory: true)
                let fileURL: URL = folderPath.appendingPathComponent(localPath)
                if FileManager.default.fileExists(atPath: fileURL.relativePath) {
                    let data = NSData(contentsOf: fileURL)
                    let image = UIImage(data: data! as Data)
                    imageContainer?.image = image
                }
            }
            else {
                if let thumImage = message?.mediaChatMessage?.mediaThumbImage {
                    ChatUtils.setThumbnail(imageContainer: imageContainer, base64String: thumImage)
                }
            }
        }
        else {
        if let thumImage = message?.mediaChatMessage?.mediaThumbImage {
            ChatUtils.setThumbnail(imageContainer: imageContainer, base64String: thumImage)
        }
        }
        
        if let isCarbon = message?.isCarbonMessage, isCarbon {
            mediaStatusForCorbon(message: message)
        } else {
            mediaStatus(message: message)
        }

        if message?.messageType == .image {
            playButton.isHidden = true
            videoTimeStackView.isHidden = true
        }
        else {
            videoTimeStackView.isHidden = false
        }
        
        messageStatus(message: message)
        
        // Message time
        guard let timeStamp =  message?.messageSentTime else {
            return self
        }
        let time = DateFormatterUtility.shared.convertMillisecondsToTime(milliSeconds: timeStamp).getTimeFormat()
        self.sentTime.text = time.uppercased()
        self.captionLabelTime.text = time.uppercased()
        return self
    }
    
    func showHideForwardView(message: ChatMessage?,isShowForwardView: Bool?,isDeleteMessageSelected: Bool?) {
        if isDeleteMessageSelected ?? false {
            // Forward view elements and its data
            forwardView?.isHidden = (isShowForwardView == false || message?.mediaChatMessage?.mediaUploadStatus == .uploading)  || (message?.isMessageRecalled == true) ? true : false
            forwardView?.makeCircleView(borderColor: Color.forwardCircleBorderColor.cgColor, borderWidth: 1.5)
            forwardLeadingCOns?.constant = (isShowForwardView == false ||  message?.mediaChatMessage?.mediaUploadStatus == .uploading)  || (message?.isMessageRecalled == true) ? 0 : 20
            forwardButton?.isHidden = (isShowForwardView == false ||  message?.mediaChatMessage?.mediaUploadStatus == .uploading)  || (message?.isMessageRecalled == true) ? true : false
        } else {
            // Forward view elements and its data
            forwardView?.isHidden = (isShowForwardView == true && message?.mediaChatMessage?.mediaUploadStatus == .uploaded) ? false : true
            forwardView?.makeCircleView(borderColor: Color.forwardCircleBorderColor.cgColor, borderWidth: 1.5)
            forwardLeadingCOns?.constant = (isShowForwardView == true && message?.mediaChatMessage?.mediaUploadStatus == .uploaded) ? 20 : 0
            forwardButton?.isHidden = (isShowForwardView == true && message?.mediaChatMessage?.mediaUploadStatus == .uploaded) ? false : true
        }
    }
    
    func mediaStatus(message: ChatMessage?) {
        downloadView?.isHidden = true
        downloadButton?.isHidden = true
        downloadLabel?.isHidden = true
        switch message?.mediaChatMessage?.mediaUploadStatus {
        case .not_uploaded:
            playButton.isHidden = true
            progressLoader?.isHidden = true
            progressView?.isHidden = true
            retryButton?.isHidden = false
            uploadView?.isHidden = false
        case .failed:
            playButton.isHidden = true
            progressLoader?.isHidden = true
            progressView?.isHidden = true
            retryButton?.isHidden = false
            uploadView?.isHidden = false
            
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
    
    func mediaStatusForCorbon(message: ChatMessage?) {
        
        retryButton?.isHidden = true
        uploadView?.isHidden = true
        
        switch message?.mediaChatMessage?.mediaDownloadStatus {
        case .not_downloaded:
            playButton.isHidden = true
            progressLoader?.isHidden = true
            progressView?.isHidden = true
            downloadButton?.isHidden = false
            downloadView?.isHidden = false
            downloadLabel?.isHidden = false
            if let fileSize = message?.mediaChatMessage?.mediaFileSize{
                downloadLabel?.text = "\(fileSize.byteSize)"
            }else {
                downloadLabel?.text = ""
            }
        case .failed:
            playButton.isHidden = true
            progressLoader?.isHidden = true
            progressView?.isHidden = true
            downloadButton?.isHidden = false
            downloadView?.isHidden = false
            downloadLabel?.isHidden = false
            if let fileSize = message?.mediaChatMessage?.mediaFileSize{
                downloadLabel?.text = "\(fileSize.byteSize)"
            }else {
                downloadLabel?.text = ""
            }
        case .downloading:
            let progrss = message?.mediaChatMessage?.mediaProgressStatus ?? 0
            print("Video Upload mediaStatus \(message?.mediaChatMessage?.mediaUploadStatus)")
            print("video Upload mediaStatus \(progrss)")
            progressLoader.isHidden = false
            progressView.isHidden = false
            uploadView.isHidden = true
            playButton.isHidden = true
            retryButton?.isHidden = true
            downloadButton?.isHidden = true
            downloadView?.isHidden = true
            downloadLabel?.isHidden = true
            if progrss == 100 || progrss == 0 {
                progressLoader.transition(to: .indeterminate)
            } else {
                progressLoader?.transition(to: .determinate(percentage: CGFloat(progrss/100)))
            }
        case .downloaded:
            progressLoader.transition(to: .indeterminate)
            progressView.isHidden = true
            uploadView.isHidden = true
            playButton.isHidden = false
            retryButton?.isHidden = true
            downloadButton?.isHidden = true
            downloadView?.isHidden = true
            downloadLabel?.isHidden = true
            if(message?.messageStatus == .sent) {
                playButton.isHidden = true
                downloadButton?.isHidden = false
                downloadView?.isHidden = false
                progressView.isHidden = true
            }
        default:
            progressView.isHidden = true
            playButton.isHidden = true
            downloadButton?.isHidden = false
            downloadView?.isHidden = false
            if let fileSize = message?.mediaChatMessage?.mediaFileSize{
                downloadLabel?.text = "\(fileSize.byteSize)"
            }else {
                downloadLabel?.text = ""
            }
        }
    }
    
    
    
    func messageStatus(message: ChatMessage?) {
        switch message?.messageStatus {
        case .notAcknowledged:
            self.msgStatus.image = UIImage.init(named: ImageConstant.ic_hour)
            self.msgStatus.accessibilityLabel = notAcknowledged.localized
            self.captionStatus.image = UIImage.init(named: ImageConstant.ic_hour)
            self.captionStatus.accessibilityLabel = notAcknowledged.localized
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

