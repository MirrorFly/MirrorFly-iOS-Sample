//
//  AppUtils.swift
//  MirrorflyUIkit
//
//  Created by User on 17/09/21.
//

import Foundation
import UIKit
import AVKit
import Photos

class AppUtils: NSObject {
    
    //Singleton class
    static let shared = AppUtils()
    
    //MARK: Get random string
    func getRandomString(length: Int) -> String? {
        let letters = "0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
        
    }
    
    //MARK: Image path from directory
    func saveInDirectory(with data: Data?, fileName: String?) -> String? {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).map(\.path)
        let documentsDirectory = paths[0]
        let localFilePath = documentsDirectory + "/" + fileName!
        if let value = data {
            NSData(data: value).write(toFile: localFilePath, atomically: true)
        }
        return localFilePath
    }
    
    func currentMillisecondsToTime(milliSec: Double) -> String{
        let dateVar = Date.init(timeIntervalSince1970: TimeInterval(milliSec)/1000)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = chatTimeFormat
        return dateFormatter.string(from: dateVar)
    }
    
    func cropToBounds(image: UIImage, width: Double, height: Double, imageOrientation: UIImage.Orientation) -> UIImage {
        
        let cgimage = image.cgImage!
        let contextImage: UIImage = UIImage(cgImage: cgimage)
        let contextSize: CGSize = contextImage.size
        var posX: CGFloat = 0.0
        var posY: CGFloat = 0.0
        var cgwidth: CGFloat = CGFloat(width)
        var cgheight: CGFloat = CGFloat(height)
        
        // See what size is longer and create the center off of that
        if contextSize.width > contextSize.height {
            posX = ((contextSize.width - contextSize.height) / 2)
            posY = 0
            cgwidth = contextSize.height
            cgheight = contextSize.height
        } else {
            posX = 0
            posY = ((contextSize.height - contextSize.width) / 2)
            cgwidth = contextSize.width
            cgheight = contextSize.width
        }
        
        let rect: CGRect = CGRect(x: posX, y: posY, width: cgwidth, height: cgheight)
        
        // Create bitmap image from context using the rect
        let imageRef: CGImage = cgimage.cropping(to: rect)!
        
        // Create a new image based on the imageRef and rotate back to the original orientation
        let image: UIImage = UIImage(cgImage: imageRef, scale: image.scale, orientation: imageOrientation)
        
        return image
    }
    
    
    func callPhoneNumber(phoneNumber: String) {
        if let phoneCallURL = URL(string: "tel://\(phoneNumber)") {
            let application:UIApplication = UIApplication.shared
            if (application.canOpenURL(phoneCallURL)) {
                application.open(phoneCallURL, options: [:], completionHandler: nil)
            }
        }
    }
    
    func openURLInBrowser(urlString: String) {
        var tempUrl = urlString
        if !tempUrl.contains("http://") || !tempUrl.contains("https://")  {
            tempUrl = "https://" + tempUrl
        }
        if let url = URL(string: tempUrl) {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(url)
            }
        }
    }
    
    func getRandomColors() ->[UIColor?]
    {
        let colors = [Color.color1, Color.color2, Color.color3, Color.color4, Color.color5, Color.color6, Color.color7, Color.color8, Color.color9, Color.color10, Color.color11, Color.color12, Color.color13, Color.color14, Color.color15, Color.color16, Color.color17, Color.color18, Color.color19, Color.color20 ]
        return colors
    }
    
    func setRandomColors(totalCount: Int) -> [UIColor?] {
        var colors : [UIColor?] = []
        while totalCount > 0 {
            colors.append(contentsOf: getRandomColors())
            if totalCount <= colors.count {
                return colors
            }
        }
        return getRandomColors()
    }
    
    
    func generateThumbnail(path: URL) -> UIImage? {
        do {
            let asset = AVURLAsset(url: path, options: nil)
            let imgGenerator = AVAssetImageGenerator(asset: asset)
            imgGenerator.appliesPreferredTrackTransform = true
            var time = asset.duration
            time.value = 0
            let cgImage = try imgGenerator.copyCGImage(at: time, actualTime: nil)
            var thumbnail = UIImage(cgImage: cgImage)
            let imageData = thumbnail.jpegData(compressionQuality: 0.5)
            thumbnail = UIImage(data: imageData!)!
            return thumbnail
        } catch let error {
            print("*** Error generating thumbnail: \(error.localizedDescription)")
            return nil
        }
    }
    
    func marqueeTextToWebKit(text : String) -> String{
        return "<html><body><marquee>" + text + "</marquee></body></html>"
    }
    
    func compressVideo(inputURL: URL, outputURL: URL, handler:@escaping (_ exportSession: AVAssetExportSession?)-> Void) {
        let urlAsset = AVURLAsset(url: inputURL, options: nil)
        guard let exportSession = AVAssetExportSession(asset: urlAsset, presetName: AVAssetExportPresetMediumQuality) else {
            handler(nil)
            
            return
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = AVFileType.mov
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.exportAsynchronously { () -> Void in
            handler(exportSession)
        }
    }
    
}

public struct Units {
    
    public let bytes: Int64
    
    public var kilobytes: Double {
        return Double(bytes) / 1_024
    }
    
    public var megabytes: Double {
        return kilobytes / 1_024
    }
    
    public var gigabytes: Double {
        return megabytes / 1_024
    }
    
    public init(bytes: Int64) {
        self.bytes = bytes
    }
    
    public func getReadableUnit() -> String {
        
        switch bytes {
        case 0..<1_024:
            return "\(bytes) bytes"
        case 1_024..<(1_024 * 1_024):
            return "\(String(format: "%.1f", kilobytes)) KB"
        case 1_024..<(1_024 * 1_024 * 1_024):
            return "\(String(format: "%.1f", megabytes)) MB"
        case (1_024 * 1_024 * 1_024)...Int64.max:
            return "\(String(format: "%.1f", gigabytes)) GB"
        default:
            return "\(bytes) bytes"
        }
    }
}

func executeOnMainThread( codeBlock: @escaping () -> Void) {
    DispatchQueue.main.async {
        codeBlock()
    }
}

