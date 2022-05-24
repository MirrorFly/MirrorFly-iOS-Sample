//
//  ContactImageTableViewCell.swift
//  MirrorflyUIkit
//
//  Created by John on 28/01/22.
//

import UIKit

protocol ContactImageCellDelegate: class {
    func updatedGroupName(groupName: String)
}

class ContactImageCell: UITableViewCell {
    @IBOutlet weak var backButton: UIButton?
    @IBOutlet weak var onlineStatus: UILabel?
    @IBOutlet weak var userNameLabel: UILabel?
    @IBOutlet weak var editTextField: UITextField!
    @IBOutlet weak var editButton: UIButton?
    @IBOutlet weak var editProfileButton: UIButton?
    @IBOutlet weak var userImage: UIImageView?
    
    weak var delegate: ContactImageCellDelegate? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        editTextField.delegate = self
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}

extension ContactImageCell: UITextFieldDelegate {
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        delegate?.updatedGroupName(groupName: textField.text ?? "")
    }
    
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        
        let currentCharacterCount = textField.text?.count ?? 0
        if range.length + range.location > currentCharacterCount {
            return false
        }
        let newLength = currentCharacterCount + string.count - range.length
        return newLength <= 25
    }
}
