//
//  GroupMembersTableViewCell.swift
//  MirrorflyUIkit
//
//  Created by Prabakaran M on 03/03/22.
//

import UIKit
import FlyCore
import FlyCommon
import SDWebImage

class GroupMembersTableViewCell: UITableViewCell {
    
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var adminLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        userImageView.layer.cornerRadius = 20
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
    
    func getGroupInfo(groupInfo: GroupParticipantDetail) {
        
        nameLabel.text = getUserName(name: groupInfo.profileDetail?.name ?? "", nickName: groupInfo.profileDetail?.nickName ?? "")
        statusLabel.text = groupInfo.profileDetail?.status
        
        let imageURL = groupInfo.profileDetail?.image ?? ""
        let urlString = FlyDefaults.baseURL + "media/" + imageURL + "?mf=" + FlyDefaults.authtoken
        let url = URL(string: urlString)
        let color = getColor(userName: groupInfo.profileDetail?.name ?? "")
        
        userImageView.sd_setImage(with: url,
                                  placeholderImage: getPlaceholder(
                                    name: groupInfo.profileDetail?.name ?? "",
                                    color: color))
        
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
