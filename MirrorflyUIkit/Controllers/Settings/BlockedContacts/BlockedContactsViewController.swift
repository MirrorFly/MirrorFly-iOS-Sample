//
//  BlockedContactsViewController.swift
//  UiKitQa
//
//  Created by Amose Vasanth on 24/11/22.
//

import UIKit
import FlyCore
import FlyCommon

class BlockedContactsViewController: UIViewController {


    @IBOutlet weak var blockedContactsTableView: UITableView! {
        didSet {
            blockedContactsTableView.register(UINib(nibName: "BlockedContactTableViewCell", bundle: nil), forCellReuseIdentifier: "BlockedContactTableViewCell")
        }
    }

    var blockedList = [ProfileDetails]()

    override func viewDidLoad() {
        super.viewDidLoad()

        ContactManager.shared.getUsersIBlocked(fetchFromServer: false) { [weak self] isSuccess, error, data in
            if let blocked = data["data"] as? [ProfileDetails] {
                self?.blockedList = blocked
            }
            self?.blockedContactsTableView.reloadData()
        }
    }
    

    @IBAction func backAction(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }

    //MARK: UnBlockUser
    private func unblockUser(contact: ProfileDetails) {
        let name = FlyUtils.getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType)
        BlockUnblockViewModel.unblockUser(jid: contact.jid) { [weak self] isSuccess, error, data in
            if isSuccess {
                self?.blockedList.removeAll { detail in
                    detail.jid == contact.jid
                }
                self?.blockedContactsTableView.reloadData()
                AppAlert.shared.showToast(message: "\(name) has been Unblocked")
            }
        }
    }

}

extension BlockedContactsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return blockedList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "BlockedContactTableViewCell") as? BlockedContactTableViewCell {
            let contact = blockedList[indexPath.row]
            cell.setupCell(contact: contact)
            return cell
        } else {
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var actions: [(String, UIAlertAction.Style)] = [(ChatActions.unblock.rawValue, .default)]
        let contact = blockedList[indexPath.row]
        AppActionSheet.shared.showActionSeet(title : "", message: "\(ChatActions.unblock.rawValue) \(FlyUtils.getUserName(jid: contact.jid, name: contact.name, nickName: contact.nickName, contactType: contact.contactType))?",actions: actions , sheetCallBack: { [weak self] didCancelTap, tappedTitle in
            if !didCancelTap {
                if let contact = self?.blockedList[indexPath.row] {
                    self?.unblockUser(contact: contact)
                }
            }
        })
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }


}
