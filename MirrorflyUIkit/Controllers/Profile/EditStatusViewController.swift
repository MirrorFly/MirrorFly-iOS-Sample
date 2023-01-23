//
//  EditStatusViewController.swift
//  MirrorflyUIkit
//
//  Created by User on 17/08/21.
//

import Foundation
import UIKit
import FlyCore
import FlyCommon
import FlyDatabase

protocol StatusDelegate: class {
    func userSelectedStatus(selectedStatus: String)
}

class EditStatusViewController: UIViewController {
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var topStatusView: UIView!
    @IBOutlet weak var editStatusScrollView: UIScrollView!
    @IBOutlet weak var typeHereLabel: UILabel!
    @IBOutlet weak var statusTextview: UITextView!
    @IBOutlet weak var editStatusTableView: UITableView!
    @IBOutlet weak var editTextButton: UIButton!
    @IBOutlet weak var okButtonView: UIView!
    @IBOutlet weak var textCountLabel: UILabel!
    @IBOutlet weak var editStatusViewBottom: NSLayoutConstraint!
    @IBOutlet weak var selectionHeaderView: UIView!

    var isUserBusyStatus = false
    
    var defaultStatus: String!
    var setstatusArray = [StatusModel]()
    weak var delegate: StatusDelegate? = nil
    var statusArray: [ProfileStatus] = []
    var busyStatusArray: [BusyStatus] = []
    var isStatusChanged: Bool = false

    var isLongPress = false
    var deleteIndexPath: IndexPath?
    
    override func viewDidLoad() {
        super.viewDidLoad()
          statusArray =   getStatus()
        busyStatusArray = getBusyStatus()
        setupUI()
        if(  statusArray.count > 0) {
              editStatusTableView.reloadData()
        }
        else {
              saveStatus()
        }
      
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
          editStatusTableView.rowHeight = UITableView.automaticDimension
          editStatusTableView.estimatedRowHeight = UITableView.automaticDimension
    }
    
    func setupUI() {

        if isUserBusyStatus {
            defaultStatus = ChatManager.shared.getMyBusyStatus().status
        }

          backgroundView.isHidden = true
          typeHereLabel.isHidden = true
          okButtonView.isHidden = true
          textCountLabel.isHidden = true
          statusTextview.delegate = self
          statusTextview.text =   defaultStatus
          statusTextview.inputAccessoryView = UIView()
          statusTextview.textInputMode?.primaryLanguage == emoji
          statusTextview.keyboardType = .default
    }
    
    func saveStatus() {
          setstatusArray = [
            StatusModel(userStatus: atTheMovies.localized, isSelected: false),
            StatusModel(userStatus: urgentCalls.localized, isSelected: false),
            StatusModel(userStatus: available.localized, isSelected: false),
            StatusModel(userStatus: sleeping.localized, isSelected: false),
            StatusModel(userStatus: inMirrorfly.localized, isSelected: true)
        ]
        for status in   setstatusArray {
            ChatManager.saveProfileStatus(statusText: status.userStatus,currentStatus: status.isSelected)
        }
        
          statusArray =   getStatus()
          editStatusTableView.reloadData()
    }
    
    func getStatus() -> [ProfileStatus] {
        let profileStatus = ChatManager.getAllStatus()
        print("Get Status Started profileList Count \(profileStatus.count)")
        return profileStatus
    }

    func getBusyStatus() -> [BusyStatus] {
        let profileStatus = ChatManager.shared.getBusyStatusList()
        print("Get Status Started profileList Count \(profileStatus.count)")
        return profileStatus
    }
    
    @objc private func keyboardDidShow(notification: Notification) {
        let keyboardInfo = notification.userInfo
        let keyboardFrameBegin = keyboardInfo?[UIResponder.keyboardFrameEndUserInfoKey]
        let keyboardFrameBeginRect = (keyboardFrameBegin as! NSValue).cgRectValue
        self.editStatusViewBottom.constant = keyboardFrameBeginRect.size.height
        let contentInset:UIEdgeInsets = UIEdgeInsets.zero
        self.editStatusScrollView.contentInset = contentInset
        self.editStatusScrollView.isScrollEnabled = false
        self.view.layoutIfNeeded()
    }
    
    @objc private func keyboardDidHide(notification: Notification) {
        self.editStatusViewBottom.constant = 0
        let contentInset:UIEdgeInsets = UIEdgeInsets.zero
        self.editStatusScrollView.contentInset = contentInset
        self.editStatusScrollView.isScrollEnabled = true
        self.view.layoutIfNeeded()
    }
   
    func newStatusView() {
          backgroundView.isHidden = false
          backgroundView.backgroundColor = Color.primaryTextColor
          backgroundView.alpha = 0.5
          topStatusView.backgroundColor = Color.primaryTextColor
          topStatusView.alpha = 0.5
          view.bringSubviewToFront(backgroundView)
          statusTextview.becomeFirstResponder()
          editTextButton.isHidden = true
          typeHereLabel.isHidden = false
          okButtonView.isHidden = false
          textCountLabel.isHidden = false
    }
}

//MARK: Button Action
extension EditStatusViewController {
    @IBAction func onEditButton(_ sender: Any) {
          newStatusView()
    }
    
    @IBAction func onBackButton(_ sender: Any) {
          navigationController?.popViewController(animated: true)
    }

    @IBAction func onDeleteBackButton(_ sender: Any) {
        updateDeleteHeaderView()
    }

    @IBAction func onDeleteButton(_ sender: Any) {
        if let indexPath = deleteIndexPath {
            showDelete(indexPath: indexPath)
        }
        updateDeleteHeaderView()
    }

    func updateDeleteHeaderView() {
        selectionHeaderView.isHidden = true
        deleteIndexPath = nil
        editStatusTableView.reloadData()
        isLongPress = false
    }
    
    @IBAction func onOkButton(_ sender: Any) {
        if isUserBusyStatus {
            if   statusTextview.text.isBlank {
                AppAlert.shared.showToast(message: busyEmptyStatus.localized)
            } else {
                if FlyDatabaseController.shared.userBusyStatusManager.saveStatus(busyStatus: BusyStatus(statusText: statusTextview.text)) {
                    ChatManager.shared.setMyBusyStatus(statusTextview.text)
                }
                navigationController?.popViewController(animated: true)
            }
        } else {
            if NetworkReachability.shared.isConnected {
                if   statusTextview.text.isBlank {
                    AppAlert.shared.showToast(message: emptyStatus.localized)
                }
                else {
                    let trimmedStatus =   statusTextview.text.trimmingCharacters(in: .whitespacesAndNewlines)

                    if(  isStatusChanged) {
                    var getAllStatus: [ProfileStatus] = []
                        getAllStatus =   getStatus()
                        for getAllStatus in   statusArray {
                        ChatManager.updateStatus(statusId: getAllStatus.id, statusText: getAllStatus.status, currentStatus: false)
                    }
                    ChatManager.saveProfileStatus(statusText: trimmedStatus, currentStatus: true)
                    }

                    delegate?.userSelectedStatus(selectedStatus: trimmedStatus)
                      navigationController?.popViewController(animated: true)
                }
            }
            else {
                AppAlert.shared.showToast(message: ErrorMessage.noInternet)
            }
        }
    }
}

//MARK: Tableview
extension EditStatusViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let label = StatusHeaderLabel()
        label.text = editStatusSectionTitle.localized
        
        let containerView = UIView()
        containerView.addSubview(label)
        label.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        label.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20).isActive = true
        return containerView
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
      return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat(statusHeader)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return  isUserBusyStatus ? busyStatusArray.count : statusArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: EditStatusTableViewCell!
        
        cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.statusCell, for: indexPath as IndexPath) as? EditStatusTableViewCell
        cell.selectionStyle = .none

        if isUserBusyStatus {
            cell.statusLabel.text =   busyStatusArray[indexPath.row].status
            if(busyStatusArray[indexPath.row].isCurrentStatus) {
                cell.selectImage.isHidden = false
                cell.statusLabel.textColor = .black
            }
            else {
                cell.statusLabel.textColor = Color.userStatusUnselectColor
                cell.selectImage.isHidden = true
            }
        } else {
            cell.statusLabel.text =   statusArray[indexPath.row].status
            if(statusArray[indexPath.row].isCurrentStatus) {
                cell.selectImage.isHidden = false
                cell.statusLabel.textColor = .black
            }
            else {
                cell.statusLabel.textColor = Color.userStatusUnselectColor
                cell.selectImage.isHidden = true
            }
        }

        if let index = deleteIndexPath, index == indexPath {
            cell.contentView.backgroundColor = Color.recentChatSelectionColor
            selectionHeaderView.isHidden = false
        } else {
            cell.contentView.backgroundColor = .clear
        }

        cell.selectButton.tag = indexPath.row
        cell.selectButton.addTarget(self, action: #selector(  onSelectStatus(sender:)), for: .touchUpInside)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(sender:)))
        tableView.addGestureRecognizer(longPress)
        
        return cell
    }
   
}
//MARK: Tableview action
extension EditStatusViewController {
    @objc private func handleLongPress(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let touchPoint = sender.location(in:   editStatusTableView)
            if let indexPath =   editStatusTableView.indexPathForRow(at: touchPoint) {
                isLongPress = true
                deleteIndexPath = indexPath
                editStatusTableView.reloadRows(at: [indexPath], with: .none)
                  //showDelete(indexPath: indexPath)
                
            }
        }
    }

    @objc private func onDeleteStatus(sender: UITapGestureRecognizer) {
        if let indexPath = deleteIndexPath {
            showDelete(indexPath: indexPath)
        }
    }
    
    func showDelete(indexPath: IndexPath) {

        if self.isUserBusyStatus == true {
            if self.busyStatusArray[indexPath.row].isCurrentStatus == true {
                return
            }
        }

        AppAlert.shared.showAlert(view: self, title: nil, message: deleteStatusAlert, buttonOneTitle: noButton, buttonTwoTitle: yesButton)
        AppAlert.shared.onAlertAction = { [weak self] (result)  ->
            Void in
            if result == 1 {
                if let status = self?.isUserBusyStatus, status == true {
                    self?.deleteBusyStatus(status: (self?.busyStatusArray[indexPath.row])!)
                    self?.busyStatusArray.remove(at: indexPath.row)
                    self?.editStatusTableView.deleteRows(at: [indexPath], with: .automatic)
                } else {
                    self?.deleteStatus(statusId: (self?.statusArray[indexPath.row].id)!)
                    self?.statusArray.remove(at: indexPath.row)
                    self?.editStatusTableView.deleteRows(at: [indexPath], with: .automatic)
                }
            }else {
                self?.deleteIndexPath = nil
                self?.editStatusTableView.reloadData()
            }
        }

//        let deleteAlert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
//        let okButton = UIAlertAction(title: deleteText.localized, style: UIAlertAction.Style.default) {
//            (result : UIAlertAction) -> Void in
//            self.dismiss(animated: true, completion: nil)
//
//            if self.isUserBusyStatus == true {
//                if self.busyStatusArray[indexPath.row].isCurrentStatus == true {
//                    return
//                }
//            }
//
//            AppAlert.shared.showAlert(view: self, title: nil, message: deleteStatusAlert, buttonOneTitle: noButton, buttonTwoTitle: yesButton)
//            AppAlert.shared.onAlertAction = { [weak self] (result)  ->
//                Void in
//                if result == 1 {
//                    if let status = self?.isUserBusyStatus, status == true {
//                        self?.deleteBusyStatus(status: (self?.busyStatusArray[indexPath.row])!)
//                        self?.busyStatusArray.remove(at: indexPath.row)
//                        self?.editStatusTableView.deleteRows(at: [indexPath], with: .automatic)
//                    } else {
//                        self?.deleteStatus(statusId: (self?.statusArray[indexPath.row].id)!)
//                        self?.statusArray.remove(at: indexPath.row)
//                        self?.editStatusTableView.deleteRows(at: [indexPath], with: .automatic)
//                    }
//                }else {
//
//                }
//            }
//        }
//        deleteAlert.addAction(okButton)
//          present(deleteAlert, animated: true) {
//            deleteAlert.view.superview?.isUserInteractionEnabled = true
//            deleteAlert.view.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.alertControllerBackgroundTapped)))
//        }
    }

    func deleteStatus(statusId: String) {
       ChatManager.deleteStatus(statusId: statusId)
    }

    func deleteBusyStatus(status: BusyStatus) {
        ChatManager.shared.deleteBusyStatus(status)
    }
    
    @objc func alertControllerBackgroundTapped()
    {
          dismiss(animated: true, completion: nil)
    }
    
    @objc func onSelectStatus(sender : UIButton) {

        if isLongPress {
            deleteIndexPath = IndexPath(row: sender.tag, section: 0)
            editStatusTableView.reloadData()
        } else {
            if isUserBusyStatus {

                let indexRow = sender.tag
                for i in 0..<busyStatusArray.count {
                    busyStatusArray[i].isCurrentStatus = false
                }
                busyStatusArray[indexRow].isCurrentStatus = true
                editStatusTableView.reloadData()
                statusTextview.text =   busyStatusArray[indexRow].status

                ChatManager.shared.setMyBusyStatus(statusTextview.text)
            } else {
                if NetworkReachability.shared.isConnected {
                    let indexRow = sender.tag
                    for i in 0..<statusArray.count {
                        statusArray[i].isCurrentStatus = false
                    }
                    statusArray[indexRow].isCurrentStatus = true
                    editStatusTableView.reloadData()
                    statusTextview.text =   statusArray[indexRow].status
                    delegate?.userSelectedStatus(selectedStatus:   statusArray[indexRow].status)

                    var getAllStatus: [ProfileStatus] = []
                    getAllStatus =   getStatus()
                    for getAllStatus in   statusArray {
                        if(getAllStatus.id ==   statusArray[indexRow].id) {
                            ChatManager.updateStatus(statusId:   statusArray[indexRow].id ,statusText:   statusArray[indexRow].status,currentStatus: true)
                        }
                        else{
                            ChatManager.updateStatus(statusId: getAllStatus.id, statusText: getAllStatus.status, currentStatus: false)
                        }
                    }
                }
                else {
                    AppAlert.shared.showToast(message: ErrorMessage.noInternet)
                }
            }
        }
    }
}

//MARK: TextViewDelegate
extension EditStatusViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
          textCountLabel.text = "\(editStatusTextMaxLength - textView.text.count)"
          newStatusView()
          typeHereLabel.text = ""
    }
    func textViewDidEndEditing(_ textView: UITextView) {
          backgroundView.isHidden = true
          topStatusView.backgroundColor = Color.navigationColor
          view.sendSubviewToBack(  backgroundView)
          typeHereLabel.isHidden = true
          okButtonView.isHidden = true
          textCountLabel.isHidden = true
          editTextButton.isHidden = false
    }
    
    func textViewDidChange(_ textView: UITextView) {
          isStatusChanged = true
          textCountLabel.text = "\(editStatusTextMaxLength - textView.text.count)"
//        if textView.text.last == "\n" {
//            textView.resignFirstResponder()
//        }
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (text == "\n") {
            textView.resignFirstResponder()
            return true
        }
        if text.count > 1 {
            let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
            return newText.count <= editStatusTextMaxLength;
          } else {
            return textView.text.count + (text.count - range.length) <= editStatusTextMaxLength
          }
    }
}

