//
//  UserDefaults.swift
//  MirrorFly
//
//  Created by User on 18/05/21.
//

import UIKit
import FlyCommon
import Alamofire

class Utility: NSObject{
    
    class func saveInPreference (key : String , value : Any) {
        UserDefaults.standard.setValue(value, forKey: key)
    }
    
    class func getIntFromPreference(key : String) -> Int32 {
        if (UserDefaults.standard.object(forKey: key) != nil)
        {
            return  Int32(UserDefaults.standard.integer(forKey:key))
        }else{
            return 0
        }
    }
    
    class func getStringFromPreference(key : String) -> String {
        if (UserDefaults.standard.object(forKey: key) != nil)
        {
            return  UserDefaults.standard.string(forKey: key) ?? ""
        }else{
            return ""
        }
    }
    
    class func getArrayFromPreference(key : String) -> NSArray {
        if (UserDefaults.standard.object(forKey: key) != nil)
        {
            return  UserDefaults.standard.object(forKey: key) as? NSArray ?? NSArray()
        }else
        {
            return NSArray()
        }
    }
    
    class func getBoolFromPreference(key : String) -> Bool {
        if (UserDefaults.standard.object(forKey: key) != nil)
        {
            return  UserDefaults.standard.bool(forKey:key)
        }else{
            return false
        }
    }
    
    class func timeString(time: TimeInterval) -> String {
        let minute = Int(time) / 60 % 60
        let second = Int(time) % 60

        // return formated string
        return String(format: "%02i:%02i", minute, second)
    }
    
    class func secondsToMinutesSeconds (seconds : Int32) -> String {
        let minute = (seconds % 3600) / 60
        let second = (seconds % 3600) % 60
        
      return String(format: "%02i:%02i", minute, second)
    }
    
    class func currentMillisecondsToTime(milliSec: Double) -> String{
        let dateVar = Date.init(timeIntervalSince1970: TimeInterval(milliSec)/1000)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = chatTimeFormat
        return dateFormatter.string(from: dateVar)
    }
    
    class func convertTime(timeStamp: Double) -> String {
        let convertTimeStamp = timeStamp / 1000
        let date2 = Date(timeIntervalSince1970: (Double(convertTimeStamp) / 1000.0))
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .short
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
       let dateStr = dateFormatter.string(from: date2)
        let dateFormatter1 = DateFormatter()
        dateFormatter1.timeStyle = .short
        dateFormatter1.timeZone = TimeZone(abbreviation: "UTC")
        
        if let date = dateFormatter1.date(from: dateStr) {
            dateFormatter1.timeZone = TimeZone.current
            return dateFormatter1.string(from: date)
        }
        return ""
    }
    class func removeCharFromString(string: String, char: String) ->String {
        let strValue = string.replacingOccurrences(of: char, with: "", options: NSString.CompareOptions.literal, range: nil)
        return strValue

    }
 
    public class func appendBaseURL(restEnd : String) -> String {
        var restEndUrl:String = ""
        
        if (!restEnd.hasPrefix("http://") && !restEnd.hasPrefix("https://")) {
            restEndUrl = BASE_URL + restEnd
        }
        return restEndUrl
    }
    
    public class func IntialLetter(name : String , imageView: UIImageView , colorCode : String, frameSize : Int, fontSize : CGFloat)
    {
        let lblNameInitialize = UILabel()
        lblNameInitialize.frame.size = CGSize(width: frameSize, height: frameSize)
        lblNameInitialize.textColor = UIColor.white
        lblNameInitialize.font = AppFont.Medium.size(fontSize)
        let wordArray = name.split(separator: " ")
        if wordArray.count >= 2 {
            let firstTwoChar = String(wordArray[0].first!).uppercased() + String(wordArray[1].first!).uppercased()
            lblNameInitialize.text = firstTwoChar
        }else{
            lblNameInitialize.text = String(name.prefix(2)).uppercased()
        }
        lblNameInitialize.textAlignment = NSTextAlignment.center
        UIGraphicsBeginImageContext(CGSize(width: frameSize, height: frameSize))
        lblNameInitialize.layer.render(in: UIGraphicsGetCurrentContext()!)
        imageView.image = UIGraphicsGetImageFromCurrentImageContext()
        imageView.backgroundColor = Utility.color(fromHexString: colorCode)
        imageView.contentMode = .center
        UIGraphicsEndImageContext()
    }
    
    public class func download(token : String , profileImage : UIImageView?, uniqueId : String, name : String, colorCode : String, frameSize: Int, fontSize : CGFloat,notify: Bool = false,completion : @escaping () -> Void) {
        let imageCache = ImageCache.shared
        if let profileImage = profileImage{
            if token == "" {
                IntialLetter(name: name, imageView: profileImage, colorCode: colorCode,frameSize: frameSize,fontSize: fontSize)
            }else{
                if let cachedImage = imageCache.object(forKey: token as NSString) {
                    profileImage.clipsToBounds = true
                    profileImage.contentMode = .scaleAspectFill
                    profileImage.image = cachedImage
                }else{
                    IntialLetter(name: name, imageView: profileImage, colorCode: colorCode,frameSize: frameSize,fontSize: fontSize)
                    var endPoint = String()
                    if token.contains("https"){
                        let arr = token.components(separatedBy: "/")
                        let baseUrl = "\(arr[6])".components(separatedBy: ".")
                        endPoint = appendBaseURL(restEnd: "media/" + "\(baseUrl[0])" + ".")
                    }else{
                        let baseUrl = "media/" + token
                        endPoint = appendBaseURL(restEnd: baseUrl)
                    }
                    var localFileName : String = ""
                    let destination: DownloadRequest.Destination = { _, _ in
                        let localPath = attachmentsDocumentDirectory()
                        localFileName = generateUniqueId()
                        let localFilePath = localPath.appendingPathComponent(localFileName)
                        return (localFilePath, [.removePreviousFile, .createIntermediateDirectories])
                    }
                    let headers: HTTPHeaders
                    headers = [
                        "Content-Type": "application/json",
                        "Authorization": FlyDefaults.authtoken,
                        "messageID" : ""
                    ]
                    AF.download(endPoint, method: .get, headers: headers, to: destination)
                        .responseData { [self] (response) in
                            if response.error == nil{
                                if response.response?.statusCode == 200 {
                                    DispatchQueue.main.async {
                                        if let uiImage = UIImage(contentsOfFile: response.fileURL?.relativePath ?? ""){
                                            imageCache.setObject(uiImage, forKey: token as NSString)
                                            if notify {
                                                completion()
                                            }else{
                                                profileImage.contentMode = .scaleAspectFill
                                                profileImage.image = imageCache.object(forKey: token as NSString)
                                            }
                                        }
                                    }
                                }else if response.response?.statusCode == 401{
                                    refreshToken { isSuccess in
                                        if isSuccess {
                                            self.download(token: token, profileImage: profileImage, uniqueId: uniqueId,name: name,colorCode: colorCode,frameSize: frameSize,fontSize: fontSize, completion: completion)
                                        }
                                    }
                                }
                                
                            }else{
                                print(response.description)
                            }
                        }
                }
            }
        }
        
    }
    
    public class func refreshToken(onCompletion: @escaping (_ isSuccess: Bool) -> Void) {
        let username = FlyDefaults.myXmppUsername
        let password = FlyDefaults.myXmppPassword
        if username.count == 0 || password.count == 0 {
            return
        }
        let parameters = ["username" : username,
                          "password": password];
        let url = appendBaseURL(restEnd: "login")
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: nil, requestModifier: nil).validate().responseJSON { response in
            switch response.result {
            case .success(let result):
                if response.response?.statusCode == 200 {
                    guard let responseDictionary = result as? [String : Any]  else{
                        return
                    }
                    let data = responseDictionary["data"] as? [String: String] ?? [:]
                    let token = data["token"] ?? ""
                    FlyDefaults.authtoken = token
                }
                onCompletion(true)
                
            case .failure(_) :
                onCompletion(false)
            }
        }
    }
    
    public class func color(fromHexString hexString: String?) -> UIColor? {
        if (hexString?.count ?? 0) != 0 {
            let hexint = Int(intFromHexString(hexStr: hexString!))
            let red = CGFloat((hexint & 0xff0000) >> 16) / 255.0
            let green = CGFloat((hexint & 0xff00) >> 8) / 255.0
            let blue = CGFloat((hexint & 0xff) >> 0) / 255.0
            // Create color object, specifying alpha as well
            let color = UIColor(red: red, green: green, blue: blue, alpha: 1.0)
            return color
        } else {
            return UIColor.black
        }
    }
    
    public class func intFromHexString(hexStr: String) -> UInt32 {
        var hexInt: UInt32 = 0
        // Create scanner
        let scanner: Scanner = Scanner(string: hexStr)
        // Tell scanner to skip the # character
        scanner.charactersToBeSkipped = CharacterSet(charactersIn: "#")
        // Scan hex value
        scanner.scanHexInt32(&hexInt)
        return hexInt
    }
    
    public static func attachmentsDocumentDirectory() -> URL {
        var customFolder = "FlyMedia"
        customFolder = customFolder + "/" + "Image"
        let fileManager = FileManager.default
        let documentsFolder = try! fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        let localPath = documentsFolder.appendingPathComponent(customFolder)
        let folderExists = (try? localPath.checkResourceIsReachable()) ?? false
        do {
            if !folderExists {
                try fileManager.createDirectory(at: localPath, withIntermediateDirectories: true)
            }
        } catch { print(error) }
        
        return localPath
    }
    
    public static func generateUniqueId() -> String {
        return UUID.init().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
    }
    
}
extension TimeInterval {
    var minuteSecondMS: String {
        return String(format:"%d:%02d", minute, second)
    }
    var minute: Int {
        return Int((self/60).truncatingRemainder(dividingBy: 60))
    }
    var second: Int {
        return Int(truncatingRemainder(dividingBy: 60))
    }
}

extension Int {
    var msToSeconds: Double {
        return Double(self) / 1000
    }
}

public class ImageCache {
    
    private init() {}
    
    public static let shared = NSCache<NSString, UIImage>()
    
}

