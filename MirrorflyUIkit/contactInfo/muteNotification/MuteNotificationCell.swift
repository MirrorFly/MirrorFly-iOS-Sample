//
//  MuteNotificationCell.swift
//  MirrorflyUIkit
//
//  Created by John on 28/01/22.
//

import UIKit

class MuteNotificationCell: UITableViewCell {

    @IBOutlet weak var muteSwitch: UISwitch?
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
