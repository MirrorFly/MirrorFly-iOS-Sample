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
    
    @IBOutlet weak var cellHeightConstarint: NSLayoutConstraint?
    @IBOutlet weak var cellBaseViewTopConstarint: NSLayoutConstraint?
    @IBOutlet weak var bubbleImageView: UIImageView?
    @IBOutlet weak var cellBaseView: UIView?
    @IBOutlet weak var imageContainerView: UIImageView?
    @IBOutlet weak var documenTypeView: UIView?
    @IBOutlet weak var documentNameLabel: UILabel?
    @IBOutlet weak var documetTypeImage: UIImageView?
    @IBOutlet weak var sentTimeLabel: UILabel?
    @IBOutlet weak var messageStatusImage: UIImageView?
    @IBOutlet weak var groupSenderNameLabel: GroupReceivedMessageHeader!
    @IBOutlet weak var groupSenderNameView: UIView?
    @IBOutlet weak var nicoProgressBar: NicoProgressBar?
    @IBOutlet weak var fwdButton: UIButton?
    
    @IBOutlet weak var bubbleLeadingCons: NSLayoutConstraint?
    @IBOutlet weak var replyViewHeight: NSLayoutConstraint?
    @IBOutlet weak var replyView: UIView?
    @IBOutlet weak var replyTypeIconImageView: UIImageView?
    @IBOutlet weak var replyUserNameLabel: UILabel?
    @IBOutlet weak var replyTypeLabel: UILabel?
    @IBOutlet weak var replyTypeImageView: UIImageView?
    
    @IBOutlet weak var pageCountLabel: UILabel?
    @IBOutlet weak var documentSizeLabel: UILabel?
    
    @IBOutlet weak var downloadButton: UIButton?
    @IBOutlet weak var downloadView: UIView?
    @IBOutlet weak var cancelDownloadImage: UIImageView?
    @IBOutlet weak var downloadImageView: UIImageView?
    
    // Forward Outlet
    @IBOutlet weak var forwardImageView: UIImageView?
    @IBOutlet weak var forwardView: UIView?
    @IBOutlet weak var forwardLeadingCons: NSLayoutConstraint?
    @IBOutlet weak var forwardButton: UIButton?
    @IBOutlet weak var viewDocumentButton: UIButton?
    
    var isUploading: Bool? = false
    
    var selectedForwardMessage: [SelectedForwardMessage]? = []
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
        cellBaseView?.roundCorners(corners: [.topLeft, .bottomRight, .topRight], radius: 5.0)
        documenTypeView?.roundCorners(corners: [.topLeft, .topRight, .bottomLeft, .bottomRight], radius: 5.0)
        nicoProgressBar?.primaryColor = .gray
        nicoProgressBar?.secondaryColor = .clear
    }
    
    func setSelectView(selected: Bool) {
        if selected {
            self.backgroundColor = .lightGray
        } else {
            self.backgroundColor = .clear
        }
    }
    
    func getCellFor(_ message: ChatMessage?, at indexPath: IndexPath?, isShowForwardView: Bool?) -> ReceiverDocumentsTableViewCell? {
        currentIndexPath = nil
        currentIndexPath = indexPath
        replyUserNameLabel?.text = ""
        
        // Forward view elements and its data
        forwardView?.isHidden = (isShowForwardView == true && message?.mediaChatMessage?.mediaDownloadStatus == .downloaded) ? false : true
        forwardButton?.isHidden = (isShowForwardView == true && message?.mediaChatMessage?.mediaDownloadStatus == .downloaded) ? false : true
        
        if isShowForwardView == true && message?.mediaChatMessage?.mediaDownloadStatus == .downloaded {
            bubbleLeadingCons?.isActive = true
            forwardLeadingCons?.isActive = false
        } else {
            bubbleLeadingCons?.isActive = false
            forwardLeadingCons?.isActive = true
        }
        
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
                forwardView?.isHidden = true
                forwardButton?.isHidden = true
                isAllowSwipe = false
            } else {
                forwardView?.isHidden = false
                forwardButton?.isHidden = false
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
            cellBaseViewTopConstarint?.constant = 50
            replyView?.isHidden = false
            groupSenderNameView?.isHidden = true
            let getReplymessage = message?.replyParentChatMessage?.messageTextContent
            let replyMessage = FlyMessenger.getMessageOfId(messageId: message?.replyParentChatMessage?.messageId ?? "")
            replyTypeLabel?.text = getReplymessage
            let mediaUrl = message?.mediaChatMessage?.mediaFileUrl
            checkFileType(urlExtension: ((mediaUrl?.isEmpty ?? false ? (message?.mediaChatMessage?.mediaLocalStoragePath.components(separatedBy: ".").last as? String) : mediaUrl?.components(separatedBy: ".").last) ?? ""), typeImageView: replyTypeImageView)
            
            if replyMessage?.isMessageSentByMe == false {
                replyUserNameLabel?.text = you.localized
                documenTypeView?.roundCorners(corners: [.bottomLeft, .bottomRight], radius: 5)
            } else {
                documenTypeView?.roundCorners(corners: [.topLeft, .bottomLeft, .topRight, .bottomRight], radius: 5.0)
                replyUserNameLabel?.textColor = ChatUtils.getColorForUser(userName: message?.senderUserName)
                replyUserNameLabel?.text = getUserName(jid: replyMessage?.senderUserJid ?? "", name: replyMessage?.senderUserName ?? "",
                                                       nickName: replyMessage?.senderNickName ?? "",
                                                       contactType: replyMessage?.isSavedContact == true ? .live : .unknown)
            }
            
            if replyMessage?.mediaChatMessage != nil {
                replyTypeImageView?.isHidden = false
                switch replyMessage?.mediaChatMessage?.messageType {
                case .image:
                    replyTypeIconImageView?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "senderCamera" : "receiverCamera")
                    if let thumImage = replyMessage?.mediaChatMessage?.mediaThumbImage {
                        let converter = ImageConverter()
                        let image =  converter.base64ToImage(thumImage)
                        replyTypeImageView?.image = image
                        replyTypeImageView?.isHidden = false
                        replyTypeLabel?.text = (!(replyMessage?.mediaChatMessage?.mediaCaptionText.isEmpty ?? false)) ? replyMessage?.mediaChatMessage?.mediaCaptionText : "Photo"
                    }
                case .audio:
                    ChatUtils.setIconForAudio(imageView: replyTypeIconImageView, chatMessage: message)
                    let duration = Int(replyMessage?.mediaChatMessage?.mediaDuration ?? 0)
                    replyTypeLabel?.text = (!(replyMessage?.mediaChatMessage?.mediaCaptionText.isEmpty ?? false)) ? replyMessage?.mediaChatMessage?.mediaCaptionText : replyMessage?.mediaChatMessage?.messageType.rawValue.capitalized.appending(" (\(duration.msToSeconds.minuteSecondMS))")
                case .video:
                    replyTypeIconImageView?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "senderVideo" : "video")
                    if let thumImage = replyMessage?.mediaChatMessage?.mediaThumbImage {
                        let converter = ImageConverter()
                        let image =  converter.base64ToImage(thumImage)
                        replyTypeImageView?.image = image
                        replyTypeImageView?.isHidden = false
                        replyTypeLabel?.text = (!(replyMessage?.mediaChatMessage?.mediaCaptionText.isEmpty ?? false)) ? replyMessage?.mediaChatMessage?.mediaCaptionText : replyMessage?.mediaChatMessage?.messageType.rawValue.capitalized
                        
                    }
                case .document:
                    replyTypeIconImageView?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "ic_document" : "ic_document")
                    let mediaUrl = message?.mediaChatMessage?.mediaFileUrl
                    checkFileType(urlExtension: ((mediaUrl?.isEmpty ?? false ? (message?.mediaChatMessage?.mediaLocalStoragePath.components(separatedBy: ".").last as? String) : mediaUrl?.components(separatedBy: ".").last) ?? ""), typeImageView: replyTypeImageView)
                    
                    replyUserNameLabel?.text = message?.replyParentChatMessage?.senderUserName.capitalized
                    replyTypeLabel?.text = message?.replyParentChatMessage?.mediaChatMessage?.mediaFileName
                    replyTypeImageView?.isHidden = false
                default:
                    replyTypeImageView?.isHidden = true
                }
                
            } else if replyMessage?.locationChatMessage != nil {
                replyTypeLabel?.text = "Location"
                replyTypeIconImageView?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "map" : "receivedMap")
                guard let latitude = replyMessage?.locationChatMessage?.latitude else {
                    return nil
                }
                guard let longitude = replyMessage?.locationChatMessage?.longitude  else {
                    return nil
                }
                
                DispatchQueue.main.async { [self] in
                    // 2. Perform UI Operations.
                    let position = CLLocationCoordinate2DMake(latitude,longitude)
                    let marker = GMSMarker(position: position)
                }
                replyTypeIconImageView?.isHidden = false
            } else if replyMessage?.contactChatMessage != nil {
                replyTypeLabel?.attributedText = ChatUtils.setAttributeString(name: replyMessage?.contactChatMessage?.contactName)
                replyTypeImageView?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "senderContact" : "receiverContact")
                replyTypeIconImageView?.isHidden = false
            }
            
            
        } else {
            replyView?.isHidden = true
            cellBaseViewTopConstarint?.constant = 4
        }
        
        
        switch message?.messageStatus {
        case .notAcknowledged:
            messageStatusImage?.image = UIImage(named: ImageConstant.ic_hour)
            messageStatusImage?.accessibilityLabel = notAcknowledged.localized
        case .sent:
            messageStatusImage?.image = UIImage(named: ImageConstant.ic_hour)
            messageStatusImage?.accessibilityLabel = sent.localized
        case .acknowledged:
            messageStatusImage?.image = UIImage(named: ImageConstant.ic_sent)
            messageStatusImage?.accessibilityLabel = acknowledged.localized
        case .delivered:
            messageStatusImage?.image = UIImage(named: ImageConstant.ic_delivered)
            messageStatusImage?.accessibilityLabel = delivered.localized
        case .seen:
            messageStatusImage?.image = UIImage(named: ImageConstant.ic_seen)
            messageStatusImage?.accessibilityLabel = seen.localized
        case .received:
            messageStatusImage?.image = UIImage(named: ImageConstant.ic_delivered)
            messageStatusImage?.accessibilityLabel = delivered.localized
        default:
            messageStatusImage?.image = UIImage(named: ImageConstant.ic_hour)
            messageStatusImage?.accessibilityLabel = notAcknowledged.localized
        }
        
        
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
            groupSenderNameView?.isHidden = false
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
        sentTimeLabel?.text = Utility.convertTime(timeStamp: timeStamp)
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
