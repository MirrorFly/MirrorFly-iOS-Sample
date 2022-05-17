//
//  UILabelExtension.swift
//  MirrorflyUIkit
//
//  Created by John on 19/04/22.
//

import Foundation
import UIKit

extension UILabel {
    
    func underLine(text : String) {
        let underlineAttribute = [NSAttributedString.Key.underlineStyle: NSUnderlineStyle.thick.rawValue]
        let underlineAttributedString = NSAttributedString(string: text, attributes: underlineAttribute)
        self.attributedText = underlineAttributedString
    }
    
    
}
