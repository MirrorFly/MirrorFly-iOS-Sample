//
//  ReceiverDocumentsTableViewCell.swift
//  UiKitQa
//
//  Created by Prabakaran M on 17/05/22.
//

import UIKit
import FlyCommon
import FlyCore
import NicoProgress
import GoogleMaps
import MapKit

class ReceiverDocumentsTableViewCell: BaseTableViewCell {

    @IBOutlet weak var bubbleImageView: UIImageView?
    @IBOutlet weak var documenTypeView: UIView?
    @IBOutlet weak var documentNameLabel: UILabel?
    @IBOutlet weak var documetTypeImage: UIImageView?
    @IBOutlet weak var sentTimeLabel: UILabel?
    @IBOutlet weak var groupSenderNameLabel: GroupReceivedMessageHeader!
    @IBOutlet weak var groupSenderNameView: UIView?
    @IBOutlet weak var nicoProgressBar: NicoProgressBar?
    @IBOutlet weak var fwdButton: UIButton?
    
    @IBOutlet weak var forwardImageleadingCons: NSLayoutConstraint?
    @IBOutlet weak var bubbleLeadingCons: NSLayoutConstraint?
    @IBOutlet weak var replyTypeIconWidthCons: NSLayoutConstraint?
    @IBOutlet weak var replyView: UIView?
    @IBOutlet weak var replyTypeIconImageView: UIImageView?
    @IBOutlet weak var replyUserNameLabel: UILabel?
    @IBOutlet weak var replyTypeLabel: UILabel?
    @IBOutlet weak var replyTypeImageView: UIImageView?
    
    @IBOutlet weak var replyTypeIconView: UIView?
    @IBOutlet weak var topStackView: UIStackView?
    @IBOutlet weak var mapView: GMSMapView?
    @IBOutlet weak var documentSizeLabel: UILabel?
    
    @IBOutlet weak var downloadButton: UIButton?
    @IBOutlet weak var downloadView: UIView?
    @IBOutlet weak var cancelDownloadImage: UIImageView?
    @IBOutlet weak var downloadImageView: UIImageView?
    
    @IBOutlet weak var favImageView: UIImageView?
    // Forward Outlet
    @IBOutlet weak var forwardImageView: UIImageView?
    @IBOutlet weak var forwardView: UIView?
    @IBOutlet weak var replyImageWidthCons: NSLayoutConstraint?
    @IBOutlet weak var forwardButton: UIButton?
    @IBOutlet weak var viewDocumentButton: UIButton?
    @IBOutlet weak var bubbleLeadingWithSuperViewCons: NSLayoutConstraint?
    @IBOutlet weak var forwardTrailingCons: NSLayoutConstraint?
    @IBOutlet weak var replyStackViewTrailingCons: NSLayoutConstraint?
    var isUploading: Bool? = false
    
    var selectedForwardMessage: [SelectedMessages]? = []
    var sendMediaMessages: [ChatMessage]? = []
    var message: ChatMessage?
    
    var refreshDelegate: RefreshBubbleImageViewDelegate? = nil
    
    override func awakeFromNib() { 
        super.awakeFromNib()
        setupUI()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func setupUI() {
        bubbleImageView?.roundCorners(corners: [.topLeft, .bottomRight, .topRight], radius: 5.0)
        documenTypeView?.roundCorners(corners: [.topLeft, .topRight, .bottomLeft, .bottomRight], radius: 5.0)
        nicoProgressBar?.primaryColor = .gray
        nicoProgressBar?.secondaryColor = .clear
        replyView?.backgroundColor = .white
    }
    
    func setSelectView(selected: Bool) {
        if selected {
            self.backgroundColor = .lightGray
        } else {
            self.backgroundColor = .clear
        }
    }
    
    func getCellFor(_ message: ChatMessage?, at indexPath: IndexPath?, isShowForwardView: Bool?,isDeletedOrStarredSelected: Bool?, fromChat: Bool = false, isMessageSearch: Bool = false, searchText: String = "") -> ReceiverDocumentsTableViewCell? {
        currentIndexPath = nil
        currentIndexPath = indexPath
        replyUserNameLabel?.text = ""
        
        // Forward view elements and its data
        forwardView?.isHidden = (isShowForwardView == true && message?.mediaChatMessage?.mediaDownloadStatus == .downloaded) ? false : true
        forwardButton?.isHidden = (isShowForwardView == true && message?.mediaChatMessage?.mediaDownloadStatus == .downloaded) ? false : true
        viewDocumentButton?.isHidden = isShowForwardView == true ? true : false
        
        if isShowForwardView == true && message?.mediaChatMessage?.mediaDownloadStatus == .downloaded {
            bubbleLeadingWithSuperViewCons?.isActive = false
            bubbleLeadingWithSuperViewCons?.constant = 0
            forwardImageleadingCons?.isActive = true
            forwardTrailingCons?.isActive = true
        } else {
            forwardImageleadingCons?.isActive = false
            bubbleLeadingWithSuperViewCons?.constant = 20
            forwardTrailingCons?.isActive = false
            bubbleLeadingWithSuperViewCons?.isActive = true
        }
        
        // Starred Messages
        favImageView?.isHidden =  message!.isMessageStarred ? false : true
        
        if selectedForwardMessage?.filter({$0.chatMessage.messageId == message?.messageId}).first?.isSelected == true {
            forwardView?.makeCircleView(borderColor: Color.forwardCircleBorderColor.cgColor, borderWidth: 0.0)
            forwardImageView?.image = UIImage(named: "forwardSelected")
            forwardImageView?.isHidden = false
            forwardView?.makeCircleView(borderColor: Color.forwardCircleBorderColor.cgColor, borderWidth: 0.0)
        } else {
            forwardImageView?.image = UIImage(named: "")
            forwardImageView?.isHidden = true
            forwardButton?.isSelected = !(forwardButton?.isSelected ?? false)
            forwardView?.makeCircleView(borderColor: Color.forwardCircleBorderColor.cgColor, borderWidth: 1.5)
        }
        
            if (message?.mediaChatMessage?.mediaDownloadStatus == .not_downloaded || message?.mediaChatMessage?.mediaDownloadStatus == .failed || message?.mediaChatMessage?.mediaDownloadStatus == .downloading || message?.messageStatus == .notAcknowledged || message?.messageStatus == .sent || isShowForwardView == false) {
                isAllowSwipe = false
            } else {
                isAllowSwipe = true
            }
        
        if  ((message?.mediaChatMessage?.mediaDownloadStatus == .not_downloaded  || message?.mediaChatMessage?.mediaDownloadStatus == .failed || message?.mediaChatMessage?.mediaDownloadStatus == .downloading || message?.messageStatus == .notAcknowledged || message?.messageStatus == .sent) && isShowForwardView == false) {
            fwdButton?.isHidden = true
        } else {
            fwdButton?.isHidden = false
        }
        
        isAllowSwipe = message?.messageStatus == .notAcknowledged ? false : true
        
        /// - Handling Reply Messages
        
        if(message!.isReplyMessage) {
            replyView?.isHidden = false
            groupSenderNameView?.isHidden = true
            let getReplymessage = message?.replyParentChatMessage?.messageTextContent
            let replyMessage = FlyMessenger.getMessageOfId(messageId: message?.replyParentChatMessage?.messageId ?? "")
            replyTypeLabel?.attributedText = ChatUtils.getAttributedMessage(message: getReplymessage ?? "", searchText: searchText, isMessageSearch: isMessageSearch)
            replyTypeIconImageView?.isHidden = true
            replyTypeIconView?.isHidden = true
            if replyMessage?.isMessageSentByMe == true {
                replyUserNameLabel?.text = you.localized
                documenTypeView?.roundCorners(corners: [.bottomLeft, .bottomRight], radius: 5)
            } else {
                documenTypeView?.roundCorners(corners: [.topLeft, .bottomLeft, .topRight, .bottomRight], radius: 5.0)
                replyUserNameLabel?.text = getUserName(jid: replyMessage?.senderUserJid ?? "", name: replyMessage?.senderUserName ?? "",
                                                       nickName: replyMessage?.senderNickName ?? "",
                                                       contactType: replyMessage?.isSavedContact == true ? .live : .unknown)
            }
            replyTypeImageView?.isHidden = true
            replyTypeIconWidthCons?.constant = 0
            if message?.replyParentChatMessage?.isMessageDeleted == true || message?.replyParentChatMessage?.isMessageRecalled == true {
                replyTypeLabel?.text = "Original message not available"
                replyTypeIconWidthCons?.constant = 0
                replyTypeImageView?.isHidden = true
                replyTypeIconImageView?.isHidden = true
                replyTypeIconView?.isHidden = true
                replyImageWidthCons?.isActive = false
                replyStackViewTrailingCons?.constant = 10
            } else if replyMessage?.mediaChatMessage != nil {
                replyTypeIconImageView?.isHidden = false
                replyTypeIconView?.isHidden = false
                replyTypeImageView?.isHidden = false
                switch replyMessage?.mediaChatMessage?.messageType {
                case .image:
                    replyStackViewTrailingCons?.constant = 54
                    replyTypeIconWidthCons?.isActive = true
                    replyTypeIconWidthCons?.constant = 12
                    replyTypeIconImageView?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "senderCamera" : "receiverCamera")
                    if let thumImage = replyMessage?.mediaChatMessage?.mediaThumbImage {
                        let converter = ImageConverter()
                        let image =  converter.base64ToImage(thumImage)
                        replyTypeImageView?.image = image
                        replyTypeImageView?.isHidden = false
                        replyImageWidthCons?.isActive = true
                        replyTypeIconImageView?.isHidden = false
                        replyTypeIconView?.isHidden = false
                        replyTypeLabel?.text = (!(replyMessage?.mediaChatMessage?.mediaCaptionText.isEmpty ?? false)) ? replyMessage?.mediaChatMessage?.mediaCaptionText : "Photo"
                    }
                    mapView?.isHidden = true
                case .audio:
                    ChatUtils.setIconForAudio(imageView: replyTypeIconImageView, chatMessage: replyMessage)
                    let duration = Int(replyMessage?.mediaChatMessage?.mediaDuration ?? 0)
                    replyTypeLabel?.text = (!(replyMessage?.mediaChatMessage?.mediaCaptionText.isEmpty ?? false)) ? replyMessage?.mediaChatMessage?.mediaCaptionText : replyMessage?.mediaChatMessage?.messageType.rawValue.capitalized.appending(" (\(duration.msToSeconds.minuteSecondMS))")
                    replyTypeImageView?.isHidden = true
                    replyStackViewTrailingCons?.constant = 10
                    replyImageWidthCons?.isActive = false
                    replyTypeIconWidthCons?.constant = 12
                    replyTypeIconWidthCons?.isActive = true
                    mapView?.isHidden = true
                    replyTypeIconImageView?.isHidden = false
                    replyTypeIconView?.isHidden = false
                case .video:
                    replyTypeIconWidthCons?.constant = 12
                    replyTypeIconWidthCons?.isActive = true
                    replyTypeIconImageView?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "senderVideo" : "video")
                    if let thumImage = replyMessage?.mediaChatMessage?.mediaThumbImage {
                        let converter = ImageConverter()
                        let image =  converter.base64ToImage(thumImage)
                        replyTypeImageView?.image = image
                        replyTypeImageView?.isHidden = false
                        replyStackViewTrailingCons?.constant = 54
                        replyImageWidthCons?.isActive = true
                        replyTypeIconWidthCons?.constant = 12
                        replyTypeIconWidthCons?.isActive = true
                        replyTypeIconImageView?.isHidden = false
                        replyTypeIconView?.isHidden = false
                        replyTypeLabel?.text = (!(replyMessage?.mediaChatMessage?.mediaCaptionText.isEmpty ?? false)) ? replyMessage?.mediaChatMessage?.mediaCaptionText : replyMessage?.mediaChatMessage?.messageType.rawValue.capitalized
                        
                    }
                    mapView?.isHidden = true
                case .document:
                    replyTypeIconImageView?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "document" : "document")
                    let mediaUrl = message?.mediaChatMessage?.mediaFileUrl
                    checkFileType(urlExtension: ((mediaUrl?.isEmpty ?? false ? (message?.mediaChatMessage?.mediaLocalStoragePath.components(separatedBy: ".").last as? String) : mediaUrl?.components(separatedBy: ".").last) ?? ""), typeImageView: replyTypeImageView)
                    replyTypeLabel?.text = message?.replyParentChatMessage?.mediaChatMessage?.mediaFileName
                    replyTypeImageView?.isHidden = false
                    replyStackViewTrailingCons?.constant = 54
                    replyImageWidthCons?.isActive = true
                    replyTypeIconWidthCons?.constant = 12
                    replyTypeIconWidthCons?.isActive = true
                    mapView?.isHidden = true
                    replyTypeIconImageView?.isHidden = false
                    replyTypeIconView?.isHidden = false
                default:
                    replyTypeImageView?.isHidden = true
                    replyTypeIconImageView?.isHidden = true
                    replyTypeIconView?.isHidden = true
                    replyStackViewTrailingCons?.constant = 10
                }
                
            } else if replyMessage?.locationChatMessage != nil {
                replyStackViewTrailingCons?.constant = 54
                replyTypeLabel?.text = "Location"
                mapView?.isHidden = false
                replyTypeIconWidthCons?.isActive = true
                replyTypeIconWidthCons?.constant = 12
                replyTypeIconImageView?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "map" : "receivedMap")
                mapView?.isUserInteractionEnabled = false
                guard let latitude = replyMessage?.locationChatMessage?.latitude else {
                    return nil
                }
                guard let longitude = replyMessage?.locationChatMessage?.longitude  else {
                    return nil
                }
                
                mapView?.camera = GMSCameraPosition.camera(withLatitude: latitude, longitude: longitude, zoom: 16.0, bearing: 360.0, viewingAngle: 15.0)
       
                DispatchQueue.main.async { [self] in
                    // 2. Perform UI Operations.
                    let position = CLLocationCoordinate2DMake(latitude,longitude)
                    let marker = GMSMarker(position: position)
                    marker.map = mapView
                }
                replyTypeImageView?.isHidden = true
                replyImageWidthCons?.isActive = false
                replyTypeIconImageView?.isHidden = false
                replyTypeIconView?.isHidden = false
            } else if replyMessage?.contactChatMessage != nil {
                replyStackViewTrailingCons?.constant = 10
                replyTypeLabel?.attributedText = ChatUtils.setAttributeString(name: replyMessage?.contactChatMessage?.contactName)
                replyTypeIconImageView?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "senderContact" : "receiverContact")
                replyTypeIconWidthCons?.isActive = true
                replyTypeIconWidthCons?.constant = 12
                replyTypeIconImageView?.isHidden = false
                replyTypeIconView?.isHidden = false
                mapView?.isHidden = true
                replyTypeImageView?.isHidden = true
                replyImageWidthCons?.isActive = false
            }
        } else {
            replyView?.isHidden = true
        }
        ChatUtils.setReceiverBubbleBackground(imageView: bubbleImageView)
        
        
        switch message?.mediaChatMessage?.mediaDownloadStatus {
        case .not_downloaded:
            downloadImageView?.image = UIImage(named: ImageConstant.ic_download)
            downloadImageView?.isHidden = false
            nicoProgressBar?.isHidden = true
            downloadButton?.isHidden = false
            downloadView?.isHidden = false
        case .failed:
            downloadImageView?.image = UIImage(named: ImageConstant.ic_download)
            downloadImageView?.isHidden = false
            nicoProgressBar?.isHidden = true
            downloadButton?.isHidden = false
            downloadView?.isHidden = false
        case .downloading:
            downloadImageView?.image = UIImage(named: ImageConstant.ic_download_cancel)
            downloadButton?.isHidden = false
            downloadImageView?.isHidden = false
            nicoProgressBar?.isHidden = false
            nicoProgressBar?.transition(to: .indeterminate)
            downloadView?.isHidden = false
        case .downloaded:
            downloadImageView?.isHidden = true
            downloadButton?.isHidden = true
            nicoProgressBar?.isHidden = true
            downloadView?.isHidden = true
        default:
            downloadImageView?.image = UIImage(named: ImageConstant.ic_download)
            downloadImageView?.isHidden = false
            downloadButton?.isHidden = false
            nicoProgressBar?.isHidden = true
            downloadView?.isHidden = false
        }
        
        guard let timeStamp =  message?.messageSentTime else {
            return self
        }
        
        if let fileSize = message?.mediaChatMessage?.mediaFileSize {
            documentSizeLabel?.text = "\(fileSize.byteSize)"
        } else {
            documentSizeLabel?.text = ""
        }
        
        if message?.messageChatType == .groupChat {
            groupSenderNameLabel?.text = ChatUtils.getGroupSenderName(messsage: message)
            groupSenderNameLabel?.textColor = ChatUtils.getColorForUser(userName: message?.senderUserName)
            groupSenderNameLabel?.font = UIFont.font14px_appSemibold()
        } else {
            groupSenderNameLabel?.isHidden = true
            groupSenderNameView?.isHidden = true
        }
        
        let mediaUrl = message?.mediaChatMessage?.mediaFileUrl
        checkFileType(urlExtension: ((mediaUrl?.isEmpty ?? false ? (message?.mediaChatMessage?.mediaLocalStoragePath.components(separatedBy: ".").last as? String) : mediaUrl?.components(separatedBy: ".").last) ?? ""), typeImageView: documetTypeImage)
        documentNameLabel?.text = message?.mediaChatMessage?.mediaFileName
        sentTimeLabel?.text = DateFormatterUtility.shared.currentMillisecondsToLocalTime(milliSec: timeStamp)
        self.layoutIfNeeded()
        self.layoutSubviews()
        
        return self
    }
    
    func startDownload() {
        DispatchQueue.main.async { [weak self] in
            self?.downloadImageView?.image = UIImage(named: ImageConstant.ic_download_cancel)
            self?.downloadImageView?.isHidden = false
            self?.downloadButton?.isHidden = false
            self?.nicoProgressBar?.isHidden = false
            self?.downloadView?.isHidden = false
            self?.nicoProgressBar?.transition(to: .indeterminate)
        }
    }
    
    func stopDownload() {
        DispatchQueue.main.async { [weak self] in
            self?.downloadImageView?.image = UIImage(named: ImageConstant.ic_download)
            self?.downloadImageView?.isHidden = false
            self?.nicoProgressBar?.isHidden = true
            self?.downloadButton?.isHidden = false
            self?.downloadView?.isHidden = false
        }
    }
}
