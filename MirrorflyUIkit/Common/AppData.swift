//
//  AppData.swift
//  commonDemo
//
//  Created by User on 13/08/21.
//

import Foundation

//Access : AppConstant.baseUrl
let googleApiKey = "AIzaSyDnjPEs86MRsnFfW1sVPKvMWjqQRnSa7Ts"

struct AppEnvironment {
    static var env = Environment.dev
}

struct AppConstant {
    //App Detail
    static let appName = "MirrorFly"

    static let baseUrl = AppEnvironment.env.baseURL
}


enum Environment: String {
    case dev
    case staging
    case sandbox
    case sandboxImage
    case sandboxContact
    case login
    
    var baseURL: String {
        switch self {
        case .dev:      return  "https://api-preprod-sandbox.mirrorfly.com/api/v1/sandbox/"
        case .staging:  return "https://api-preprod-sandbox.mirrorfly.com/api/v1/sandbox/"
        case .sandbox:  return "https://api-preprod-sandbox.mirrorfly.com/api/v1/sandbox/"
        case .sandboxImage:  return
           "https://api-preprod-sandbox.mirrorfly.com/api/v1/"
        case .sandboxContact:  return
           "https://api-preprod-sandbox.mirrorfly.com/api/v1/contacts/sandbox/"
        case .login:  return
           "https://api-preprod-sandbox.mirrorfly.com/api/v1/"
        }
    }
}
