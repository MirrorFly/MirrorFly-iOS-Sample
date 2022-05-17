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
                self.saveImage(image: image, currentFolder: currentFolder, assetsCollection: self.assetCollection)
            }
        }
        return PHAssetCollection()
    }

    func saveImage(image: UIImage?,currentFolder : String?,assetsCollection: PHAssetCollection?) {
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
        }, completionHandler: nil)
    }
}
