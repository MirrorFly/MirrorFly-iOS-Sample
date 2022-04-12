//
//  GroupInfoViewController.swift
//  MirrorflyUIkit
//
//  Created by Prabakaran M on 03/03/22.
//

import UIKit
import Foundation
import AVFoundation
import FlyCommon
import SDWebImage
import FlyCore
import Toaster
import MobileCoreServices
import Photos
import Toaster
import Tatsi
import QCropper

class GroupInfoViewController: UIViewController {
    
    // MARK: Properties
    
    @IBOutlet weak var tableView: UITableView!
    
    let groupInfoViewModel = GroupInfoViewModel()
    
    var profileDetails : ProfileDetails?
    var groupID = ""
    var updatedGroupName = ""
    var groupMembers = [GroupParticipantDetail]()
    let contactInfoViewModel = ContactInfoViewModel()
    var getProfileDetails: ProfileDetails!
    
    let imagePickerController = UIImagePickerController()
    var isImagePicked: Bool = false
    var previewImage: UIImage!
    var profileImage: UIImageView?
    var profileImageLocalPath = String()
    var lastSelectedCollection: PHAssetCollection?
    
    var firstView: TatsiConfig.StartView {
        if let lastCollection = self.lastSelectedCollection {
            return .album(lastCollection)
        } else {
            return .userLibrary
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpUI()
        setupConfiguration()
        getGroupMembers()
        getParticipants()
        print(groupID, "groupID")
    }
    
    private func setUpUI() {
        setUpStatusBar()
        navigationController?.navigationBar.isHidden = true
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView?.register(UINib(nibName: Identifiers.contactImageCell, bundle: .main),
                            forCellReuseIdentifier: Identifiers.contactImageCell)
        tableView?.register(UINib(nibName: Identifiers.contactInfoCell, bundle: .main),
                            forCellReuseIdentifier: Identifiers.contactInfoCell)
        tableView?.register(UINib(nibName: Identifiers.muteNotificationCell, bundle: .main),
                            forCellReuseIdentifier: Identifiers.muteNotificationCell)
        tableView?.register(UINib(nibName: Identifiers.groupOptionsTableViewCell, bundle: .main),
                            forCellReuseIdentifier: Identifiers.groupOptionsTableViewCell)
        tableView?.register(UINib(nibName: Identifiers.groupMembersTableViewCell, bundle: .main),
                            forCellReuseIdentifier: Identifiers.groupMembersTableViewCell)
    }
    
    private func setupConfiguration() {
        ContactManager.shared.profileDelegate = self
        if groupID.isNotEmpty {
            profileDetails = groupInfoViewModel.getContactInfo(jid: groupID)
        }
    }
    
    private func refreshData() {
        tableView?.reloadData()
    }
    
    private func updateGroupProfileImage(selectedImage: UIImage) {
        let indexPath = IndexPath(row: 0, section: 0)
        if let cell = tableView?.cellForRow(at: indexPath) as? ContactImageCell {
            cell.userImage?.image = selectedImage
        }
    }
    
    // MARK: User Intractions
    
    @objc
    func didTapBack(sender : Any) {
        navigationController?.navigationBar.isHidden = false
        navigationController?.popViewController(animated: true)
    }
    
    @objc
    func didTapImage(sender : Any) {
        if let image = profileDetails?.image, image.isNotEmpty {
            performSegue(withIdentifier: Identifiers.viewUserImageController, sender: self)
        }
    }
    
    @objc
    func stateChanged(switchState: UISwitch) {
        if switchState.isOn {
            groupInfoViewModel.muteNotification(jid: groupID, mute: true)
        } else {
            groupInfoViewModel.muteNotification(jid: groupID, mute: false)
        }
    }
    
    @objc
    func updateGroupProfileAction(sender: Any) {
        showActionSheet()
    }
    
    @objc
    func updateGroupNameAction(sender: Any) {
        let storyboard = UIStoryboard.init(name: Storyboards.chat, bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: Identifiers.updateGroupInfoViewController) as! UpdateGroupInfoViewController
        controller.groupName = getUserName(name: profileDetails?.name ?? "",
                                           nickName: profileDetails?.nickName ?? "")
        controller.delegate = self
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Identifiers.viewUserImageController {
            let viewUserImageVC = segue.destination as! ViewUserImageController
            viewUserImageVC.profileDetails = profileDetails
        }
    }
    
    // MARK: Private Methods
    
    func getGroupMembers() {
        groupMembers = [GroupParticipantDetail]()
        groupMembers = GroupManager.shared.getGroupMemeberFromLocal(groupJid:  groupID).participantDetailArray
        print("getGrouMember \(groupMembers.count)")
        refreshData()
    }
    
    func getParticipants() {
        GroupManager.shared.getParticipants(groupJID: groupID)
    }
    
    //MARK: Remove Profile Image
    
    func removeProfileImage(fileUrl : String){
        if NetworkReachability.shared.isConnected {
            AppAlert.shared.showToast(message: profilePictureRemoved.localized)
            ContactManager.shared.removeProfileImage( completionHandler: { isSuccess, flyError, flyData in
                var data  = flyData
                if isSuccess {
                    print(data.getMessage() as! String)
                    FlyDefaults.myProfileImageUrl = ""
                } else {
                    print(data.getMessage() as! String)
                }
            })
        } else {
            AppAlert.shared.showToast(message: ErrorMessage.noInternet)
        }
    }
}

extension GroupInfoViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 2 {
            return groupMembers.count
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            let cell = (tableView.dequeueReusableCell(withIdentifier: Identifiers.contactImageCell,
                                                      for: indexPath) as? ContactImageCell)!
            
            _ = (profileDetails?.name.isEmpty ?? false) ?
            profileDetails?.nickName : profileDetails?.name
            cell.userNameLabel?.text = getUserName(name: profileDetails?.name ?? "",
                                                   nickName: profileDetails?.nickName ?? "")
            let imageUrl = profileDetails?.image ?? ""
            cell.userImage?.sd_setImage(with: ChatUtils.getUserImaeUrl(imageUrl: imageUrl),
                                        placeholderImage: UIImage(named: "ic_groupPlaceHolder"))
            
            let gestureRecognizer = UITapGestureRecognizer(target: self,
                                                           action: #selector(didTapImage(sender:)))
            cell.userImage?.isUserInteractionEnabled = true
            cell.userImage?.addGestureRecognizer(gestureRecognizer)
            cell.editButton?.isHidden = false
            cell.editProfileButton?.isHidden = false
            
            cell.backButton?.addTarget(self, action: #selector(didTapBack(sender:)),
                                       for: .touchUpInside)
            cell.editProfileButton?.addTarget(self,
                                              action: #selector(updateGroupProfileAction(sender:)),
                                              for: .touchUpInside)
            cell.editButton?.addTarget(self,
                                       action: #selector(updateGroupNameAction(sender:)),
                                       for: .touchUpInside)
            return cell
            
//        } else if indexPath.section == 1 {
//            let cell = (tableView.dequeueReusableCell(withIdentifier: Identifiers.muteNotificationCell,
//                                                      for: indexPath) as? MuteNotificationCell)!
//            cell.muteSwitch?.addTarget(self, action: #selector(stateChanged), for: .valueChanged)
//            cell.muteSwitch?.setOn(profileDetails?.isMuted ?? false, animated: true)
//            return cell
//
        } else if indexPath.section == 1 {
            let cell = (tableView.dequeueReusableCell(withIdentifier: Identifiers.groupOptionsTableViewCell, for: indexPath) as? GroupOptionsTableViewCell)!
            cell.optionImageview.image = UIImage(named: "add_user")
            cell.optionLabel.textColor = Color.userNameTextColor
            cell.optionLabel.text = "Add Participants"
            return cell
            
        } else if indexPath.section == 2 {
            let groupMembers = groupMembers[indexPath.row]
            let cell = (tableView.dequeueReusableCell(withIdentifier: Identifiers.groupMembersTableViewCell, for: indexPath) as? GroupMembersTableViewCell)!
            cell.getGroupInfo(groupInfo: groupMembers)
            return cell
        } else if indexPath.section == 3 {
            let cell = (tableView.dequeueReusableCell(withIdentifier: Identifiers.groupOptionsTableViewCell, for: indexPath) as? GroupOptionsTableViewCell)!
            cell.optionImageview.image = UIImage(named: "leave_group")
            cell.optionLabel.textColor = Color.leaveGroupTextColor
            cell.optionLabel.text = "Leave Group"
            return cell
            
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 1 {
            let storyboard = UIStoryboard.init(name: Storyboards.main, bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: Identifiers.addParticipants) as! AddParticipantsViewController
            controller.isFromGroupInfo = true
            controller.groupID = groupID
            controller.delegate = self
            self.navigationController?.pushViewController(controller, animated: true)
        } else if indexPath.section == 3 {
            let storyboard = UIStoryboard.init(name: Storyboards.chat, bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: Identifiers.groupInfoOptionsViewController) as! GroupInfoOptionsViewController
            controller.modalPresentationStyle = .overCurrentContext
            controller.modalTransitionStyle = .crossDissolve
            controller.delegate = self
            controller.groupID = groupID
            controller.userJid = groupMembers[indexPath.row].memberJid
            self.present(controller, animated: true, completion: nil)
        }
    }
}

extension GroupInfoViewController: UpdateGroupNameDelegate {
    func updatedGroupName(groupName: String) {
        startLoading(withText: pleaseWait)
        try! GroupManager.shared.updateGroupName(groupJid: groupID, groupName: groupName) { [weak self] isSuccess,error,data in
            if isSuccess {
                self?.setupConfiguration()
                self?.refreshData()
            }
            self?.stopLoading()
            print("groupName", groupName)
        }
    }
}

extension GroupInfoViewController: AddParticipantsDelegate {
    func updatedAddParticipants() {
        getGroupMembers()
        refreshData()
    }
}

extension GroupInfoViewController: GroupInfoOptionsDelegate {
    func makeGroupAdmin() {
        getGroupMembers()
        refreshData()
    }
}

extension GroupInfoViewController: ProfileEventsDelegate {
    
    func userCameOnline(for jid: String) {
        
    }
    
    func userWentOffline(for jid: String) {
        
    }
    
    func userProfileFetched(for jid: String, profileDetails: ProfileDetails?) {
        
    }
    
    func myProfileUpdated() {
        
    }
    
    func usersProfilesFetched() {
        
    }
    
    func blockedThisUser(jid: String) {
        
    }
    
    func unblockedThisUser(jid: String) {
        
    }
    
    func usersIBlockedListFetched(jidList: [String]) {
        
    }
    
    func usersBlockedMeListFetched(jidList: [String]) {
        
    }
    
    func userUpdatedTheirProfile(for jid: String, profileDetails: ProfileDetails) {
        if jid ==  groupID {
            self.profileDetails = profileDetails
            refreshData()
        }
    }
    
    func userBlockedMe(jid: String) {
        
    }
    
    func userUnBlockedMe(jid: String) {
        
    }
    
    func hideUserLastSeen() {
        
    }
    
    func getUserLastSeen() {
        
    }
}

extension GroupInfoViewController {
    
    func showActionSheet() {
        let alertAction = UIAlertController(title: nil, message:nil, preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(title: takePhoto.localized, style: .default) { [weak self] _ in
            
            if NetworkReachability.shared.isConnected {
                if UIImagePickerController.isSourceTypeAvailable(.camera){
                    self?.checkCameraPermissionAccess(sourceType: .camera)
                } else {
                    AppAlert.shared.showAlert(view: self!, title: noCamera.localized, message: noCameraMessage.localized, buttonTitle: noCamera.localized)
                }
            } else {
                AppAlert.shared.showToast(message: ErrorMessage.noInternet)
            }
        }
        
        let galleryAction = UIAlertAction(title: chooseFromGallery.localized, style: .default) { [weak self] _ in
            if NetworkReachability.shared.isConnected {
                self?.checkGalleryPermissionAccess(sourceType: .photoLibrary)
            } else {
                AppAlert.shared.showToast(message: ErrorMessage.noInternet)
            }
        }
        let cancelAction = UIAlertAction(title: cancel, style: .cancel)
        
        alertAction.addAction(cameraAction)
        alertAction.addAction(galleryAction)
        if(isImagePicked) {
            let removeAction = UIAlertAction(title: removePhoto.localized, style: .default) { [weak self] _ in
                guard let self = self else {
                    return
                }
                if NetworkReachability.shared.isConnected {
                    AppAlert.shared.showAlert(view: self, title: alert,
                                              message: removePhotoAlert,
                                              buttonOneTitle: cancel,
                                              buttonTwoTitle: removeButton)
                    AppAlert.shared.onAlertAction = { [weak self] (result) ->
                        Void in
                        if result == 1 {
                            self?.isImagePicked = false
                            self?.profileDetails?.image = ""
                            self?.removeProfileImage(fileUrl:  self!.profileImageLocalPath)
                        } else {
                            
                        }
                    }
                } else {
                    AppAlert.shared.showToast(message: ErrorMessage.noInternet)
                }
            }
            alertAction.addAction(removeAction)
        }
        alertAction.addAction(cancelAction)
        present(alertAction, animated: true, completion: nil)
    }
    
    /// This function used to check camera Permission
    
    func checkCameraPermissionAccess(sourceType: UIImagePickerController.SourceType) {
        let authorizationStatus =  AVCaptureDevice.authorizationStatus(for: .video)
        switch authorizationStatus {
        case .denied:
            presentCameraSettings()
            break
        case .restricted:
            break
        case .authorized:
            showImagePickerController(sourceType: sourceType)
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    print("Granted access to ")
                    self.showImagePickerController(sourceType: sourceType)
                } else {
                    print("Denied access to")
                }
            }
            break
        @unknown default:
            print("Permission failed")
        }
    }
    
    func presentCameraSettings() {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "",
                message: cameraAccessDenied.localized,
                preferredStyle: UIAlertController.Style.alert
            )
            
            alert.addAction(UIAlertAction(title: cancel.localized, style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: settings.localized, style: .default, handler: { (alert) -> Void in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url, options: [:], completionHandler: { _ in
                    })
                }
            }))
            
            self.present(alert, animated: false, completion: nil)
        }
    }
    
    /// This function used to check gallery Permission
    
    func checkGalleryPermissionAccess(sourceType: UIImagePickerController.SourceType) {
        var config = TatsiConfig.default
        config.supportedMediaTypes = [.image]
        config.firstView = self.firstView
        config.maxNumberOfSelections = 1
        
        let pickerViewController = TatsiPickerViewController(config: config)
        pickerViewController.pickerDelegate = self
        pickerViewController.isEditing = true
        self.present(pickerViewController, animated: true, completion: nil)
    }
    
    func getAssetThumbnail(asset: PHAsset) -> UIImage {
        let manager = PHImageManager.default()
        let option = PHImageRequestOptions()
        var thumbnail = UIImage()
        option.isSynchronous = true
        manager.requestImage(for: asset,
                                targetSize: CGSize(width: 100, height: 100),
                                contentMode: .aspectFit,
                                options: option, resultHandler: {(result, info)->Void in
            thumbnail = result!
        })
        return thumbnail
    }
    
    func getUIImage(asset: PHAsset) -> UIImage? {
        
        var img: UIImage?
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.version = .original
        options.isSynchronous = true
        manager.requestImageData(for: asset, options: options) { data, _, _, _ in
            
            if let data = data {
                img = UIImage(data: data)
            }
        }
        return img
    }
}

extension GroupInfoViewController: UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    func showImagePickerController(sourceType: UIImagePickerController.SourceType) {
        DispatchQueue.main.async {
            self.imagePickerController.delegate = self
            self.imagePickerController.mediaTypes = ["public.image"]
            self.imagePickerController.sourceType = sourceType
            self.present(self.imagePickerController, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo
                               info: [UIImagePickerController.InfoKey : Any]) {
        isImagePicked = true
        if let userPickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            let cropper = CropperViewController(originalImage: userPickedImage , isCircular: true)
            cropper.delegate = self
            picker.dismiss(animated: true) {
                self.present(cropper, animated: true, completion: nil)
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

extension GroupInfoViewController: CropperViewControllerDelegate {
    func cropperDidConfirm(_ cropper: CropperViewController, state: CropperState?) {
        cropper.dismiss(animated: true, completion: nil)
        
        if let state = state,
           let image = cropper.originalImage.cropped(withCropperState: state) {
            
            print(cropper.isCurrentlyInInitialState)
            print(image)
            
            let string = AppUtils.shared.getRandomString(length: 15)
            let fileName = string ?? ""
            profileImageLocalPath = AppUtils.shared.saveInDirectory(with: image.jpegData(compressionQuality: 1.0), fileName: fileName + jpg) ?? ""
            
            print("localPath-- \( profileImageLocalPath)")
            startLoading(withText: pleaseWait)
            try! GroupManager.shared.updateGroupProfileImage(groupJid: groupID, groupProfileImageUrl: profileImageLocalPath){ [weak self] isSuccess,error,data in
                if isSuccess {
                    self?.setupConfiguration()
                    self?.refreshData()
                    AppAlert.shared.showToast(message: groupImageUpdateSuccess)
                }
                self?.stopLoading()
            }

        }
    }
}

//MARK: For Gallery picker - Select photos and allow photos in permisssion

extension GroupInfoViewController: TatsiPickerViewControllerDelegate {
    
    func pickerViewController(_ pickerViewController: TatsiPickerViewController,
                              didSelectCollection collection: PHAssetCollection) {
        self.lastSelectedCollection = collection
        print("User selected collection: \(collection)")
    }
    
    func pickerViewController(_ pickerViewController: TatsiPickerViewController,
                              didPickAssets assets: [PHAsset]) {
        print("Picked assets: \(assets)")
        
        let options = PHContentEditingInputRequestOptions()
        options.isNetworkAccessAllowed = false //for icloud backup assets
        let asset : PHAsset = assets .first!
        asset.requestContentEditingInput(with: options) { (contentEditingInput, info) in
            if let uniformTypeIdentifier = contentEditingInput?.uniformTypeIdentifier {
                var fullImage: CIImage? = nil
                if let fullSizeImageURL = contentEditingInput?.fullSizeImageURL {
                    fullImage = CIImage(contentsOf: fullSizeImageURL)
                }
                print("uniformTypeIdentifier", uniformTypeIdentifier)
                //if uniformTypeIdentifier == (kUTTypePNG as String) || uniformTypeIdentifier == (kUTTypeJPEG as String) {
                self.isImagePicked = true
                
                guard let assetToImage = self.getUIImage(asset: asset) else {
                    return
                }
                let cropper = CropperViewController(originalImage: assetToImage, isCircular: true)
                cropper.delegate = self
                pickerViewController.dismiss(animated: true) {
                    self.present(cropper, animated: true, completion: nil)
                }
            }
        }
    }
    
    func setCroppedImage(_ croppedImage: UIImage) {
        self.profileImage?.image = croppedImage
    }
}
