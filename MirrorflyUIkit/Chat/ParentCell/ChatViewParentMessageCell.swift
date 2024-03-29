//
//  ChatViewParentMessageCell.swift
//  MirrorflyUIkit
//
//  Created by User on 23/08/21.
//

import UIKit
import FlyCommon
import MapKit
import GoogleMaps
import Alamofire
import FlyCore
import SDWebImage

protocol RefreshBubbleImageViewDelegate {
    func refreshBubbleImageView(indexPath: IndexPath,isSelected: Bool,title: String?)
}

class ChatViewParentMessageCell: BaseTableViewCell {
    
    //Outgoing And Incoming cell -  Basic view and its elements
    @IBOutlet weak var baseView: UIView?
    @IBOutlet weak var bubbleImageView: UIImageView?
    
    @IBOutlet weak var replyUserLabelWidthCons: NSLayoutConstraint?
    @IBOutlet weak var locationOutgoingView: UIView!
    @IBOutlet weak var favouriteIcon: UIImageView?
    @IBOutlet weak var baseViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var groupMsgNameView: UIView?
    @IBOutlet weak var groupMsgSenderName: GroupReceivedMessageHeader?
    // Text message view and its elements
    @IBOutlet weak var messageLabel: UILabel?
    
    //General -> Favourite,time and status
    @IBOutlet weak var favouriteImageView: UIImageView?
    @IBOutlet weak var textMessageTimeLabel: UILabel?
    @IBOutlet weak var messageStatusImageView: UIImageView?
    @IBOutlet weak var senderProfileImage: UIImageView?
    @IBOutlet weak var senderTimeLabel: UILabel?
    @IBOutlet weak var senderStackView: UIStackView?
    @IBOutlet weak var starredMessageView: UIView?
    @IBOutlet weak var bubbleImageBottomCons: NSLayoutConstraint?
    @IBOutlet weak var bubbleImageTopCons: NSLayoutConstraint?
    @IBOutlet weak var sendFromLabel: UILabel?
    @IBOutlet weak var senderToLabel: UILabel?
    @IBOutlet weak var senderImageView: UIImageView?
    @IBOutlet weak var chatLocationMapView: GMSMapView?
    @IBOutlet weak var mediaLocationMapView: GMSMapView?
    
    // Location message view and its elements
    @IBOutlet weak var locationImageView: UIImageView?
    
    // Contact message view and its elements
    @IBOutlet weak var contactName: UILabel?
    @IBOutlet weak var saveContactButton: UIButton?
    
    // Reply view and its elements
    @IBOutlet weak var replyView: UIView?
    @IBOutlet weak var replyUserLabel: UILabel?
    @IBOutlet weak var replyTextLabel: UILabel?
    @IBOutlet weak var mediaImageView: UIImageView?
    @IBOutlet weak var messageTypeIcon: UIImageView?
    @IBOutlet weak var messageIconView: UIView?
    @IBOutlet weak var replyMessageIconWidthCons: NSLayoutConstraint?
    @IBOutlet weak var replyMessageIconHeightCons: NSLayoutConstraint?
    @IBOutlet weak var mediaImageViewWidthCons: NSLayoutConstraint?
    @IBOutlet weak var replyTextWithImageTrailingCons: NSLayoutConstraint?
    @IBOutlet weak var replyTextLabelTrailingCons: NSLayoutConstraint?
    @IBOutlet weak var replyViewHeightCons: NSLayoutConstraint?
    @IBOutlet weak var replyVIewWithMediaCons: NSLayoutConstraint?
    @IBOutlet weak var replyViewWithoutMediaCons: NSLayoutConstraint?
    
    //MARK -  Incoming cell
    @IBOutlet weak var seperatorLine: UIView?
    @IBOutlet weak var senderNameLabel: UILabel?
    @IBOutlet weak var replyTitleLabel: UILabel?
    @IBOutlet weak var translatedTextLabel: UILabel?
    @IBOutlet weak var stackViewTranslate: UIStackView?
    //@IBOutlet weak var stackViewTimeStamp: UIStackView?
    @IBOutlet weak var stackViewTimeStampTopCons: NSLayoutConstraint?
    @IBOutlet weak var translatedView: UIView?
    @IBOutlet weak var stackViewTranslateTrailingCons: NSLayoutConstraint?
    
    //MARK: Forward
    @IBOutlet weak var forwardImageView: UIImageView?
    @IBOutlet weak var forwardView: UIView?
    @IBOutlet weak var forwardLeadingCons: NSLayoutConstraint?
    @IBOutlet weak var bubbleImageLeadingCons: NSLayoutConstraint?
    @IBOutlet weak var forwardButton: UIButton?
    @IBOutlet weak var quickForwardButton: UIButton?
    @IBOutlet weak var quickForwardView: UIView?
    
    var refreshDelegate: RefreshBubbleImageViewDelegate? = nil
    var selectedForwardMessage: [SelectedMessages]? = []
    var isDeleteSelected: Bool = false
    var isStarredMessagePage: Bool = false
    var searchText: String?
       
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        textMessageTimeLabel?.font = UIFont.font9px_appLight()
        starredMessageView?.roundCorners(corners: [.topLeft, .bottomLeft, .topRight], radius: 5.0)
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
        // Configure the view for the selected state
    }
    
    func showHideStarredMessageView() {
        starredMessageView?.isHidden = isStarredMessagePage == true ? false : true
        baseViewTopConstraint?.isActive = isStarredMessagePage == true ? false : true
        bubbleImageTopCons?.isActive = isStarredMessagePage == true ? false : true
        senderStackView?.isHidden = isStarredMessagePage == true ? false : true
        bubbleImageBottomCons?.constant = isStarredMessagePage == true ? 10 : 3
    }
    
    func hideGroupMsgNameView() {
        groupMsgNameView?.isHidden = true
        groupMsgSenderName?.text = ""
    }
    
    func setUserProfileInfo(message: ChatMessage?,isBlocked: Bool) {
        let getProfileDetails = ChatManager.profileDetaisFor(jid: message?.chatUserJid ?? "")
        let senderProfileDetails = ChatManager.profileDetaisFor(jid: message?.senderUserJid ?? "")
        if !(message?.isMessageSentByMe ?? false) {
            senderToLabel?.text = message?.messageChatType == .singleChat ? "You" : getUserName(jid : getProfileDetails?.jid ?? "" ,name: getProfileDetails?.name ?? "", nickName: getProfileDetails?.nickName ?? "", contactType: getProfileDetails?.contactType ?? .local)
            sendFromLabel?.text = getUserName(jid : senderProfileDetails?.jid ?? "" ,name: senderProfileDetails?.name ?? "", nickName: senderProfileDetails?.nickName ?? "", contactType: senderProfileDetails?.contactType ?? .local)
            senderImageView?.image = UIImage(named: "Receiver")
        } else {
            sendFromLabel?.text = message?.isMessageSentByMe == true ? "You" : message?.senderUserName
            senderToLabel?.text = getUserName(jid : getProfileDetails?.jid ?? "" ,name: getProfileDetails?.name ?? "", nickName: getProfileDetails?.nickName ?? "", contactType: getProfileDetails?.contactType ?? .local)
            senderImageView?.image = UIImage(named: "Sender")
        }
        let timeStamp =  message?.messageSentTime
        senderTimeLabel?.text = String(describing: DateFormatterUtility.shared.convertMillisecondsToSentTime(milliSeconds: timeStamp ?? 0.0))
        senderProfileImage?.makeRounded()
        let contactColor = getColor(userName: getUserName(jid: senderProfileDetails?.jid ?? "",name: senderProfileDetails?.name ?? "", nickName: senderProfileDetails?.nickName ?? "", contactType: senderProfileDetails?.contactType ?? .local))
        let profileImage = (senderProfileDetails?.thumbImage.isEmpty ?? true) ? senderProfileDetails?.image : senderProfileDetails?.thumbImage
        setImage(imageURL: profileImage ?? "", name: getUserName(jid: senderProfileDetails?.jid ?? "", name: senderProfileDetails?.name ?? "", nickName: senderProfileDetails?.nickName ?? "", contactType: senderProfileDetails?.contactType ?? .local), color: contactColor, chatType: senderProfileDetails?.profileChatType ?? .singleChat, jid: senderProfileDetails?.jid ?? "")
    }
    
    private func getisBlockedMe(jid: String) -> Bool {
        return ChatManager.getContact(jid: jid)?.isBlockedMe ?? false
    }
    
    func setImage(imageURL: String, name: String, color: UIColor, chatType : ChatType,jid: String) {
        if !getisBlockedMe(jid: jid) {
            senderProfileImage?.loadFlyImage(imageURL: imageURL, name: name, chatType: chatType, jid: jid)
        } else if chatType == .groupChat {
            senderProfileImage?.image = UIImage(named: ImageConstant.ic_group_small_placeholder)!
        }  else {
            senderProfileImage?.image = UIImage(named: ImageConstant.ic_profile_placeholder)!
        }
    }
    
    func getCellFor(_ message: ChatMessage?, at indexPath: IndexPath?,isShowForwardView: Bool?, fromChat: Bool = false, isMessageSearch: Bool = false, searchText: String = "") -> ChatViewParentMessageCell? {
        currentIndexPath = nil
        currentIndexPath = indexPath
        replyViewHeightCons?.isActive = true
        replyTextLabel?.text = ""
        replyUserLabel?.text = ""
        translatedTextLabel?.text = ""

        // Forward view elements and its data
        bubbleImageLeadingCons?.constant = (isShowForwardView == true) ? 10 : 0
        stackViewTimeStampTopCons?.constant = FlyDefaults.isTranlationEnabled && message?.isMessageTranslated ?? false ? 5 : -2
       // stackViewTimeStampTopCons?.constant = message!.isMessageTranslated ? 5 : 0
        stackViewTranslateTrailingCons?.constant = FlyDefaults.isTranlationEnabled && message!.isMessageTranslated ? 0 : 20
        
        if selectedForwardMessage?.filter({$0.chatMessage.messageId == message?.messageId}).first?.isSelected == true {
            forwardImageView?.image = UIImage(named: "forwardSelected")
            forwardImageView?.isHidden = false
            forwardView?.makeCircleView(borderColor: Color.forwardCircleBorderColor.cgColor, borderWidth: 0.0)
        } else {
           // forwardImageView?.image = UIImage(named: "")
            forwardImageView?.isHidden = true
            forwardView?.makeCircleView(borderColor: Color.forwardCircleBorderColor.cgColor, borderWidth: 1.5)
        }
        
        if (message?.messageStatus == .notAcknowledged || message?.messageStatus == .sent || isShowForwardView == true || isStarredMessagePage == true) {
            quickForwardView?.isHidden = true
            quickForwardButton?.isHidden = true
            isAllowSwipe = false
        } else {
            quickForwardView?.isHidden = false
            quickForwardButton?.isHidden = false
            isAllowSwipe = true
        }
        
        if !(isShowForwardView ?? false) || (isDeleteSelected == false && message?.isMessageRecalled == true) {
            forwardView?.isHidden = true
            forwardButton?.isHidden = true
            forwardLeadingCons?.constant = 0
        } else {
            forwardView?.isHidden = false
            forwardButton?.isHidden = false
            forwardLeadingCons?.constant = 20
        }
        
        // Favorite message icon
        if(message!.isMessageStarred) {
            favouriteIcon?.isHidden = false
            favouriteImageView?.isHidden = false
        }
        else {
            favouriteIcon?.isHidden = true
            favouriteImageView?.isHidden = true
        }
        mediaLocationMapView?.isHidden = true
        
        
        // Reply view elements and its data
       let isReplyMessage = message?.isReplyMessage ?? false
       if isReplyMessage {
            replyView?.isHidden = false
           let replyMessage = FlyMessenger.getMessageOfId(messageId: message?.replyParentChatMessage?.messageId ?? "")
           if message?.replyParentChatMessage?.isMessageRecalled == true || message?.replyParentChatMessage?.isMessageDeleted == true || replyMessage == nil {
               replyTextLabel?.text = "Original message not available"
               mediaImageView?.isHidden = true
               messageIconView?.isHidden = true
               mediaImageViewWidthCons?.constant = 0
               replyMessageIconWidthCons?.constant = 0
               replyMessageIconHeightCons?.isActive = false
               replyTextWithImageTrailingCons?.isActive = false
               replyTextLabelTrailingCons?.isActive = true
               replyVIewWithMediaCons?.isActive = false
               replyViewWithoutMediaCons?.isActive = true
           } else {
            let getReplymessage =  replyMessage?.messageTextContent
           replyViewHeightCons?.isActive = (getReplymessage?.count ?? 0 > 20) ? false : true
               replyTextLabel?.attributedText = ChatUtils.getAttributedMessage(message: getReplymessage ?? "", searchText: searchText, isMessageSearch: isMessageSearch,isSystemBlue: false)
           if replyMessage?.mediaChatMessage != nil {
               mediaImageViewWidthCons?.constant = 50
               replyMessageIconWidthCons?.constant = 12
               replyMessageIconHeightCons?.isActive = true
               replyTextWithImageTrailingCons?.isActive = true
               replyTextLabelTrailingCons?.isActive = false
               switch replyMessage?.mediaChatMessage?.messageType {
               case .image:
                   messageTypeIcon?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "senderCamera" : "receiverCamera")
                   if let thumImage = replyMessage?.mediaChatMessage?.mediaThumbImage {
                       let converter = ImageConverter()
                       let image =  converter.base64ToImage(thumImage)
                       mediaImageView?.image = image
                       mediaImageView?.isHidden = false
                       messageIconView?.isHidden = false
                       replyTextLabel?.text = !(replyMessage?.mediaChatMessage?.mediaCaptionText.isEmpty ?? false) ? replyMessage?.mediaChatMessage?.mediaCaptionText : "Photo"
                   }
                   replyVIewWithMediaCons?.isActive = true
                   replyViewWithoutMediaCons?.isActive = false
               case .audio:
                   mediaImageView?.isHidden = true
                   messageIconView?.isHidden = false
                   ChatUtils.setIconForAudio(imageView: messageTypeIcon, chatMessage: nil, replyParentMessage: message?.replyParentChatMessage)
                   let duration = Int(replyMessage?.mediaChatMessage?.mediaDuration ?? 0)
                   replyTextLabel?.text = !(replyMessage?.mediaChatMessage?.mediaCaptionText.isEmpty ?? false) ? replyMessage?.mediaChatMessage?.mediaCaptionText : replyMessage?.mediaChatMessage?.messageType.rawValue.capitalized.appending(" (\(duration.msToSeconds.minuteSecondMS))")
                   replyVIewWithMediaCons?.isActive = false
                   replyViewWithoutMediaCons?.isActive = true
               case .video:
                   messageTypeIcon?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "senderVideo" : "video")
                   if let thumImage = replyMessage?.mediaChatMessage?.mediaThumbImage {
                       let converter = ImageConverter()
                       let image =  converter.base64ToImage(thumImage)
                       mediaImageView?.image = image
                       mediaImageView?.isHidden = false
                       messageIconView?.isHidden = false
                       replyTextLabel?.text = !(replyMessage?.mediaChatMessage?.mediaCaptionText.isEmpty ?? false) ? replyMessage?.mediaChatMessage?.mediaCaptionText : replyMessage?.mediaChatMessage?.messageType.rawValue.capitalized
                   }
                   replyVIewWithMediaCons?.isActive = true
                   replyViewWithoutMediaCons?.isActive = false
                   
                   //// - Need to check thumbnail image
               case .document:
                   messageTypeIcon?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "document" : "document")
                   checkFileType(url: replyMessage?.mediaChatMessage?.mediaFileUrl ?? "", typeImageView: mediaImageView)
                   mediaImageView?.contentMode = .scaleAspectFill
                   mediaImageView?.isHidden = false
                   messageIconView?.isHidden = false
                   replyTextLabel?.text = replyMessage?.mediaChatMessage?.mediaFileName.capitalized
                   replyVIewWithMediaCons?.isActive = true
                   replyViewWithoutMediaCons?.isActive = false
               default:
                   messageIconView?.isHidden = true
                   mediaImageViewWidthCons?.constant = 0
                   replyMessageIconWidthCons?.constant = 0
                   replyMessageIconHeightCons?.isActive = false
                   mediaImageView?.isHidden = true
                   replyTextWithImageTrailingCons?.isActive = false
                   replyTextLabelTrailingCons?.isActive = true
                   replyVIewWithMediaCons?.isActive = false
                   replyViewWithoutMediaCons?.isActive = true
               }
           } else if replyMessage?.locationChatMessage != nil {
               mediaImageView?.isHidden = true
               mediaLocationMapView?.isHidden = false
               replyTextLabel?.text = "Location"
               mediaLocationMapView?.camera = GMSCameraPosition.camera(withLatitude: replyMessage?.locationChatMessage?.latitude ?? 0.0, longitude: replyMessage?.locationChatMessage?.longitude ?? 0.0, zoom: 16.0, bearing: 360.0, viewingAngle: 15.0)
               mediaLocationMapView?.isUserInteractionEnabled = false
               DispatchQueue.main.async
               { [self] in
                   // 2. Perform UI Operations.
                   let position = CLLocationCoordinate2DMake(replyMessage?.locationChatMessage?.latitude ?? 0.0,replyMessage?.locationChatMessage?.longitude ?? 0.0)
                   let marker = GMSMarker(position: position)
                   marker.map = mediaLocationMapView
               }
               replyVIewWithMediaCons?.isActive = true
               replyViewWithoutMediaCons?.isActive = false
               messageTypeIcon?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "map" : "receivedMap")
               messageIconView?.isHidden = false
               mediaImageViewWidthCons?.constant = 50
               replyMessageIconWidthCons?.constant = 12
               replyMessageIconHeightCons?.isActive = true
               replyTextWithImageTrailingCons?.isActive = true
               replyTextLabelTrailingCons?.isActive = false
           } else if replyMessage?.contactChatMessage != nil {
               mediaImageView?.isHidden = true
               replyTextLabel?.attributedText = ChatUtils.setAttributeString(name: replyMessage?.contactChatMessage?.contactName)
               messageTypeIcon?.image = UIImage(named: (message?.isMessageSentByMe ?? false) ? "senderContact" : "receiverContact")
               messageIconView?.isHidden = false
               mediaImageViewWidthCons?.constant = 0
               replyMessageIconWidthCons?.constant = 12
               replyMessageIconHeightCons?.isActive = true
               replyTextWithImageTrailingCons?.isActive = false
               replyTextLabelTrailingCons?.isActive = true
               replyVIewWithMediaCons?.isActive = false
               replyViewWithoutMediaCons?.isActive = true
           } else {
               mediaImageView?.isHidden = true
               messageIconView?.isHidden = true
               mediaImageViewWidthCons?.constant = 0
               replyMessageIconWidthCons?.constant = 0
               replyMessageIconHeightCons?.isActive = false
               replyTextWithImageTrailingCons?.isActive = false
               replyTextLabelTrailingCons?.isActive = true              
               replyVIewWithMediaCons?.isActive = false
               replyViewWithoutMediaCons?.isActive = true
           }
       }
        if(replyMessage?.isMessageSentByMe ?? false) {
            replyUserLabel?.text = you.localized
        }
        else {
            let name =   getUserName(jid: replyMessage?.senderUserJid ?? "", name: replyMessage?.senderUserName ?? "", nickName: replyMessage?.senderNickName ?? "", contactType: (replyMessage?.isDeletedUser ?? false) ? .deleted : (replyMessage?.isSavedContact ?? false) ? .live : .unknown)
            replyUserLabel?.text = name
        }
           
        ChatUtils.setDeletedReplyMessage(chatMessage: replyMessage, messageIconView: messageIconView, messageTypeIcon: messageTypeIcon, replyTextLabel: replyTextLabel, mediaImageView: mediaImageView, mediaImageViewWidthCons: mediaImageViewWidthCons, replyMessageIconWidthCons: replyMessageIconWidthCons, replyMessageIconHeightCons: replyMessageIconHeightCons)
    }
        else {
            mediaImageViewWidthCons?.constant = 0
            replyMessageIconWidthCons?.constant = 0
            replyMessageIconHeightCons?.isActive = false
            replyTextWithImageTrailingCons?.isActive = false
            replyTextLabelTrailingCons?.isActive = true
            replyView?.isHidden = true
        }
        
        //Bubble View
        if (message!.isMessageSentByMe) {
            ChatUtils.setSenderBubbleBackground(imageView: bubbleImageView)
        }
        else {
            ChatUtils.setReceiverBubbleBackground(imageView: bubbleImageView)
            if message?.messageChatType == .groupChat {
                if let nameLabel = groupMsgSenderName {
                    nameLabel.text = ChatUtils.getGroupSenderName(messsage: message)
                }
            } else {
                groupMsgNameView?.isHidden = true
                groupMsgSenderName?.isHidden = true
            }
        }
        
        // Message acknowledgement status
            messageStatusImageView?.isAccessibilityElement = true
        if(message!.isMessageSentByMe) {
            messageStatusImageView?.isHidden = false
            switch message?.messageStatus {
            case .sent:
                messageStatusImageView?.image = UIImage.init(named: ImageConstant.ic_hour)
                messageStatusImageView?.accessibilityLabel = sent.localized
                break
            case .acknowledged:
                messageStatusImageView?.image = UIImage.init(named: ImageConstant.ic_sent)
                messageStatusImageView?.accessibilityLabel = acknowledged.localized
                break
            case .delivered:
                messageStatusImageView?.image = UIImage.init(named: ImageConstant.ic_delivered)
                messageStatusImageView?.accessibilityLabel = delivered.localized
                break
            case .seen:
                messageStatusImageView?.image = UIImage.init(named: ImageConstant.ic_seen)
                messageStatusImageView?.accessibilityLabel = seen.localized
                break
            case .received:
                messageStatusImageView?.image = UIImage.init(named: ImageConstant.ic_delivered)
                messageStatusImageView?.accessibilityLabel = delivered.localized
                break
            default:
                messageStatusImageView?.image = UIImage.init(named: ImageConstant.ic_hour)
                messageStatusImageView?.accessibilityLabel = notAcknowledged.localized
                break
            }
        }
        else {
            messageStatusImageView?.isHidden = true
         //   self.seperatorLine.isHidden = true
        }
        // Message time
        guard let timeStamp =  message?.messageSentTime else {
            return self
        }
        textMessageTimeLabel?.isAccessibilityElement =  true
        textMessageTimeLabel?.accessibilityLabel = Utility.currentMillisecondsToTime(milliSec: timeStamp)
        textMessageTimeLabel?.accessibilityLabel = DateFormatterUtility.shared.currentMillisecondsToLocalTime(milliSec: timeStamp)
        textMessageTimeLabel?.text = DateFormatterUtility.shared.currentMillisecondsToLocalTime(milliSec: timeStamp)
        
        
        self.isAccessibilityElement = true
        self.accessibilityLabel = message?.messageId
        favouriteImageView?.accessibilityLabel = message?.messageId
        bubbleImageView?.isAccessibilityElement =  true
        
        switch  message?.messageType {
        case .text:
            if let label = messageLabel {

                messageLabel?.attributedText = processTextMessage(message: message?.messageTextContent ?? "", uiLabel: label, fromChat: fromChat, isMessageSearch: isMessageSearch, searchText: searchText, isSentByMe: message?.isMessageSentByMe ?? false)
                print("message label width = \(messageLabel?.frame.size.width)")

            }
        case .location:
            
            guard let latitude = message?.locationChatMessage?.latitude else {
                return nil
            }
            guard let longitude = message?.locationChatMessage?.longitude  else {
                return nil
            }
            
            chatLocationMapView?.camera = GMSCameraPosition.camera(withLatitude: latitude, longitude: longitude, zoom: 16.0, bearing: 360.0, viewingAngle: 15.0)
   
            DispatchQueue.main.async
            { [self] in
                // 2. Perform UI Operations.
                var position = CLLocationCoordinate2DMake(latitude,longitude)
                let marker = GMSMarker(position: position)
                marker.map = chatLocationMapView
            }
            
           break
        case .contact:
            if isMessageSearch == true || isStarredMessagePage {
                ChatUtils.highlight(uilabel: contactName ?? UILabel(), message: message?.contactChatMessage?.contactName ?? "", searchText: searchText, isMessageSearch: isMessageSearch, isSystemBlue: isStarredMessagePage == true && isMessageSearch == true ? true : false)
            } else {
                contactName?.attributedText =  ChatUtils.getAttributedMessage(message: message?.contactChatMessage?.contactName ?? "", searchText: searchText, isMessageSearch: isMessageSearch,isSystemBlue: isStarredMessagePage == true && isMessageSearch == true ? true : false)
            }
            break
        
        default:
            break
            
        }
        
        //MARK: - Populating the Incoming Cell with the translated message
        
        if (message!.isMessageTranslated && FlyDefaults.isTranlationEnabled) {
            guard let chatMessage = message,let messageLabeltemp = messageLabel, let translatedTextLabeltemp = translatedTextLabel else {return self }

            messageLabel?.attributedText = processTextMessage(message: chatMessage.messageTextContent , uiLabel: messageLabeltemp, fromChat: fromChat, isMessageSearch: isMessageSearch, searchText: searchText, isSentByMe: message?.isMessageSentByMe ?? false)
            translatedTextLabel?.attributedText = processTextMessage(message: chatMessage.translatedMessageTextContent , uiLabel: translatedTextLabeltemp, fromChat: fromChat, isMessageSearch: isMessageSearch, searchText: searchText, isSentByMe: message?.isMessageSentByMe ?? false)

        }
        return self
    }
    
    @objc func didTapTextLabel(sender: UITapGestureRecognizer){
        if let textUILabel = sender.view as? UILabel {
            let tempName = (textUILabel).text ?? ""
            if !tempName.isEmpty {
                let textArray = tempName.split(separator: " ")
                for tempText in textArray {
                    let text = String(tempText)
                    if text.isNumber && text.count >= 6 && text.count <= 13 {
                        let textRange = (tempName as NSString).range(of: text)
                        if(sender.didTapAttributedTextInLabel(label: textUILabel, inRange: textRange)) {
                            print("didTapTextLabel isNumber \(text)")
                            AppUtils.shared.callPhoneNumber(phoneNumber: text)
                            break
                        }
                        
                    } else if text.isURL {
                        let textRange = (tempName as NSString).range(of: text)
                        if(sender.didTapAttributedTextInLabel(label: textUILabel, inRange: textRange)) {
                            print("didTapTextLabel isURL \(text)")
                            AppUtils.shared.openURLInBrowser(urlString: text)
                            break
                        }
                    }
                }
            }
        }
        
    }
    

    func processTextMessage(message : String, uiLabel : UILabel, fromChat: Bool = false, isMessageSearch: Bool = false, searchText: String = "", isSentByMe: Bool) -> NSMutableAttributedString? {

        var attributedString : NSMutableAttributedString?
        if !message.isEmpty {
            attributedString = NSMutableAttributedString(string: message)
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapTextLabel(sender:)))
            let textArray = message.trim().split(separator: " ")
            if isStarredMessagePage == true && searchText.trim().isNotEmpty == true {
                let range = (message.lowercased() as NSString).range(of: searchText.lowercased())
                attributedString?.addAttributes([NSAttributedString.Key.foregroundColor: UIColor.systemBlue], range: range)
            }
            for (index, tempText) in textArray.enumerated() {
                print("processTextMessage index \(index) item \(tempText)")
                print("processTextMessage tempText \(tempText)")
                 let text = String(tempText).trim()
                 if text.isNumber && text.count >= 6 && text.count <= 13 {
                     print("processTextMessage isNumber \(tempText)")
                     let numberRange = (message as NSString).range(of: text)
                     attributedString?.addAttribute(NSAttributedString.Key.underlineStyle,value: NSUnderlineStyle.single.rawValue, range: numberRange)
                     let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapTextLabel(sender:)))
                     uiLabel.addGestureRecognizer(gestureRecognizer)
                 } else if text.trim().isURL {
                     print("processTextMessage text.isURL \(tempText)")
                     let urlRange = (message as NSString).range(of: text )
                     attributedString?.addAttribute(NSAttributedString.Key.underlineStyle,value: NSUnderlineStyle.single.rawValue, range: urlRange)
                     uiLabel.addGestureRecognizer(gestureRecognizer)
                 }

                if fromChat && isMessageSearch {
                    do {
                        let regex = try NSRegularExpression(pattern:  NSRegularExpression.escapedPattern(for: searchText.trim().lowercased()).folding(options: .regularExpression, locale: .current), options: .caseInsensitive)
                        let range = NSRange(location: 0, length: message.utf16.count)
                        for match in regex.matches(in: message.lowercased().folding(options: .regularExpression, locale: .current), options: .withTransparentBounds, range: range) {
                            attributedString?.addAttribute(NSAttributedString.Key.backgroundColor, value: Color.color_3276E2 ?? .blue, range: match.range)
                        }
                    }
                    catch {
                    }
                }
                 print("processTextMessage After else \(tempText)")
            }
        } else {
            attributedString = NSMutableAttributedString(string: message)
        }
        return attributedString
        
    }
}

extension UITapGestureRecognizer {
    func didTapAttributedTextInLabel(label: UILabel, inRange targetRange: NSRange) -> Bool {
            // Create instances of NSLayoutManager, NSTextContainer and NSTextStorage
            let layoutManager = NSLayoutManager()
            let textContainer = NSTextContainer(size: CGSize.zero)
            let textStorage = NSTextStorage(attributedString: label.attributedText!)
            
            // Configure layoutManager and textStorage
            layoutManager.addTextContainer(textContainer)
            textStorage.addLayoutManager(layoutManager)
            
            // Configure textContainer
            textContainer.lineFragmentPadding = 0.0
            textContainer.lineBreakMode = label.lineBreakMode
            textContainer.maximumNumberOfLines = label.numberOfLines
            let labelSize = label.bounds.size
            textContainer.size = labelSize
            
            // Find the tapped character location and compare it to the specified range
            let locationOfTouchInLabel = self.location(in: label)
            let textBoundingBox = layoutManager.usedRect(for: textContainer)
            let textContainerOffset = CGPoint(x: (labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x,
                                              y: (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y);
            let locationOfTouchInTextContainer = CGPoint(x: locationOfTouchInLabel.x - textContainerOffset.x,
                                                         y: locationOfTouchInLabel.y - textContainerOffset.y);
            var indexOfCharacter = layoutManager.characterIndex(for: locationOfTouchInTextContainer, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
            indexOfCharacter = indexOfCharacter + 4
            return NSLocationInRange(indexOfCharacter, targetRange)
    }
}

