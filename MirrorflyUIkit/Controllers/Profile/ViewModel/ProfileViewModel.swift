//
//  ProfileViewModel.swift
//  MirrorflyUIkit
//
//  Created by User on 17/08/21.
//

import Foundation
import FlyCommon
import Alamofire
import FlyCore
class ProfileViewModel {
    var profileModel: ProfileModel!
    
    var emailId: String {
        return profileModel.emailId
    }
    var mobileNumber: String {
        return profileModel.mobileNumber
    }
    var userStatus: String {
        return profileModel.userStatus
    }
    
    typealias ProfileCallBack = (_ status: Bool, _ message: String) -> Void
    var profileCallback:ProfileCallBack?
    
    func updateProfileWith(userName: String, emailId: String, mobileNumber: String) {
        let trimmedUserName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedUserName.isBlank {
            self.profileCallback?(false, emptyUserName.localized)
        }
        else if trimmedUserName.count >  userNameMaxLength{
            self.profileCallback?(false, userNameValidation.localized)
        }
        else if trimmedUserName.count <  userNameMinLength{
            self.profileCallback?(false, userNameMinValidation.localized)
        }
        else if emailId.isBlank {
            self.profileCallback?(false, emptyEmail.localized)
        }
        else if !emailId.isValidEmail(email: emailId) {
            self.profileCallback?(false, emailValidation.localized)
        }
        else {
            self.profileCallback?(true, "")
        }
    }
  
    //MARK:- loginCompletionHandler
    func profileCompletionHandler(callBack: @escaping ProfileCallBack) {
        self.profileCallback = callBack
    }
    
    //MARK:- Contact sync
    func contactSync() {
        let  apiService =  ApiService()
        let params = ["licenseKey": FlyDefaults.licenseKey]
        let url = FlyDefaults.baseURL + "contacts/sandbox/" + syncContacts
        let headers: HTTPHeaders
        let authtoken = FlyDefaults.authtoken
        headers = [
            FlyConstants.authorization: authtoken, "content-type": "application/json"]
        print(headers)
        print(params)
        apiService.post(withEndPoint: url, params: params, headers: headers).responseJSON { [weak self] (response) in
            if response.response?.statusCode == 401 {
                apiService.refreshToken(completionHandler: { isSuccess,flyError,flyData  in
                    if isSuccess {
                        var resultDict : [String: Any] = [:]
                        resultDict = flyData
                        let profiledict = resultDict.getData() as? NSDictionary ?? [:]
                        guard let token = profiledict.value(forKey: "token") as? String else{
                            return
                        }
                        FlyDefaults.authtoken = token
                        self?.contactSync()
                    }
                })
                return
            }
            switch response.result {
            case .success(let JSON):
                guard let responseDictionary = JSON as?[String : Any]  else{
                    return
                }
                ContactManager.shared.getFriendsList(fromServer: true) { isSuccess, error, data in }
                print("success \(responseDictionary)")
                break
            case .failure(let error):
                print("Faill \(error.localizedDescription)")
                break
            }
        }
    }
}
