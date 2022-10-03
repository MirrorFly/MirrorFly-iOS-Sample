//
//  GroupMembersTableViewCell.swift
//  MirrorflyUIkit
//
//  Created by Prabakaran M on 03/03/22.
//

import UIKit
import FlyCommon
import SDWebImage

class GroupMembersTableViewCell: UITableViewCell {
    
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var nickNameLabel: UILabel!
    @IBOutlet weak var adminLabel: UILabel!
    var isAdminMember: Bool = false
    
    var profileDetails: ProfileDetails!
    let groupInfoViewModel = GroupInfoViewModel()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.separatorInset = UIEdgeInsets(top: 0, left: 64, bottom: 0, right: 19)
        userImageView.layer.cornerRadius = 20
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
    
    func getGroupInfo(groupInfo: GroupParticipantDetail) {
        nickNameLabel.text = ""
        
        let userName = getUserName(jid : groupInfo.profileDetail?.jid ?? "", name: groupInfo.profileDetail?.name ?? "", nickName: groupInfo.profileDetail?.nickName ?? "", contactType: groupInfo.profileDetail?.contactType ?? .unknown)
        let imageURL = groupInfo.profileDetail?.image ?? ""
        
        nameLabel.text = userName
        statusLabel.text = groupInfo.profileDetail?.status
        userImageView?.loadFlyImage(imageURL: imageURL, name: userName,
                                    chatType: groupInfo.profileDetail?.profileChatType ?? .singleChat, jid: groupInfo.profileDetail?.jid ?? "")
        
        if groupInfo.memberJid == FlyDefaults.myJid {
            nameLabel.text = "You"
            nickNameLabel.text = ""
            userImageView?.loadFlyImage(imageURL: FlyDefaults.myImageUrl, name: "",
                                        chatType: groupInfo.profileDetail?.profileChatType ?? .singleChat,
                                        uniqueId: FlyDefaults.myJid, jid: groupInfo.profileDetail?.jid ?? "")
        }
        
        let profileDetails = groupInfoViewModel.checkContactType(participantJid: groupInfo.memberJid)
        self.profileDetails = profileDetails
        
        if self.profileDetails?.contactType == .unknown {
            nickNameLabel.text = ("\("~")\(groupInfo.profileDetail?.name ?? "")")
        }
        
        if groupInfo.isAdminMember == true {
            adminLabel.text = "Admin"
        } else {
            adminLabel.text = ""
        }
    }
    
    func getPlaceholder(name: String, color: UIColor) -> UIImage {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let ipimage = IPImage(text: trimmedName,
                              radius: Double(userImageView.frame.size.height),
                              font: UIFont.font32px_appBold(), textColor: nil, color: color)
        let placeholder = ipimage.generateInitialImage()
        return placeholder ?? #imageLiteral(resourceName: "ic_profile_placeholder")
    }
}
