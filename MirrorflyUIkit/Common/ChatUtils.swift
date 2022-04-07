//
//  ChatUtils.swift
//  MirrorflyUIkit
//
//  Created by John on 14/12/21.
//

import Foundation
import UIKit
import AVKit
import FlyCommon

class ChatUtils {
    
    static func setSenderBubbleBackground(imageView : UIImageView?)   {
        imageView?.backgroundColor = Color.senderBubbleColor
        imageView?.roundCorners(corners: [.topLeft,.bottomLeft,.topRight], radius: 8)
    }
    
    static func setReceiverBubbleBackground(imageView : UIImageView?) {
        imageView?.backgroundColor = Color.receiverBubbleColor
        imageView?.roundCorners(corners: [.topLeft,.bottomRight,.topRight], radius: 8)
    }
    
    static func getColorForUser(userName : String?) -> UIColor {
        if let name = userName, !name.isEmpty {
            var totalAsciiValue = 0
            for char in name {
                if char.isASCII {
                    totalAsciiValue = totalAsciiValue + Int(char.asciiValue ?? UInt8(name.count))
                } else {
                    totalAsciiValue = totalAsciiValue + name.count
                }
            }
            let colorValue = totalAsciiValue * 10000
            let colorNum = colorValue
            let blue = colorNum >> 16
            let red = (colorNum & 0x00FF00) >> 8
            let green = (colorNum & 0x0000FF)
            let userColor = UIColor(red: CGFloat(red)/255.0, green: CGFloat(green)/255.0, blue: CGFloat(blue)/255.0, alpha: 1.0)
            return userColor
        } else {
            return UIColor.gray
        }
    }
    
    static func compressSlowMotionVideo(asset : AVComposition, onCompletion: @escaping (Bool, URL?) -> Void){
        let compressedURL = NSURL.fileURL(withPath: NSTemporaryDirectory() + NSUUID().uuidString + ".mp4")
        print(compressedURL)
        let avCompositionAsset = asset
        if avCompositionAsset.tracks.count > 1{
            guard let exportSession = AVAssetExportSession(asset: avCompositionAsset, presetName: AVAssetExportPresetHighestQuality) else { onCompletion(false, nil); return}
            exportSession.outputURL = compressedURL
            exportSession.outputFileType = AVFileType.mp4
            exportSession.shouldOptimizeForNetworkUse = true
            exportSession.exportAsynchronously { () -> Void in
                DispatchQueue.main.async {
                    let urls = exportSession.outputURL
                    compressVideoTempURL(videoURL: urls!) { (success, url) in
                        if(success){
                            onCompletion(success,url)
                        }
                    }
                }
            }
        }
    }
    
    static func compressVideoTempURL(videoURL : URL, onComplete : @escaping (Bool, URL?) -> Void){
        let compressedURL = NSURL.fileURL(withPath: NSTemporaryDirectory() + NSUUID().uuidString + ".mp4")
        print(compressedURL)
        compressVideo(inputURL: videoURL , outputURL: compressedURL) { (exportSession) in
            guard let session = exportSession else {
                return
            }
            switch session.status {
            case .unknown:
                print("unknown")
                break
            case .waiting:
                print("waiting")
                break
            case .exporting:
                print("exporting")
                break
            case .completed:
                do {
                    let compressedData = try  Data.init(contentsOf: compressedURL)
                    print("File size AFTER compression: \(Double(compressedData.count / 1048576)) mb")
                    onComplete(true,compressedURL)
                }
                catch{
                    onComplete(false,nil)
                    print(error)
                }
            case .failed:
                onComplete(false,nil)
                print("failed")
                break
            case .cancelled:
                onComplete(false,nil)
                print("cancelled")
                break
            @unknown default:
                fatalError()
            }
        }
    }
    
    static func compressVideo(inputURL: URL, outputURL: URL, handler:@escaping (_ exportSession: AVAssetExportSession?)-> Void) {
        let urlAsset = AVURLAsset(url: inputURL, options: nil)
        guard let exportSession = AVAssetExportSession(asset: urlAsset, presetName: AVAssetExportPresetMediumQuality) else {
            handler(nil)
            return
        }
        exportSession.outputURL = outputURL
        exportSession.outputFileType = AVFileType.mp4
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.exportAsynchronously { () -> Void in
            handler(exportSession)
        }
    }
    
   static func getPlaceholder(name: String , userColor: UIColor, userImage : UIImageView)->UIImage {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let ipimage = IPImage(text: trimmedName, radius: Double(userImage.frame.size.height), font: UIFont.font200px_appBold(), textColor: nil, color: userColor)
        let placeholder = ipimage.generateInitialImage()
        return placeholder ?? #imageLiteral(resourceName: "ic_profile_placeholder")
    }
    
    static func getUserImaeUrl(imageUrl : String) -> URL? {
        let urlString = Environment.sandboxImage.baseURL + "media/" + imageUrl + "?mf=" + FlyDefaults.authtoken
        print("ContactInfoViewController setProfile \(urlString)")
        return URL(string: urlString)
    }
    
    static func setThumbnail(imageContainer : UIImageView, base64String : String) {
        let converter = ImageConverter()
        let image =  converter.base64ToImage(base64String)
        imageContainer.image = image
    }
    
}
