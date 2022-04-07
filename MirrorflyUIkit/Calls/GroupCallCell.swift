//
//  GroupCallCollectionViewCell.swift
//  GroupCallUI
//
//  Created by Vasanth Kumar on 19/05/21.
//

import UIKit
import WebRTC

class GroupCallCell: UICollectionViewCell {
    
    static let identifier = "GroupCallCell"
    
    @IBOutlet weak var contentVIew: UIView!
    @IBOutlet var profileImage: UIImageView!
    @IBOutlet var profileName: UILabel!
    @IBOutlet var foreGroundView: UIView!
    @IBOutlet var statusLable: UILabel!
    @IBOutlet var audioIconImageView: UIImageView!
    @IBOutlet weak var videoView: RTCMTLVideoView!
    @IBOutlet weak var callActionsView: UIView!
    @IBOutlet weak var videoViewLeading: NSLayoutConstraint!
    @IBOutlet weak var videoViewTrailing: NSLayoutConstraint!
    @IBOutlet weak var profileImageLeading: NSLayoutConstraint!
    @IBOutlet weak var profileImageTrailing: NSLayoutConstraint!
    
    override class func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func prepareForReuse() {
        profileImage.image = nil
        super.prepareForReuse()
    }
}
