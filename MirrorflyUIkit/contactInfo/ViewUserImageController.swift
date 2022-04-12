//
//  ViewUserImamgeController.swift
//  MirrorflyUIkit
//
//  Created by John on 31/01/22.
//

import UIKit
import FlyCommon
import SDWebImage

class ViewUserImageController: ViewController {
   
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var closeButton: UIButton?
    @IBOutlet weak var userImage: UIImageView?
    var profileDetails : ProfileDetails?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
        setInformation()
        // Do any additional setup after loading the view.
    }
    
    private func setUpUI() {
        setUpStatusBar()
    }
    
    private func setInformation() {
        let name = getUserName(name: profileDetails?.name ?? "", nickName: profileDetails?.nickName ?? "")
        let placeholder = ChatUtils.getPlaceholder(name: profileDetails?.name ?? "", userColor: ChatUtils.getColorForUser(userName: name), userImage: userImage ?? UIImageView())
        let imageUrl = profileDetails?.image  ?? ""
        userImage?.sd_setImage(with: ChatUtils.getUserImaeUrl(imageUrl: imageUrl), placeholderImage: placeholder)
        
        titleLabel?.text = name
    }
    
    @IBAction func onClose(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    

}
