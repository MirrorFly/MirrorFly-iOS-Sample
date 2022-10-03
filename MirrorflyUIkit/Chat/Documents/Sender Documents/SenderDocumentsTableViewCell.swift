//
//  SenderDocumentsTableViewCell.swift
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

class SenderDocumentsTableViewCell: BaseTableViewCell {
    
    @IBOutlet weak var baseViewTopConstraint: NSLayoutConstraint?
    @IBOutlet weak var bubbleImageView: UIImageView?
    @IBOutlet weak var cellBaseView: UIView?
    @IBOutlet weak var imageContainerView: UIImageView?
    @IBOutlet weak var documenTypeView: UIView?
    @IBOutlet weak var documentNameLabel: UILabel?
    @IBOutlet weak var documetTypeImage: UIImageView?
    @IBOutlet weak var sentTimeLabel: UILabel?
    @IBOutlet weak var messageStatusImage: UIImageView?
    @IBOutlet weak var nicoProgressBar: NicoProgressBar?
    @IBOutlet weak var documentNameLabelTrailingConstarint: NSLayoutConstraint?
    @IBOutlet weak var fwdButton: UIButton?
    
    @IBOutlet weak var doctNameTrailingWithoutImageCons: NSLayoutConstraint?
    @IBOutlet weak var documentNameTrailingCons: NSLayoutConstraint?
    @IBOutlet weak var viewDocumentButton: UIButton?
    @IBOutlet weak var pageCountLabel: UILabel?
    @IBOutlet weak var documentSizeLabel: UILabel?
    
    @IBOutlet weak var uploadButton: UIButton?
    @IBOutlet weak var uploadView: UIView?
    @IBOutlet weak var uploadCancelImage: UIImageView?
    @IBOutlet weak var uploadImageView: UIImageView?
    
    @IBOutlet weak var replyViewHeight: NSLayoutConstraint?
    @IBOutlet weak var replyView: UIView?
    @IBOutlet weak var replyTypeIconImageView: UIImageView?
    @IBOutlet weak var replyUserNameLabel: UILabel?
    @IBOutlet weak var replyTypeLabel: UILabel?
    @IBOutlet weak var replyTypeImageView: UIImageView?
    @IBOutlet weak var mediaMapView: GMSMapView?
    
    // Forward Outlet
    @IBOutlet weak var forwardImageView: UIImageView?
    @IBOutlet weak var forwardView: UIView?
    @IBOutlet weak var forwardLeadingCons: NSLayoutConstraint?
    @IBOutlet weak var forwardButton: UIButton?
    
    var isUploading: Bool? = false
    
    var isShowAudioLoadingIcon: Bool? = false
    
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
    }
    
    func setupUI() {
        replyView?.roundCorners(corners: [.topLeft, .topRight], radius: 5.0)
        cellBaseView?.roundCorners(corners: [.topLeft, .bottomLeft, .topRight], radius: 5.0)
        //        documenTypeView?.roundCorners(corners: [.topLeft, .bottomLeft, .topRight, .bottomRight], radius: 5.0)
        imageContainerView?.backgroundColor = UIColor.clear
        //uploadView?.isHidden = true
        nicoProgressBar?.primaryColor = .white
        nicoProgressBar?.secondaryColor = .clear
    }
    
    func setSelectView(selected: Bool) {
        if selected {
            self.backgroundColor = .lightGray
        } else {
            self.backgroundColor = .clear
        }
    }
    
    func getCellFor(_ message: ChatMessage?, at indexPath: IndexPath?, isShowForwardView: Bool?) -> SenderDocumentsTableViewCell? {
        currentIndexPath = nil
        currentIndexPath = indexPath
        let mediaUrl = message?.mediaChatMessage?.mediaFileUrl
        checkFileType(urlExtension: ((mediaUrl?.isEmpty ?? false ? (message?.mediaChatMessage?.mediaLocalStoragePath.components(separatedBy: ".").last as? String) : mediaUrl?.components(separatedBy: ".").last) ?? ""), typeImageView: documetTypeImage)
        // Forward view elements and its data
        forwardView?.isHidden = (isShowForwardView == true && message?.mediaChatMessage?.mediaUploadStatus == .uploaded) ? false : true
        forwardLeadingCons?.constant = (isShowForwardView == true && message?.mediaChatMessage?.mediaUploadStatus == .uploaded) ? 20 : 0
        forwardButton?.isHidden = (isShowForwardView == true && message?.mediaChatMessage?.mediaUploadStatus == .uploaded) ? false : true
        
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
        isAllowSwipe = (message?.messageStatus == .notAcknowledged || message?.mediaChatMessage?.mediaUploadStatus == .not_uploaded || message?.mediaChatMessage?.mediaUploadStatus == .failed  || message?.mediaChatMessage?.mediaUploadStatus == .uploading) ? false : true
        if message?.isCarbonMessage == true {
            if  ((message?.mediaChatMessage?.mediaDownloadStatus == .not_downloaded  || message?.mediaChatMessage?.mediaDownloadStatus == .failed || message?.mediaChatMessage?.mediaDownloadStatus == .downloading || message?.messageStatus == .notAcknowledged || message?.messageStatus == .sent) && isShowForwardView == false) {
                forwardView?.isHidden = true
                forwardButton?.isHidden = true
            } else {
                forwardView?.isHidden = false
                forwardButton?.isHidden = false
            }
        } else {
            if  (message?.mediaChatMessage?.mediaUploadStatus == .uploaded && isShowForwardView == true) {
                forwardView?.isHidden = false
                forwardButton?.isHidden = false
            } else {
                forwardView?.isHidden = true
                forwardButton?.isHidden = true
            }
        }
        
        if  (message?.mediaChatMessage?.mediaUploadStatus == .uploaded && isShowForwardView == false && message?.messageStatus != .notAcknowledged) {
            fwdButton?.isHidden = false
        } else {
            fwdButton?.isHidden = true
        }
        
        
        
        /// - Handling Reply Messages
        
        if(message!.isReplyMessage) {
            documenTypeView?.roundCorners(corners: [.bottomLeft, .bottomRight], radius: 5)
            replyView?.isHidden = false
            let getReplymessage = message?.replyParentChatMessage?.messageTextContent
            let replyMessage = FlyMessenger.getMessageOfId(messageId: message?.replyParentChatMessage?.messageId ?? "")
            replyTypeLabel?.text = getReplymessage
            checkFileType(url: replyMessage?.mediaChatMessage?.mediaFileUrl ?? "", typeImageView: replyTypeImageView)
            
            if replyMessage?.isMessageSentByMe == false {
                replyUserNameLabel?.text = you.localized
            } else {
                replyUserNameLabel?.text = getUserName(jid: replyMessage?.senderUserJid ?? "", name: replyMessage?.senderUserName ?? "",
                                                       nickName: replyMessage?.senderNickName ?? "",
                                                       contactType: replyMessage?.isSavedContact == true ? .live : .unknown)
            }
            
            if replyMessage?.mediaChatMessage != nil {
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
                    mediaMapView?.isHidden = true
                case .audio:
                    let duration = Int(replyMessage?.mediaChatMessage?.mediaDuration ?? 0)
                    ChatUtils.setIconForAudio(imageView: replyTypeIconImageView, chatMessage: message)
                    replyTypeLabel?.text = (!(replyMessage?.mediaChatMessage?.mediaCaptionText.isEmpty ?? false)) ? replyMessage?.mediaChatMessage?.mediaCaptionText : replyMessage?.mediaChatMessage?.messageType.rawValue.capitalized.appending(" (\(duration.msToSeconds.minuteSecondMS))")
                    replyTypeImageView?.isHidden = false
                    mediaMapView?.isHidden = true
                case .video:
                    replyTypeIconImageView?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "senderVideo" : "video")
                    replyTypeImageView?.isHidden = false
                    if let thumImage = message?.replyParentChatMessage?.mediaChatMessage?.mediaThumbImage {
                        let converter = ImageConverter()
                        let image =  converter.base64ToImage(thumImage)
                        replyTypeImageView?.image = image
                        replyTypeLabel?.text = (!(replyMessage?.mediaChatMessage?.mediaCaptionText.isEmpty ?? false)) ? replyMessage?.mediaChatMessage?.mediaCaptionText : replyMessage?.mediaChatMessage?.messageType.rawValue.capitalized
                    }
                    mediaMapView?.isHidden = true
                case .document:
                    replyTypeIconImageView?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "ic_document" : "ic_document")
                    checkFileType(url: replyMessage?.mediaChatMessage?.mediaFileUrl ?? "", typeImageView: replyTypeImageView)
                    
                    replyTypeLabel?.text = replyMessage?.mediaChatMessage?.mediaFileName
                    replyTypeImageView?.isHidden = false
                    mediaMapView?.isHidden = true
                default:
                    replyTypeImageView?.isHidden = true
                    replyUserNameLabel?.isHidden = true
                    replyTypeLabel?.isHidden = true
                    replyTypeIconImageView?.isHidden = true
                    mediaMapView?.isHidden = true
                }
            } else if replyMessage?.locationChatMessage != nil {
                replyTypeLabel?.text = "Location"
                //                chatMapView?.isUserInteractionEnabled = false
                replyTypeIconImageView?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "map" : "receivedMap")
                guard let latitude = replyMessage?.locationChatMessage?.latitude else {
                    return nil
                }
                guard let longitude = replyMessage?.locationChatMessage?.longitude  else {
                    return nil
                }
                mediaMapView?.camera = GMSCameraPosition.camera(withLatitude: replyMessage?.locationChatMessage?.latitude ?? 0.0, longitude: replyMessage?.locationChatMessage?.longitude ?? 0.0, zoom: 16.0, bearing: 360.0, viewingAngle: 15.0)
                mediaMapView?.isUserInteractionEnabled = false
                DispatchQueue.main.async
                { [self] in
                    // 2. Perform UI Operations.
                    let position = CLLocationCoordinate2DMake(replyMessage?.locationChatMessage?.latitude ?? 0.0,replyMessage?.locationChatMessage?.longitude ?? 0.0)
                    let marker = GMSMarker(position: position)
                    marker.map = mediaMapView
                }
                replyTypeIconImageView?.isHidden = false
                replyTypeImageView?.isHidden = true
                mediaMapView?.isHidden = false
                
            } else if replyMessage?.contactChatMessage != nil {
                replyTypeLabel?.attributedText = ChatUtils.setAttributeString(name: replyMessage?.contactChatMessage?.contactName)
                replyTypeImageView?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "senderContact" : "receiverContact")
                replyTypeIconImageView?.isHidden = false
                //                replyTrailingCons?.isActive = true
                //                replyTrailingWithMediaCons?.isActive = false
                mediaMapView?.isHidden = true
            }
            
        } else {
            documenTypeView?.roundCorners(corners: [.topLeft, .bottomLeft, .topRight, .bottomRight], radius: 5.0)
            replyView?.isHidden = true
        }
        
        /// Carbon Messages Handler
        
        if message?.isCarbonMessage == false {
            if message?.mediaChatMessage?.mediaUploadStatus == .not_uploaded {
                uploadCancelImage?.isHidden = false
                uploadCancelImage?.image = UIImage(named: ImageConstant.ic_upload)
                uploadButton?.isHidden = false

                if ((sendMediaMessages?.count ?? 0) > 0 && (sendMediaMessages?.filter({$0.messageId == message?.messageId}).count ?? 0) > 0) {
                    nicoProgressBar?.isHidden = false
                    nicoProgressBar?.transition(to: .indeterminate)
                } else {
                    print("sender", sendMediaMessages?.count ?? 0)
                    nicoProgressBar?.isHidden = true
                    
                }
                documentNameTrailingCons?.isActive = true
                doctNameTrailingWithoutImageCons?.isActive = false
            } else if message?.mediaChatMessage?.mediaUploadStatus == .failed {
                uploadCancelImage?.isHidden = false
                uploadCancelImage?.image = UIImage(named: ImageConstant.ic_upload)
                uploadButton?.isHidden = false

                if ((sendMediaMessages?.count ?? 0) > 0 && (sendMediaMessages?.filter({$0.messageId == message?.messageId}).count ?? 0) > 0) {
                    nicoProgressBar?.isHidden = true
                } else {
                    print("sender", sendMediaMessages?.count ?? 0)
                    nicoProgressBar?.isHidden = true
                    
                }
                documentNameTrailingCons?.isActive = true
                doctNameTrailingWithoutImageCons?.isActive = false
            } else if message?.mediaChatMessage?.mediaUploadStatus == .uploading {
                uploadCancelImage?.image = UIImage(named: ImageConstant.ic_audioUploadCancel)
                uploadButton?.isHidden = true
                uploadImageView?.isHidden = true
                uploadCancelImage?.isHidden = false
                nicoProgressBar?.isHidden = false
                nicoProgressBar?.transition(to: .indeterminate)
                documentNameTrailingCons?.isActive = true
                doctNameTrailingWithoutImageCons?.isActive = false
            } else if message?.mediaChatMessage?.mediaUploadStatus == .uploaded {
                if let localPath = message?.mediaChatMessage?.mediaFileName {
                    let directoryURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let folderPath: URL = directoryURL.appendingPathComponent("FlyMedia/Document", isDirectory: true)
                    let fileURL: URL = folderPath.appendingPathComponent(localPath)
                    if FileManager.default.fileExists(atPath: fileURL.relativePath) {
                        let data = NSData(contentsOf: fileURL)
                        let image = UIImage(data: data! as Data)
                        imageContainerView?.image = image
                    }
                }
                documentNameTrailingCons?.isActive = false
                doctNameTrailingWithoutImageCons?.isActive = true
                nicoProgressBar?.isHidden = true
                uploadCancelImage?.isHidden = true
                uploadImageView?.isHidden = true
                uploadButton?.isHidden = true
                
            } else {
                nicoProgressBar?.isHidden = true
                uploadCancelImage?.isHidden = true
                uploadImageView?.isHidden = true
                uploadButton?.isHidden = true
                documentNameTrailingCons?.isActive = false
                doctNameTrailingWithoutImageCons?.isActive = true
            }
        } else {
            if message?.mediaChatMessage?.mediaDownloadStatus == .not_downloaded || message?.messageStatus == .sent {
                uploadCancelImage?.isHidden = false
                uploadCancelImage?.image = (isShowAudioLoadingIcon == true && indexPath == IndexPath(row: 0, section: 0)) ? UIImage(named: ImageConstant.ic_uploadCancel) : UIImage(named: "download")
                uploadButton?.isHidden = (isShowAudioLoadingIcon == true && indexPath == IndexPath(row: 0, section: 0)) ? true : false
                if ((sendMediaMessages?.count ?? 0) > 0 && (sendMediaMessages?.filter({$0.messageId == message?.messageId}).count ?? 0) > 0) {
                    print("sender", sendMediaMessages?.count ?? 0)
                    nicoProgressBar?.isHidden = false
                    nicoProgressBar?.transition(to: .indeterminate)
                } else {
                    print("sender", sendMediaMessages?.count ?? 0)
                    nicoProgressBar?.isHidden = true
                    
                }
            } else if message?.mediaChatMessage?.mediaDownloadStatus == .failed  {
                uploadCancelImage?.isHidden = false
                uploadCancelImage?.image = (isShowAudioLoadingIcon == true && indexPath == IndexPath(row: 0, section: 0)) ? UIImage(named: ImageConstant.ic_uploadCancel) : UIImage(named: "download")
                uploadButton?.isHidden = (isShowAudioLoadingIcon == true && indexPath == IndexPath(row: 0, section: 0)) ? true : false
                if ((sendMediaMessages?.count ?? 0) > 0 && (sendMediaMessages?.filter({$0.messageId == message?.messageId}).count ?? 0) > 0) {
                    print("sender", sendMediaMessages?.count ?? 0)
                    nicoProgressBar?.isHidden = true
                } else {
                    print("sender", sendMediaMessages?.count ?? 0)
                    nicoProgressBar?.isHidden = true
                    
                }
            } else if message?.mediaChatMessage?.mediaDownloadStatus == .downloading {
                uploadCancelImage?.image = UIImage(named: ImageConstant.ic_uploadCancel)
                uploadCancelImage?.isHidden = false
                nicoProgressBar?.isHidden = false
                nicoProgressBar?.transition(to: .indeterminate)
                
            } else if message?.mediaChatMessage?.mediaDownloadStatus == .downloaded {
                if let localPath = message?.mediaChatMessage?.mediaFileName {
                    let directoryURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let folderPath: URL = directoryURL.appendingPathComponent("FlyMedia/Document", isDirectory: true)
                    let fileURL: URL = folderPath.appendingPathComponent(localPath)
                    if FileManager.default.fileExists(atPath: fileURL.relativePath) {
                        let data = NSData(contentsOf: fileURL)
                        let image = UIImage(data: data! as Data)
                        imageContainerView?.image = image
                    }
                }
                uploadCancelImage?.isHidden = true
                nicoProgressBar?.isHidden = true
                
            } else {
                nicoProgressBar?.isHidden = true
            }
        }
        
        let status = message?.messageStatus
        if status == .acknowledged || status == .received || status == .delivered || status == .seen {
            nicoProgressBar?.isHidden = true
        }
        
        ChatUtils.setSenderBubbleBackground(imageView: bubbleImageView)
        
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
        
        guard let timeStamp =  message?.messageSentTime else {
            return self
        }
        
        if let fileSize = message?.mediaChatMessage?.mediaFileSize{
            documentSizeLabel?.text = "\(fileSize.byteSize)"
        } else {
            documentSizeLabel?.text = ""
        }
    
        documentNameLabel?.text = message?.mediaChatMessage?.mediaFileName
        sentTimeLabel?.text = Utility.convertTime(timeStamp: timeStamp)
        self.layoutIfNeeded()
        self.layoutSubviews()
        
        return self
    }
    
    func startUpload() {
        uploadCancelImage?.isHidden = false
        uploadCancelImage?.image = UIImage(named: ImageConstant.ic_uploadCancel)
        nicoProgressBar?.isHidden = false
        nicoProgressBar?.transition(to: .indeterminate)
    }
    
    func stopUpload() {
        uploadCancelImage?.isHidden = false
        uploadCancelImage?.image = UIImage(named: ImageConstant.ic_upload)
        nicoProgressBar?.isHidden = true
    }
    
    func stopDownload() {
        uploadCancelImage?.isHidden = false
        uploadCancelImage?.image = UIImage(named: "Download")
        nicoProgressBar?.isHidden = true
    }
}

