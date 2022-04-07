//
//  ContactImageTableViewCell.swift
//  MirrorflyUIkit
//
//  Created by John on 28/01/22.
//

import UIKit

class ContactImageCell: UITableViewCell {
    @IBOutlet weak var backButton: UIButton?
    @IBOutlet weak var onlineStatus: UILabel?
    @IBOutlet weak var userNameLabel: UILabel?
    @IBOutlet weak var editButton: UIButton?
    @IBOutlet weak var userImage: UIImageView?
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        editButton?.isHidden = true
        // Configure the view for the selected state
    }
    
}
