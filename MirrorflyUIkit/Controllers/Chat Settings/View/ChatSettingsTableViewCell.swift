//
//  ChatSettingsTableViewCell.swift
//  UiKitQa
//
//  Created by User on 11/04/22.
//
import UIKit

class ChatSettingsTableViewCell: UITableViewCell {

    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var helpTextLabel: UILabel!
    @IBOutlet weak var selectedImageView: UIImageView!
    @IBOutlet weak var helpTextView: UIView!
    @IBOutlet weak var ChooseLangugaeLabel: UILabel!
    @IBOutlet weak var defaultLanguageLabel: UILabel!
    @IBOutlet weak var doubleTapLabel: UILabel!
    @IBOutlet weak var formaImageView: UIImageView!
     
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
        
}

