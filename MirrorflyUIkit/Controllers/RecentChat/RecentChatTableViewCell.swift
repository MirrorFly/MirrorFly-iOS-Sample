//
//  RecentChatTableViewCell.swift
//  MirrorflyUIkit
//
//  Created by User on 14/09/21.
//

import UIKit
import FlyCommon
import SDWebImage
import FlyCore

class RecentChatTableViewCell: UITableViewCell {
    @IBOutlet weak var profileImageButton: UIButton?
    @IBOutlet weak var profileImageView: UIImageView?
    @IBOutlet weak var userNameLabel: UILabel?
    @IBOutlet weak var userMessageLabel: UILabel?
    @IBOutlet weak var chatTimeLabel: UILabel?
    @IBOutlet weak var countView: UIView?
    @IBOutlet weak var countLabel: UILabel?
    @IBOutlet weak var statusImage: UIImageView?
    @IBOutlet weak var statusView: UIView?
    @IBOutlet weak var receiverMessageTypeImageView: UIImageView?
    @IBOutlet weak var pinImageView: UIImageView! {
        didSet {
            pinImageView.image = UIImage(named: "pushpin")?.withHorizontallyFlippedOrientation()
        }
    }
    @IBOutlet weak var muteImageView: UIImageView!
    @IBOutlet weak var archivedStatusLabel: UILabel! {
        didSet {
            archivedStatusLabel.isHidden = true
            archivedStatusLabel.cornerRadius(radius: 3, width: 0.3, color: Color.muteSwitchColor)
        }
    }
    @IBOutlet weak var senderNameLabel: UILabel?
    @IBOutlet weak var statusImageCons: NSLayoutConstraint?
    @IBOutlet weak var receiverMessageTypeView: UIView?
    @IBOutlet weak var statusViewTralingCons: NSLayoutConstraint?
    @IBOutlet weak var receivedMessageTrailingCons: NSLayoutConstraint?
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        setupProfileImageUI()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    func setupProfileImageUI() {
        profileImageView?.setCircleView()
    }
    
    private func getIsBlockedByMe(jid: String) -> Bool {
        return ChatManager.getContact(jid: jid)?.isBlockedMe ?? false
    }
    
    func setImage(imageURL: String, name: String, color: UIColor , recentChat : RecentChat) {
        let urlString = "\(FlyDefaults.baseURL + "" + media + "/" + (recentChat.profileImage ?? "") + "?mf=" + "" + FlyDefaults.authtoken)"
        let url = URL(string: urlString)
        var placeHolder = UIImage()
        if recentChat.profileType == .groupChat {
            placeHolder = UIImage(named: ImageConstant.ic_group_small_placeholder) ?? UIImage()
        } else if recentChat.isDeletedUser || getIsBlockedByMe(jid: recentChat.jid) {
            placeHolder = UIImage(named: "ic_profile_placeholder") ?? UIImage()
        } else {
            placeHolder = getPlaceholder(name: name, color: color)
        }
        
        if recentChat.isBlockedByAdmin || getIsBlockedByMe(jid: recentChat.jid) {
            profileImageView?.image = placeHolder
        } else {
            profileImageView?.sd_setImage(with: url, placeholderImage: placeHolder)
        }
    }
    
    func setSingleChatImage(imageURL: String, name: String, color: UIColor , recentChat : RecentChat) {
        var placeHolder = UIImage()
        placeHolder = getPlaceholder(name: name, color: color)
        let urlString = "\(FlyDefaults.baseURL + "" + media + "/" + imageURL + "?mf=" + "" + FlyDefaults.authtoken)"
        var url = URL(string: urlString)
        if recentChat.isDeletedUser || getIsBlockedByMe(jid: recentChat.jid) {
            placeHolder = UIImage(named: "ic_profile_placeholder") ?? UIImage()
            profileImageView?.sd_setImage(with: nil, placeholderImage: placeHolder)
        } else {
            profileImageView?.sd_setImage(with: URL(string: ""), placeholderImage: placeHolder)
        }
        
        if recentChat.isBlockedByAdmin || getIsBlockedByMe(jid: recentChat.jid){
            placeHolder = UIImage(named: "ic_profile_placeholder") ?? UIImage()
            profileImageView?.image = placeHolder
        } else {
            profileImageView?.sd_setImage(with: url, placeholderImage: placeHolder)
        }
    }
    
    func getPlaceholder(name: String , color: UIColor)->UIImage {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let ipimage = IPImage(text: trimmedName, radius: Double(profileImageView?.frame.size.height ?? 0.0), font: UIFont.font32px_appBold(), textColor: nil, color: color)
        let placeholder = ipimage.generateInitialImage()
        return placeholder ?? #imageLiteral(resourceName: "ic_profile_placeholder")
    }
    
    func imageWith(name: String?,color: UIColor) -> UIImage? {
           let frame = CGRect(x: 0, y: 0, width: 50, height: 50)
           let nameLabel = UILabel(frame: frame)
           nameLabel.textAlignment = .center
           nameLabel.backgroundColor = color
           nameLabel.textColor = .white
           nameLabel.font = UIFont.boldSystemFont(ofSize: 20)
           var initials = ""
        if let initialsArray = name?.components(separatedBy: " ") {
               if let firstWord = initialsArray.first {
                   if let firstLetter = firstWord.first {
                       initials += String(firstLetter).capitalized }
               }
               if initialsArray.count > 1, let lastWord = initialsArray.last {
                   if let lastLetter = lastWord.first { initials += String(lastLetter).capitalized
                   }
               }
           } else {
               return nil
           }
           nameLabel.text = initials
           UIGraphicsBeginImageContext(frame.size)
           if let currentContext = UIGraphicsGetCurrentContext() {
               nameLabel.layer.render(in: currentContext)
               let nameImage = UIGraphicsGetImageFromCurrentImageContext()
               return nameImage
           }
           return nil
       }
    
    // MARK: SetTextColor whileSearch
    func setTextColorWhileSearch(searchText: String,recentChat: RecentChat) {
        let name = getUserName(jid: recentChat.jid,name: recentChat.profileName , nickName: recentChat.nickName, contactType: (recentChat.isDeletedUser ? .deleted :  recentChat.isItSavedContact ? .live : .unknown))
        if let range = name.capitalized.range(of: searchText.trim().capitalized, options: [.caseInsensitive, .diacriticInsensitive]) {
            let convertedRange = NSRange(range, in: name.capitalized)
            let attributedString = NSMutableAttributedString(string: name.capitalized)
            attributedString.setAttributes([NSAttributedString.Key.foregroundColor: UIColor.systemBlue], range: convertedRange)
            userNameLabel?.attributedText = attributedString
        } else {
            userNameLabel?.text = name.capitalized.isEmpty ? name.capitalized : name.capitalized
            userNameLabel?.textColor = Color.userNameTextColor
        }
    }
    
    func setLastContentTextColor(searchText: String,recentChat: RecentChat, caption : String = "") {
        if let range = recentChat.lastMessageContent.capitalized.range(of: searchText.trim().capitalized, options: [.caseInsensitive, .diacriticInsensitive]) {
            let convertedRange = NSRange(range, in: recentChat.lastMessageContent.capitalized)
            let attributedString = NSMutableAttributedString(string: recentChat.lastMessageContent.capitalized)
            attributedString.setAttributes([NSAttributedString.Key.foregroundColor: UIColor.systemBlue], range: convertedRange)
            userMessageLabel?.attributedText = attributedString
        } else if caption.isNotEmpty {
            if let range = caption.capitalized.range(of: searchText.trim().capitalized, options: [.caseInsensitive, .diacriticInsensitive]) {
                let convertedRange = NSRange(range, in: caption.capitalized)
                let attributedString = NSMutableAttributedString(string: caption.capitalized)
                attributedString.setAttributes([NSAttributedString.Key.foregroundColor: UIColor.systemBlue], range: convertedRange)
                userMessageLabel?.attributedText = attributedString
            }
        } else {
            userMessageLabel?.text = recentChat.lastMessageContent
            userMessageLabel?.textColor = Color.userStatusTextColor
        }
    }

    
    // MARK: SetContactInformation
    func setContactInfo(recentChat: RecentChat,color : UIColor) {
        countView?.isHidden = true
        statusImage?.isHidden = true
        receiverMessageTypeView?.isHidden = true
        chatTimeLabel?.isHidden = true
        statusImageCons?.constant = 0
        receivedMessageTrailingCons?.constant = 0
        statusViewTralingCons?.constant = 0
        setImage(imageURL: recentChat.profileImage ?? "", name: getUserName(jid : recentChat.jid,name: recentChat.profileName, nickName: recentChat.nickName, contactType: recentChat.isItSavedContact ? .live : .unknown), color: color, recentChat: recentChat)
    }
    
    // MARK: Set ChatTimeColor
    func setChatTimeTextColor(lastMessageTime: Double,unreadCount: Int?) {
        let date = DateFormatterUtility.shared.convertMillisecondsToDateTime(milliSeconds: lastMessageTime)
        let secondsAgo = Int(Date().timeIntervalSince(date))
        let minute = 60
        let hour = 60 * minute
        let day = 24 * hour
        let oneDay = 1 * day
        if (secondsAgo < oneDay && (unreadCount ?? 0) > 0) {
            chatTimeLabel?.textColor = Color.recentChaTimeBlueColor
        } else {
            chatTimeLabel?.textColor = Color.recentChatDateTimeColor
        }
    }
    
    func setRecentChatMessage(recentChatMessage: RecentChat,color : UIColor,chatMessage: ChatMessage?,senderName: String, fromArchive: Bool, forSearch : Bool = false) {
        countLabel?.isHidden = false
        receivedMessageTrailingCons?.constant = 5
        statusViewTralingCons?.constant = 5
        statusImageCons?.constant = 7
        senderNameLabel?.textColor = Color.primaryTextColor
        if recentChatMessage.profileType == .groupChat && senderName.isNotEmpty && (!(chatMessage?.isMessageSentByMe ?? false)) && recentChatMessage.lastMessageType != .notification && !forSearch {
            senderNameLabel?.text =  "\(senderName): "
            senderNameLabel?.isHidden = false
        } else {
            senderNameLabel?.isHidden = true
        }
        pinImageView.isHidden = !recentChatMessage.isChatPinned
        muteImageView.isHidden = !recentChatMessage.isMuted
        archivedStatusLabel.isHidden = !recentChatMessage.isChatArchived

        if fromArchive {
            muteImageView.isHidden = true
        }

        if recentChatMessage.profileType == .groupChat {
            setImage(imageURL: recentChatMessage.profileImage ?? "", name: recentChatMessage.profileName, color: color, recentChat: recentChatMessage)
        } else {
            setSingleChatImage(imageURL: recentChatMessage.profileImage ?? "", name: getUserName(jid: recentChatMessage.jid,name: recentChatMessage.profileName, nickName: recentChatMessage.nickName, contactType: recentChatMessage.isItSavedContact ? .live : .unknown), color: color, recentChat: recentChatMessage)
        }
        let messageTime = chatMessage?.messageChatType == .singleChat ? recentChatMessage.lastMessageTime : DateFormatterUtility.shared.getGroupMilliSeconds(milliSeconds: recentChatMessage.lastMessageTime)
      
        chatTimeLabel?.text = recentChatMessage.lastMessageId == "" ? "" : String().fetchMessageDate(for: messageTime)
        countLabel?.text = recentChatMessage.unreadMessageCount > 99 ? "99+" : String(recentChatMessage.unreadMessageCount)
        chatTimeLabel?.isHidden = false
        countView?.isHidden = (recentChatMessage.unreadMessageCount > 0) ? false : true
        statusImage?.isHidden = (recentChatMessage.isLastMessageSentByMe == true) ? false : true
        statusView?.isHidden = (recentChatMessage.isLastMessageSentByMe == true) ? false : true
        receiverMessageTypeView?.isHidden = false
        contentView.backgroundColor = recentChatMessage.isSelected == true ? Color.recentChatSelectionColor : .clear
        
            switch recentChatMessage.lastMessageType {
            case .text:
                receiverMessageTypeView?.isHidden = true
            case .contact:
                receiverMessageTypeImageView?.image = UIImage(named: ImageConstant.ic_rccontact)
            case .image:
                receiverMessageTypeImageView?.image = UIImage(named: ImageConstant.ic_rcimage)
            case .location:
                receiverMessageTypeImageView?.image = UIImage(named: ImageConstant.ic_rclocation)
            case .audio:
                if chatMessage?.mediaChatMessage?.audioType == AudioType.recording {
                    ChatUtils.setIconForAudio(imageView: receiverMessageTypeImageView, chatMessage: chatMessage)
                } else {
                    receiverMessageTypeImageView?.image = UIImage(named: ImageConstant.ic_rcaudio)
                }
            case .video:
                receiverMessageTypeImageView?.image = UIImage(named: ImageConstant.ic_rcvideo)
            case .document:
                receiverMessageTypeImageView?.image = UIImage(named: ImageConstant.ic_rcdocument)
            default:
                receiverMessageTypeView?.isHidden = true
            }
    
        switch recentChatMessage.isLastMessageSentByMe {
        case true:
            // show hide sent and received msg status
            switch recentChatMessage.lastMessageStatus {
            case .notAcknowledged:
                statusImage?.image = UIImage(named: ImageConstant.ic_hour)
                break
            case .sent:
                switch recentChatMessage.lastMessageType {
                case .video, .audio, .image,.text,.contact, .document:
                    statusImage?.image = UIImage(named: ImageConstant.ic_hour)
                default:
                    statusImage?.image = UIImage(named: ImageConstant.ic_sent)
                }
                break
            case .acknowledged:
                statusImage?.image = UIImage(named: ImageConstant.ic_sent)
                break
            case .delivered:
                statusImage?.image = UIImage(named: ImageConstant.ic_delivered)
                break
            case .seen:
                statusImage?.image = UIImage(named: ImageConstant.ic_seen)
                break
            case .received:
                statusImage?.image = UIImage(named: ImageConstant.ic_delivered)
                break
            default:
                statusImage?.image = UIImage(named: ImageConstant.ic_hour)
                break
            }
            case false:
            statusImage?.isHidden = true
        }
        
        // show send messageType
        switch recentChatMessage.lastMessageType {
        case .text:
            if recentChatMessage.lastMessageContent.isEmpty == true {
                statusImage?.isHidden = true
            }
            break
        case .video, .image,.audio,.contact,.location:
            userMessageLabel?.text = (chatMessage?.mediaChatMessage?.mediaCaptionText.trim().isNotEmpty ?? false) ? chatMessage?.mediaChatMessage?.mediaCaptionText : recentChatMessage.lastMessageType?.rawValue.capitalized
        case .document:
            userMessageLabel?.text = "Document"
        default:
            break
        }
        if recentChatMessage.isLastMessageRecalledByUser {
            userMessageLabel?.text = recentChatMessage.isLastMessageSentByMe ? senderDeletedMessage : receiverDeletedMessage
            statusView?.isHidden = true
            receiverMessageTypeView?.isHidden = true
            if recentChatMessage.profileType == .groupChat && !recentChatMessage.isLastMessageSentByMe {
                senderNameLabel?.isHidden = false
            } else {
                senderNameLabel?.isHidden = true
            }
        }
    }
}
