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
import SDWebImage
import FlyCore
import Photos

class ChatUtils {
    
    static func setSenderBubbleBackground(imageView : UIImageView?)   {
        imageView?.backgroundColor = Color.senderBubbleColor
        imageView?.roundCorners(corners: [.topLeft,.bottomLeft,.topRight], radius: 8)
    }
    
    static func setReceiverBubbleBackground(imageView : UIImageView?) {
        imageView?.backgroundColor = Color.receiverBubbleColor
        imageView?.roundCorners(corners: [.topLeft,.bottomRight,.topRight], radius: 8)
    }
    
    static func setBubbleBackground(view : UIView?) {
        view?.backgroundColor = Color.deleteForEveryoneColor
        view?.roundCorners(corners: [.topLeft,.bottomRight,.topRight], radius: 8)
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
    
    static func setAttributeString(name: String?) -> NSMutableAttributedString {
        let replyTextMessage = "Contact: \(name ?? "")"
        if let range = replyTextMessage.range(of: name ?? "", options: [.caseInsensitive, .diacriticInsensitive]) {
            let convertedRange = NSRange(range, in: replyTextMessage.capitalized)
            let attributedString = NSMutableAttributedString(string: replyTextMessage.capitalized)
            attributedString.setAttributes([NSAttributedString.Key.foregroundColor: UIColor.black,NSAttributedString.Key.font: UIFont.font12px_appSemibold()], range: convertedRange)
            return attributedString
        }
        return NSMutableAttributedString()
    }

    static func getAttributedMessage(message: String, searchText: String, isMessageSearch: Bool,isSystemBlue: Bool) -> NSMutableAttributedString {
        if isMessageSearch {
            let range = (message.lowercased() as NSString).range(of: searchText.lowercased())
            let mutableAttributedString = NSMutableAttributedString.init(string: message, attributes: [NSAttributedString.Key.backgroundColor: UIColor.clear])
            mutableAttributedString.addAttribute(NSAttributedString.Key.backgroundColor, value: isSystemBlue ? .clear : Color.color_3276E2 ?? .blue, range: range)
            mutableAttributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: isSystemBlue ? UIColor.systemBlue : UIColor.black, range: range)
            return mutableAttributedString
        } else {
            return NSMutableAttributedString.init(string: message, attributes: [NSAttributedString.Key.backgroundColor: UIColor.clear])
        }
    }
    
    static func highlight(uilabel: UILabel,message: String, searchText: String, isMessageSearch: Bool,isSystemBlue: Bool)  {
        if isMessageSearch && searchText.trim().lowercased().count > 0 {
            let mutableString = NSMutableAttributedString(string: message)
            do {
                let attributedString = NSMutableAttributedString(attributedString: mutableString)
                let regex = try NSRegularExpression(pattern:  NSRegularExpression.escapedPattern(for: searchText.trim().lowercased()).folding(options: .regularExpression, locale: .current), options: .caseInsensitive)
                let range = NSRange(location: 0, length: message.utf16.count)
                for match in regex.matches(in: message.folding(options: .regularExpression, locale: .current), options: .withTransparentBounds, range: range) {
                    attributedString.addAttribute(NSAttributedString.Key.backgroundColor, value: Color.color_3276E2 ?? .blue, range: match.range)
                }
                uilabel.attributedText = attributedString
            } catch {
            }
        } else {
            uilabel.attributedText = NSMutableAttributedString.init(string: message, attributes: [NSAttributedString.Key.backgroundColor: UIColor.clear])
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
    
    static func convertAssetToUrlWithcompression(asset: PHAsset,onComplete : @escaping (Bool, URL?) -> Void) {
        
        let compressedURL = NSURL.fileURL(withPath: NSTemporaryDirectory() + UUID().uuidString + MessageExtension.video.rawValue)
        var videoUrl: URL? = nil
        let options: PHVideoRequestOptions = PHVideoRequestOptions()
        options.version = .original
        PHImageManager.default().requestAVAsset(forVideo: asset, options: options, resultHandler: {(asset: AVAsset?, audioMix: AVAudioMix?, info: [AnyHashable : Any]?) -> Void in
            if let urlAsset = asset as? AVURLAsset {
                let localVideoUrl: URL = urlAsset.url as URL
                ChatUtils.compressVideo(inputURL: localVideoUrl,
                                        outputURL: compressedURL) { exportSession in
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
            } else {
                videoUrl = nil
            }
        })
        
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
    
    static func resize(_ image: UIImage) -> UIImage {
        var actualHeight = Float(image.size.height)
        var actualWidth = Float(image.size.width)
        let maxHeight: Float = 300.0
        let maxWidth: Float = 400.0
        var imgRatio: Float = actualWidth / actualHeight
        let maxRatio: Float = maxWidth / maxHeight
        let compressionQuality: Float = 0.5
        //50 percent compression
        if actualHeight > maxHeight || actualWidth > maxWidth {
            if imgRatio < maxRatio {
                //adjust width according to maxHeight
                imgRatio = maxHeight / actualHeight
                actualWidth = imgRatio * actualWidth
                actualHeight = maxHeight
            }
            else if imgRatio > maxRatio {
                //adjust height according to maxWidth
                imgRatio = maxWidth / actualWidth
                actualHeight = imgRatio * actualHeight
                actualWidth = maxWidth
            }
            else {
                actualHeight = maxHeight
                actualWidth = maxWidth
            }
        }
        let rect = CGRect(x: 0.0, y: 0.0, width: CGFloat(actualWidth), height: CGFloat(actualHeight))
        UIGraphicsBeginImageContext(rect.size)
        image.draw(in: rect)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        let imageData = img?.jpegData(compressionQuality: CGFloat(compressionQuality))
        UIGraphicsEndImageContext()
        return UIImage(data: imageData!) ?? UIImage()
    }
    
   static func getPlaceholder(name: String , userColor: UIColor, userImage : UIImageView)->UIImage {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let ipimage = IPImage(text: trimmedName, radius: Double(userImage.frame.size.height), font: UIFont.font200px_appBold(), textColor: nil, color: userColor)
        let placeholder = ipimage.generateInitialImage()
        return placeholder ?? #imageLiteral(resourceName: "ic_profile_placeholder")
    }
    
    static func getUserImaeUrl(imageUrl : String) -> URL? {
        let urlString = FlyDefaults.baseURL + "media/" + imageUrl + "?mf=" + FlyDefaults.authtoken
        print("ContactInfoViewController setProfile \(urlString)")
        return URL(string: urlString)
    }
    
    static func setThumbnail(imageContainer : UIImageView, base64String : String) {
        let converter = ImageConverter()
        let image =  converter.base64ToImage(base64String)
        imageContainer.image = image
    }
    
    static func getGroupSenderName(messsage: ChatMessage?) -> String{
        let result = ChatManager.getUserNameAndNickName(userJid: messsage?.senderUserJid ?? "")
        return getUserName(jid: messsage?.senderUserJid ?? "", name: result.name, nickName: result.nickName, contactType: result.contactType)
    }
    
    static func reportFor(chatUserJid : String, completionHandler : @escaping FlyCompletionHandler) {
        guard let lastFiveMessages = ChatManager.getMessagesForReporting(chatUserJid: chatUserJid, messagesCount: 5) else {
            completionHandler(false,nil,[:])
            return
        }
        report(reportMessage: lastFiveMessages) {  isSuccess, error, data in
            completionHandler(isSuccess,error,data)
        }
    }
    
    static func reportFrom(message : ChatMessage, completionHandler : @escaping FlyCompletionHandler) {
        guard let lastFiveMessages = ChatManager.getMessagesForReporting(message: message, messagesCount: 5) else {
            completionHandler(false,nil,[:])
            return
        }
        report(reportMessage: lastFiveMessages) { isSuccess, error, data in
            completionHandler(isSuccess,error,data)
        }
        
    }
    
    private static func report(reportMessage : ReportMessage, completionHandler : @escaping FlyCompletionHandler) {
        ChatManager.reportMessage(reportMessage: reportMessage) { isSuccess, error, data in
            completionHandler(isSuccess,error,data)
        }
    }
    
    
    public static func isMessagesAvailableFor(jid : String) -> Bool {
        return ChatManager.isMessagesAvailableFor(jid: jid)
    }
    
    static func checkImageFileFormat(format : String) -> Bool{
        debugPrint("ChatUtils Image Format === \(format)")
        if format.isEmpty {
            return false
        }
        
        switch format.lowercased() {
        case "png":
            return true
        case "jpg":
            return true
        case "jpeg":
            return true
        case "gif":
            return true
        case "heic":
            return true
        case "heics":
            return true
        case "heif":
            return true
        case "heifs":
            return true
        case "hevc":
            return true
        default:
            return false
        }
    }
    
    static func setIconForAudio(imageView : UIImageView?, chatMessage : ChatMessage?, replyParentMessage : ReplyParentChatMessage? = nil) {
        if let imageView = imageView, let message = chatMessage {
            if message.mediaChatMessage?.audioType == AudioType.recording {
                imageView.image = UIImage(named: ImageConstant.ic_audio_filled)
            } else {
                imageView.image = UIImage(named: message.isMessageSentByMe ? "senderAudio" : "receiverAudio")
            }
        } else if let imageView = imageView, let message = replyParentMessage {
            if message.mediaChatMessage?.audioType == AudioType.recording {
                imageView.image = UIImage(named: ImageConstant.ic_audio_filled)
            } else {
                imageView.image = UIImage(named: message.isMessageSentByMe ? "senderAudio" : "receiverAudio")
            }
        }
    }
    
    static func getAudiofileDuration(mediaFileName : String) -> TimeInterval? {
        let directoryURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folderPath: URL = directoryURL.appendingPathComponent("FlyMedia/Audio", isDirectory: true)
        let fileURL: URL = folderPath.appendingPathComponent(mediaFileName)
        if FileManager.default.fileExists(atPath: fileURL.relativePath) {
            do {
                let data = try Data(contentsOf: fileURL)
                let audioPlayer = try AVAudioPlayer(data: data as Data)
                return audioPlayer.duration
            } catch {
                return nil
            }
        }
        return nil
    }
    
    static func setDeletedReplyMessage(chatMessage : ChatMessage?,  messageIconView: UIView?,  messageTypeIcon: UIImageView?, replyTextLabel: UILabel?, mediaImageView: UIImageView?, mediaImageViewWidthCons : NSLayoutConstraint?, replyMessageIconWidthCons : NSLayoutConstraint?, replyMessageIconHeightCons : NSLayoutConstraint?) {
        if let isDeleted = chatMessage?.isMessageDeleted, isDeleted || chatMessage?.isMessageRecalled == true {
            replyTextLabel?.text = "Original message not available"
            messageIconView?.isHidden = true
            messageTypeIcon?.isHidden = true
            mediaImageView?.isHidden = true
            mediaImageViewWidthCons?.constant = 0
            replyMessageIconWidthCons?.constant = 0
            replyMessageIconHeightCons?.isActive = false
        }
       
    }
    

    static func getAudioURL(audioFileName : String) -> URL {
        let directoryURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folderPath: URL = directoryURL.appendingPathComponent("FlyMedia/Audio", isDirectory: true)
        let fileURL: URL = folderPath.appendingPathComponent(audioFileName)
        return fileURL
        
    }
    
    static func getLinksFrom(text : String) -> [String] {
        if !text.isEmpty {
            let textArray = text.trim().split(separator: " ")
            
            var linkArray = [String]()
            textArray.forEach { tempText in
                print("getLinkFrom  tempText \(tempText)")
                let string = String(tempText)
                if string.trim().isURL {
                    linkArray.append(string)
                }
            }

            return linkArray
        } else {
            return [String]()
        }
    }
    
    static func clearAllPushNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications() 
    }
    
    static func getImageSize(asset : PHAsset) -> Float {
        var imageSize : Float = 0.0
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.version = .original
        options.isSynchronous = true
        manager.requestImageData(for: asset, options: options) { data, _, _, _ in
            print("getAssetThumbnail \(asset.mediaType)")
            imageSize = Float(data?.count ?? 0)
        }
        return imageSize
    }

}
