//
//  AppPermissions.swift
//  MirrorflyUIkit
//
//  Created by John on 23/11/21.
//

import Foundation
import Photos
import UIKit

class AppPermissions {
    
    //Singleton class
    static let shared = AppPermissions()
    
    typealias AvPermissionCallback = (_ avAuthorizationStatus: AVAuthorizationStatus) -> Void
    typealias GalleryPermissionCallBack = (_ phAuthorizationStatus: PHAuthorizationStatus) -> Void
    typealias RecordPermissionCallBack = (_ recordPermission : AVAudioSession.RecordPermission) -> Void
    /**
     *  This function used to check camera Permission
     */
    func checkCameraPermissionAccess(permissionCallBack : @escaping AvPermissionCallback) {
        let authorizationStatus =  AVCaptureDevice.authorizationStatus(for: .video)
        switch authorizationStatus {
        case .denied:
            permissionCallBack(.denied)
            break
        case .restricted:
            permissionCallBack(.restricted)
            break
        case .authorized:
            permissionCallBack(.authorized)
            break
        case .notDetermined:
            permissionCallBack(.notDetermined)
            break
        @unknown default:
            permissionCallBack(.notDetermined)
        }
    }
    
    /**
    * This function used to check photo library permission
    */
    
    func checkGalleryPermission(galleryPermissionCallBack : @escaping GalleryPermissionCallBack) {
        PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .authorized:
                galleryPermissionCallBack(.authorized)
                break
            case .denied:
                galleryPermissionCallBack(.denied)
                break
            case .restricted:
                galleryPermissionCallBack(.restricted)
                break
                // as above
            case .notDetermined:
                galleryPermissionCallBack(.notDetermined)
                break
                
            case .limited:
                if #available(iOS 14, *) {
                    galleryPermissionCallBack(.limited)
                } else {
                    galleryPermissionCallBack(.notDetermined)
                }
                break
                
            @unknown default:
                galleryPermissionCallBack(.notDetermined)
        
            }
        }
    }
    
    func checkMicroPhonePermission(recordPermission : @escaping RecordPermissionCallBack) {
        switch AVAudioSession.sharedInstance().recordPermission {
        case AVAudioSession.RecordPermission.granted:
            recordPermission(.granted)
            break
        case AVAudioSession.RecordPermission.denied:
            recordPermission(.denied)
            break
        case AVAudioSession.RecordPermission.undetermined:
            print("Request permission here")
            AVAudioSession.sharedInstance().requestRecordPermission({ granted in
                recordPermission(.granted)
            })
        @unknown default:
            recordPermission(.undetermined)
        }
    }
    
    func presentCameraSettings(instance : Any) {
        let alert = UIAlertController(title: "", message: cameraAccessDenied.localized, preferredStyle: UIAlertController.Style.alert)
        (instance as? UIViewController)?.present(alert, animated: true, completion:nil)
        if let setting = URL(string: UIApplication.openSettingsURLString),
            UIApplication.shared.canOpenURL(setting) {
            alert.addAction(UIAlertAction(title: settings.localized, style: .default) { action in
                    UIApplication.shared.open(setting)
                })
         }
        alert.addAction(UIAlertAction(title: cancel.localized, style: .cancel) { [weak self] action in
           
        })
    }
    
    
}
