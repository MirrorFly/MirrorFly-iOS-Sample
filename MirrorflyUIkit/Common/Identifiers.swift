//
//  Identifiers.swift
//  commonDemo
//
//  Created by User on 13/08/21.
//

import Foundation

//MARK: - Identifiers
enum Identifiers {
    
    //MARK: - Profile Identifiers
    static let profileImageFullView = "profileImageFullView"
    static let editStatusView = "editStatusView"
    static let statusCell = "statusCell"
    
    static let contactTableViewCell = "ContactTableViewCell"
    static let verifyOTPViewController = "VerifyOTPViewController"
    static let mainTabBarController = "MainTabBarController"
    static let country = "CountryCell"
    static let countryPicker = "CountryPicker"
    static let noContacts = "NoContacts"
    static let contactCell = "ContactCell"
    static let contactViewController = "ContactViewController"
    
    //MARK: - Chat
    static let chatTextView =  "ChatTextView"
    static let chatViewTextIncomingCell = "ChatViewTextIncomingCell"
    static let chatViewTextOutgoingCell = "ChatViewTextOutgoingCell"
    static let otpNextToProfile = "otpNextToProfile"
    static let chatViewParentController = "ChatViewParentController"
    static let deleteChatAlert = "DeleteAlertViewController"
    
    //MARK: - Image
    static let imageEditController = "ImageEditController"
    static let editImageCell = "EditImageCell"
    static let listImageCell = "ListImageCell"
    static let imageCell = "ImageCell"
    static let imagePreview = "ImagePreview"
    static let imageSender = "SenderImageCell"
    static let imageReceiverCell = "ReceiverImageCell"
    
    //MARK: - Audio
    static let audioSender = "AudioSender"
    static let audioReceiver = "AudioReceiver"
    static let audioView =  "AudioView"
    
    static let chatViewLocationIncomingCell = "ChatViewLocationIncomingCell"
    static let chatViewLocationOutgoingCell = "ChatViewLocationOutgoingCell"
    static let chatScreenToLocation = "ChatScreenToLocation"
    
    static let chatViewContactIncomingCell = "ChatViewContactIncomingCell"
    static let chatViewContactOutgoingCell = "ChatViewContactOutgoingCell"
    static let chatScreenToContact = "ChatScreenToContact"
    static let chatContactCell = "ChatContactCell"
    
    //MARK: - Recent Chat
    static let recentChatCell =  "RecentChatCell"
    static let recentChatToChatScreen = "RecentChatToChatScreen"
    
    //MARK: - Profile Update
    
    static let ncProfileUpdate =  "ncProfileUpdate"
    static let ncContactRefresh =  "ncContactRefresh"
    
    //MARK: Video
    static let videoIncomingCell = "ChatViewVideoIncomingCell"
    static let videoOutgoingCell = "ChatViewVideoOutgoingCell"
    

    //MARK: group
    static let createNewGroup = "NewGroupViewController"
    static let addParticipants = "AddParticipantsViewController"
    static let participantCell = "ParticipantCell"
    static let groupCreationPreview = "GroupCreationPreview"
    
    //MARK: notification
    static let notificationCell = "NotificationCell"
    static let noResultFound = "NoResultFoundCell"
    
    //MARK: ForwardMessage
    static let forwardCell = "ForwardTableViewCell"
    static let forwardVC = "ForwardViewController"
    
    //MARK: QrCodeScanner
    static let qrCodeScaner = "QRCodeScanner"
    static let webSettingsCell = "WebSettingsCell"
    
    //ContactInfo
    static let contactInfoCell = "ContactInfoCell"
    static let viewAllMediaCell = "ViewAllMediaCell"
    static let muteNotificationCell = "MuteNotificationCell"
    static let contactImageCell = "ContactImageCell"
    static let contactInfoViewController = "ContactInfoViewController"
    static let viewUserImageController = "ViewUserImamgeController"
    static let contactSyncController = "ContactSyncController"
    static let groupInfoViewController = "GroupInfoViewController"
    static let groupMembersTableViewCell = "GroupMembersTableViewCell"
    static let groupOptionsTableViewCell = "GroupOptionsTableViewCell"
    static let updateGroupInfoViewController = "UpdateGroupInfoViewController"
    static let groupInfoOptionsViewController = "GroupInfoOptionsViewController"
    static let groupInfoOptionsTableViewCell = "GroupInfoOptionsTableViewCell"
    
    //MARK: ChatSettings
    static let ChatSettingsTableViewCell = "ChatSettingsTableViewCell"
    static let LanguageSelectionTableViewCell = "LanguageSelectionTableViewCell"
    static let LanguageSelectionViewController = "LanguageSelectionViewController"
}

//MARK: - Storyboards
enum Storyboards {
    static let main = "Main"
    static let chat = "Chat"
    static let profile = "Profile"
}
