//
//  CustomPhotoAlbum.swift
//  MirrorflyUIkit
//
//  Created by Sowmiya T on 22/11/21.
//

import Photos
import UIKit

class CustomPhotoAlbum {

    var assetCollection: PHAssetCollection?
    init() {
    }
    
    func fetchAssetCollectionForAlbum(currentFolderName: String?) -> PHAssetCollection! {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", currentFolderName ?? "")
        let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        if let _ = collection.firstObject {
            return collection.firstObject!
        }
        return nil
    }
    
    func createFolder(image: UIImage?,currentFolder : String?) -> PHAssetCollection {
        if let fetchAssetCollection = fetchAssetCollectionForAlbum(currentFolderName: currentFolder) {
            assetCollection = fetchAssetCollection
            return fetchAssetCollection
        }

        PHPhotoLibrary.shared().performChanges({
            PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: currentFolder ?? "")
        }) { success, _ in
            if success {
                self.assetCollection = self.fetchAssetCollectionForAlbum(currentFolderName: currentFolder)
            }
        }
        return PHAssetCollection()
    }

    func saveImage(image: UIImage?,currentFolder : String?,assetsCollection: PHAssetCollection?, completion :@escaping () -> Void) {
        if assetsCollection == nil {
            return   // If there was an error upstream, skip the save.
        }
        assetCollection = assetsCollection
        PHPhotoLibrary.shared().performChanges({
          
            let assetChangeRequest = PHAssetChangeRequest.creationRequestForAsset(from: image ?? UIImage())
            let assetPlaceholder = assetChangeRequest.placeholderForCreatedAsset
            if let assetCollection = self.assetCollection {
                let albumChangeRequest = PHAssetCollectionChangeRequest(for: assetCollection)
                albumChangeRequest?.addAssets([assetPlaceholder] as NSFastEnumeration)
           }
        }, completionHandler: { _,_ in
            DispatchQueue.main.async {
                completion()
            }
        })
    }
    
    private static func saveImageInAlbum(customFolder : String,image: UIImage, completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.shared().performChanges({
            let assetChangeRequest =  PHAssetChangeRequest.creationRequestForAsset(from: image)
            if let fetchAssetCollection = fetchAssetCollectionForAlbum(currentFolderName: customFolder) {
                let assetPlaceholder = assetChangeRequest.placeholderForCreatedAsset
                let albumChangeRequest = PHAssetCollectionChangeRequest(for: fetchAssetCollection)
                albumChangeRequest?.addAssets([assetPlaceholder] as NSFastEnumeration)
            }
        }, completionHandler: { success, error in
            if let error = error {
                print("appSpecificAssetCollection error: \(error)")
                completion(false)
            }
            
            if success {
                completion(true)
            }
        })
    }

    public static func fetchAssetCollectionForAlbum(currentFolderName: String?) -> PHAssetCollection! {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", currentFolderName ?? "")
        let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        if let _ = collection.firstObject {
            return collection.firstObject!
        }
        return nil
    }

    public static func saveDownloadImage(customFolder : String,image: UIImage, completion: @escaping (Bool) -> Void) {
        let fetchOption = PHFetchOptions()
        
        fetchOption.predicate = NSPredicate(format: "title == '" + customFolder + "'")
        
        let fetchResult = PHAssetCollection.fetchAssetCollections(
            with: .album,
            subtype: .albumRegular,
            options: fetchOption)
        
        if fetchResult.firstObject != nil {
            saveImageInAlbum(customFolder: customFolder, image: image, completion: completion)
            
        } else {
            PHPhotoLibrary.shared().performChanges({
                PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: customFolder)
            }, completionHandler: { success, error in
                if let error = error {
                    print("appSpecificAssetCollection error: \(error)")
                    completion(false)
                }
                
                if success {
                    saveImageInAlbum(customFolder: customFolder, image: image, completion: completion)
                }
            })
        }
    }
}
