//  VerifyOTPViewModel.swift
//  MirrorFly
//  Created by User on 19/05/21.
import Foundation
import FirebaseAuth
import Alamofire
import FlyCore
import FlyCommon
import FlyCall

class VerifyOTPViewModel : NSObject
{
    private var apiService : ApiService!
    
    override init() {
        super.init()
        apiService =  ApiService()
    }
    
    func verifyOtp(verificationId: String, verificationCode: String, completionHandler:  @escaping (AuthDataResult?, Error?)-> Void) {
        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationId, verificationCode: verificationCode)
        Auth.auth().signIn(with: credential) { (authResult, error) in
            completionHandler(authResult, error)
        }
    }
    
    func validateUser(params: NSDictionary, completionHandler:  @escaping (VerifyUserModel?, Error?)-> Void)  {
        apiService.post(withEndPoint: verifyUser, params: params as? Parameters, headers: nil).responseJSON { (response) in
            switch response.result {
            case .success:
                let jsonData = response.data
                do{
                    let userData = try JSONDecoder().decode(VerifyUserModel.self, from: jsonData!)
                    completionHandler(userData,nil)
                }catch {
                    completionHandler(nil,error)
                }
                break
            case .failure( let error):
                completionHandler(nil,error)
                break
            }
        }
        
    }
    func registration(mobileNumber: String, completionHandler:  @escaping ([String: Any]?, String?)-> Void) {
        let deviceToken = Utility.getStringFromPreference(key: googleToken)
        print(deviceToken, mobileNumber)
        try! ChatManager.registerApiService(for: mobileNumber, deviceToken: deviceToken, voipDeviceToken: deviceToken, isLive: IS_LIVE) { isSuccess, flyError, flyData in
            var data = flyData
            if isSuccess {
                completionHandler(data, nil)
            }else{
                let error = data.getMessage()
                completionHandler(data, error as? String)
            }
        }
    }
    
    func initializeChatCredentials(username: String, secretKey: String){
        do {
            try ChatManager.shared.initialize(username: username, secretKey:secretKey, xmppDomain: XMPP_DOMAIN, xmppPort: XMPP_PORT )
            ChatManager.makeXMPPConnection()
            FlyDefaults.isLoggedIn = true
            print("#jid=> \(FlyDefaults.myJid)")
            VOIPManager.sharedInstance.updateDeviceToken()
            RootViewController.sharedInstance.initCallSDK()
        } catch let error {
            print(error.localizedDescription)
        }
    }
}
