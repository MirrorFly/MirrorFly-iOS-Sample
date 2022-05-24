//
//  ImageDetail.swift
//  MirrorflyUIkit
//
//  Created by User on 01/09/21.
//

import Foundation
import UIKit
import Photos
public struct ImageData {
    var image : UIImage?
    var caption: String?
    var isVideo: Bool
    var videoUrl: PHAsset?
    var isSlowMotion : Bool
    var slowMotionVideoUrl : URL?
    var isUploaded : Bool?
}

struct Profile {
    var profileName: String?
    var jid: String = ""
    var isSelected: Bool? 
}
