//
//  BaseTableViewCell.swift
//  MirrorflyUIkit
//
//  Created by Sowmiya T on 06/12/21.
//

import UIKit


class BaseTableViewCell: UITableViewCell {
    var delegate: TableViewCellDelegate?
    var currentIndexPath: IndexPath?
    var isAllowSwipe: Bool? = false
    var swiperight : UISwipeGestureRecognizer?
    override func awakeFromNib() {
        super.awakeFromNib()
        setupGestures()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    func setupGestures() {
        swiperight = UISwipeGestureRecognizer(target: self, action: #selector(handleRightSwipe(_:)))
        swiperight?.direction = UISwipeGestureRecognizer.Direction.right
        
        if let swipe = swiperight {
            contentView.addGestureRecognizer(swipe)
        }
        contentView.isUserInteractionEnabled = true
    }

    @objc func handleRightSwipe(_ recognizer: UISwipeGestureRecognizer) {
        if isAllowSwipe == true {
            DispatchQueue.main.async { [weak self] in
                UIView.animate(withDuration: 0.5) {
                    self?.contentView.transform = CGAffineTransform(translationX: -(200) , y: 0)
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) { [weak self] in
                self?.delegate?.openBottomView(indexPath: self?.currentIndexPath ?? IndexPath())
                self?.contentView.transform = CGAffineTransform(translationX: 0 , y: 0)
            }
        }
    }
}
