//
//  ChatViewVideoIncomingCell.swift
//  MirrorflyUIkit
//
//  Created by User on 24/09/21.
//

import UIKit
import FlyCommon
import FlyCore
import MapKit
import GoogleMaps
import NicoProgress

class ChatViewVideoIncomingCell: BaseTableViewCell {
   
    @IBOutlet weak var bubbleImageTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var videoTimeLabel: UILabel!
    @IBOutlet weak var baseView: UIView!
    @IBOutlet weak var imageContainer: UIImageView!
    @IBOutlet weak var reecivedTime: UILabel!
    @IBOutlet weak var progressView: UIView!
    @IBOutlet weak var timeOverlay: UIImageView!
    @IBOutlet weak var closeImageView: UIImageView!
    @IBOutlet weak var progressLoader: NicoProgressBar?
    @IBOutlet weak var progressButton: UIButton!
    @IBOutlet weak var downloadView: UIView!
    @IBOutlet weak var downloadImageView: UIImageView!
    @IBOutlet weak var fileSizeLabel: UILabel!
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var caption: UILabel!
    @IBOutlet weak var captionViewHolder: UIStackView?
    
    @IBOutlet weak var captionTime: UILabel?
    @IBOutlet weak var forwardButton: UIButton?
    @IBOutlet weak var forwardView: UIView?
    @IBOutlet weak var videoTimingContainer: UIStackView!
    @IBOutlet weak var senderNameView: UIView!
    @IBOutlet weak var senderGroupNameLabel: GroupReceivedMessageHeader!
    @IBOutlet weak var playButton: UIButton!
    
    // Reply Outlet
    @IBOutlet weak var mapView: GMSMapView?
    @IBOutlet weak var mediaImageView: UIImageView?
    @IBOutlet weak var replyTextLabel: UILabel?
    @IBOutlet weak var messageIconView: UIView?
    @IBOutlet weak var messageTypeIcon: UIImageView?
    @IBOutlet weak var replyUserLabel: UILabel?
    @IBOutlet weak var replyView: UIView?
    @IBOutlet weak var bubbleImageView: UIImageView?
    
    @IBOutlet weak var replyWithMediaCons: NSLayoutConstraint?

    @IBOutlet weak var replyWithoutMediaCOns: NSLayoutConstraint?
    
    // Forward Outlet
    @IBOutlet weak var forwardImageView: UIImageView?
    @IBOutlet weak var quickForwardView: UIView?
    @IBOutlet weak var forwardLeadingCons: NSLayoutConstraint?
    @IBOutlet weak var bubbleLeadingCons: NSLayoutConstraint?
    @IBOutlet weak var quickForwardButton: UIButton?
    
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var emptyViewHeight: NSLayoutConstraint!

    @IBOutlet weak var captionView: UIView!
    
    //Translated Outlet
    @IBOutlet weak var translatedCaptionLabel: UILabel!
    var imageGeasture: UITapGestureRecognizer!

    
    var videoGesture: UITapGestureRecognizer!
    var message : ChatMessage?
    var selectedForwardMessage: [SelectedForwardMessage]? = []
    var refreshDelegate: RefreshBubbleImageViewDelegate? = nil
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        setupUI()
    }
    
    func setupUI() {
        videoGesture = UITapGestureRecognizer()
        imageContainer.addGestureRecognizer(videoGesture)
        progressLoader?.primaryColor = .white
        progressLoader?.secondaryColor = .clear
        progressLoader?.determinateAnimationDuration = 0
        caption.font = UIFont.font12px_appRegular()
        fileSizeLabel.font = UIFont.font12px_appSemibold()
        progressView.layer.cornerRadius = 4
        downloadView.layer.cornerRadius = 4
        baseView.roundCorners(corners: [.topLeft, .bottomLeft, .topRight], radius: 5.0)
        imageContainer.layer.cornerRadius = 5.0
        imageContainer.clipsToBounds = true
        emptyView.layer.cornerRadius = 5.0
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
    
    @IBAction func canceldownload(_ sender: Any) {
        downloadView.isHidden = false
    }
    
    func getCellFor(_ message: ChatMessage?, at indexPath: IndexPath?,isShowForwardView: Bool?) -> ChatViewVideoIncomingCell? {
        currentIndexPath = nil
        currentIndexPath = indexPath
        replyTextLabel?.text = ""
        replyUserLabel?.text = ""
        translatedCaptionLabel?.text = ""
        captionViewHolder?.spacing = FlyDefaults.isTranlationEnabled && message?.isMessageTranslated ?? false ? 10 : 0
        
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
            //forwardImageView?.image = UIImage(named: "")
            forwardImageView?.isHidden = true
            forwardView?.makeCircleView(borderColor: Color.forwardCircleBorderColor.cgColor, borderWidth: 1.5)
        }
        
        if  (message?.mediaChatMessage?.mediaDownloadStatus == .not_downloaded || message?.mediaChatMessage?.mediaDownloadStatus == .failed ||  message?.mediaChatMessage?.mediaDownloadStatus == .downloading || message?.messageStatus == .notAcknowledged || isShowForwardView == true) {
            quickForwardView?.isHidden = true
            quickForwardButton?.isHidden = true
            isAllowSwipe = true
        } else {
            quickForwardView?.isHidden = false
            quickForwardButton?.isHidden = false
            isAllowSwipe = true
        }
        
        // Reply view elements and its data
       if(message!.isReplyMessage) {
            replyView?.isHidden = false
          let getReplymessage =  message?.replyParentChatMessage?.messageTextContent
           let replyMessage = FlyMessenger.getMessageOfId(messageId: message?.replyParentChatMessage?.messageId ?? "")
           messageIconView?.isHidden = true
           replyTextLabel?.text = getReplymessage
           mapView?.isHidden = true
           if replyMessage?.mediaChatMessage != nil {
               messageTypeIcon?.isHidden = false
              
               switch replyMessage?.mediaChatMessage?.messageType {
               case .image:
                   messageTypeIcon?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "senderCamera" : "receiverCamera")
                   if let thumImage = replyMessage?.mediaChatMessage?.mediaThumbImage {
                       let converter = ImageConverter()
                       let image =  converter.base64ToImage(thumImage)
                       mediaImageView?.image = image
                       mediaImageView?.isHidden = false
                       replyTextLabel?.text = (!(replyMessage?.mediaChatMessage?.mediaCaptionText.isEmpty ?? false)) ? replyMessage?.mediaChatMessage?.mediaCaptionText : "Photo"
                   }
                   replyWithoutMediaCOns?.isActive = false
                   replyWithMediaCons?.isActive = true
               case .audio:
                   ChatUtils.setIconForAudio(imageView: messageTypeIcon, chatMessage: message)
                   let duration = Int(replyMessage?.mediaChatMessage?.mediaDuration ?? 0)
                   replyTextLabel?.text = (!(replyMessage?.mediaChatMessage?.mediaCaptionText.isEmpty ?? false)) ? replyMessage?.mediaChatMessage?.mediaCaptionText : replyMessage?.mediaChatMessage?.messageType.rawValue.capitalized.appending(" (\(duration.msToSeconds.minuteSecondMS))")
                   replyWithoutMediaCOns?.isActive = false
                   replyWithMediaCons?.isActive = true
               case .video:
                   messageTypeIcon?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "senderVideo" : "video")
                   if let thumImage = replyMessage?.mediaChatMessage?.mediaThumbImage {
                       let converter = ImageConverter()
                       let image =  converter.base64ToImage(thumImage)
                       mediaImageView?.image = image
                       mediaImageView?.isHidden = false
                       replyTextLabel?.text = (!(replyMessage?.mediaChatMessage?.mediaCaptionText.isEmpty ?? false)) ? replyMessage?.mediaChatMessage?.mediaCaptionText : replyMessage?.mediaChatMessage?.messageType.rawValue.capitalized
                   }
                   replyWithoutMediaCOns?.isActive = false
                   replyWithMediaCons?.isActive = true
                   
               case .document:
                   messageTypeIcon?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "document" : "document")
                   checkFileType(url: replyMessage?.mediaChatMessage?.mediaFileUrl ?? "", typeImageView: mediaImageView)
                   replyTextLabel?.text = replyMessage?.mediaChatMessage?.mediaFileName.capitalized
                   replyWithoutMediaCOns?.isActive = false
                   replyWithMediaCons?.isActive = true
               default:
                   messageIconView?.isHidden = true
                   replyWithoutMediaCOns?.isActive = true
                   replyWithMediaCons?.isActive = false
               }
               
           } else if replyMessage?.locationChatMessage != nil {
               mapView?.isHidden = false
               replyTextLabel?.text = "Location"
               mapView?.isUserInteractionEnabled = false
               messageTypeIcon?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "map" : "receivedMap")
               guard let latitude = replyMessage?.locationChatMessage?.latitude else {
                   return nil
               }
               guard let longitude = replyMessage?.locationChatMessage?.longitude  else {
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
               replyWithoutMediaCOns?.isActive = false
               replyWithMediaCons?.isActive = true
               messageIconView?.isHidden = false
           } else if replyMessage?.contactChatMessage != nil {
                   replyTextLabel?.attributedText = ChatUtils.setAttributeString(name: replyMessage?.contactChatMessage?.contactName)
               messageTypeIcon?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "senderContact" : "receiverContact")
               messageIconView?.isHidden = false
               replyWithoutMediaCOns?.isActive = true
               replyWithMediaCons?.isActive = false
           } else {
               mediaImageView?.isHidden = true
               replyWithoutMediaCOns?.isActive = true
               replyWithMediaCons?.isActive = false
           }
        if(replyMessage!.isMessageSentByMe) {
            replyUserLabel?.text = you.localized
        }
        else {
            replyUserLabel?.text = getUserName(jid: replyMessage?.senderUserJid ?? "" ,name: replyMessage?.senderUserName ?? "",
                                               nickName: replyMessage?.senderNickName ?? "", contactType: (replyMessage?.isDeletedUser ?? false) ? .deleted : (replyMessage?.isSavedContact ?? false) ? .live : .unknown)
        }
    }
        else {
            replyView?.isHidden = true
        }
        
        ChatUtils.setReceiverBubbleBackground(imageView: bubbleImageView)
        
        self.message = message
        
        if message?.messageChatType == .groupChat {
            senderGroupNameLabel.text = ChatUtils.getGroupSenderName(messsage: message)
        }else {
            senderNameView.isHidden = true
        }
        
        if let captionTxt = message?.mediaChatMessage?.mediaCaptionText, captionTxt != "" {
            caption.text = captionTxt
            timeOverlay.isHidden = true
            reecivedTime.isHidden = true
            captionTime?.isHidden = false
            captionViewHolder?.isHidden = false
            captionView?.isHidden = false
            emptyViewHeight?.constant = 0
        }else{
            timeOverlay.isHidden = false
            reecivedTime.isHidden = false
            captionTime?.isHidden = true
            caption.text = ""
            captionViewHolder?.isHidden = true
            captionView?.isHidden = true
            emptyViewHeight?.constant = 4
        }
        
        if let duration = message?.mediaChatMessage?.mediaDuration {
            videoTimeLabel.text = Int(duration).msToSeconds.minuteSecondMS
        } else {
            videoTimeLabel.text = ""
        }
        
        mediaStatus(message: message)
        
        if message?.messageType == .image {
            playButton.isHidden = true
            videoTimingContainer.isHidden = true
        }
        else {
            videoTimingContainer.isHidden = false
        }
        
//        if let thumImage = message?.mediaChatMessage?.mediaThumbImage {
//            ChatUtils.setThumbnail(imageContainer: imageContainer, base64String: thumImage)
//        }
        if (message?.messageType == .image && message?.mediaChatMessage?.mediaDownloadStatus == .downloaded) {
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
        
        guard let timeStamp =  message?.messageSentTime else {
            return self
        }
        let receivedTime = DateFormatterUtility.shared.convertMillisecondsToTime(milliSeconds: timeStamp).getTimeFormat()
        self.reecivedTime.text = receivedTime
        self.captionTime?.text = receivedTime
        
        //MARK: - Populating the Incoming Cell with the translated message
        
        if (message!.isMessageTranslated && FlyDefaults.isTranlationEnabled) {
            guard let chatMessage = message else {return self }
            print(chatMessage.mediaChatMessage?.mediaCaptionText)
            print(chatMessage.translatedMessageTextContent)
            caption!.text = chatMessage.mediaChatMessage?.mediaCaptionText ?? ""
            translatedCaptionLabel!.text = chatMessage.translatedMessageTextContent
        }
        return self
    }
    
    func mediaStatus(message : ChatMessage?) {
        switch message?.mediaChatMessage?.mediaDownloadStatus {
        case .not_downloaded:
            downloadView.isHidden = false
            downloadButton.isHidden = false
            progressView.isHidden = true
            playButton.isHidden = true
            fileSizeLabel.isHidden = false
            progressLoader?.transition(to: .indeterminate)
            if let fileSize = message?.mediaChatMessage?.mediaFileSize{
                fileSizeLabel.text = "\(Units(bytes: Int64(fileSize)).getReadableUnit())"
            }else {
                fileSizeLabel.text = ""
            }
        case .failed:
            downloadView.isHidden = false
            downloadButton.isHidden = false
            progressView.isHidden = true
            playButton.isHidden = true
            fileSizeLabel.isHidden = false
            if let fileSize = message?.mediaChatMessage?.mediaFileSize{
                fileSizeLabel.text = "\(Units(bytes: Int64(fileSize)).getReadableUnit())"
            }else {
                fileSizeLabel.text = ""
            }
        case .downloading:
            downloadView.isHidden = true
            downloadButton.isHidden = true
            let progrss = message?.mediaChatMessage?.mediaProgressStatus ?? 0
            progressLoader?.transition(to: .determinate(percentage: CGFloat(progrss/100)))
            if progrss == 0 || progrss == 100{
                progressLoader?.transition(to: .indeterminate)
            }
            progressLoader?.isHidden = false
            progressView.isHidden = false
            playButton.isHidden = true
        case .downloaded:
            if let localPath = message?.mediaChatMessage?.mediaLocalStoragePath {
                if FileManager.default.fileExists(atPath: localPath) {
                    let url = URL.init(fileURLWithPath: localPath)
                    let data = NSData(contentsOf: url as URL)
                    let image = UIImage(data: data! as Data)
                    imageContainer.image = image
                }
            }
            downloadView.isHidden = true
            downloadButton.isHidden = true
            progressView.isHidden = true
            progressLoader?.transition(to: .determinate(percentage: CGFloat(100)))
            playButton.isHidden = false
        default:
            downloadView.isHidden = false
            downloadButton.isHidden = false
            progressView.isHidden = true
            playButton.isHidden = true
            if let fileSize = message?.mediaChatMessage?.mediaFileSize{
                fileSizeLabel.text = "\(fileSize.byteSize)"
            }else {
                fileSizeLabel.text = ""
            }
        }
    }
}
