//
//  AuthenticationPINViewController.swift
//  UiKitQa
//
//  Created by Ramakrishnan on 09/11/22.
//

import UIKit
import FirebaseAuth
import FlyCore
import FlyCommon
import PhoneNumberKit
import SafariServices
import SwiftUI

class AuthenticationPINViewController: BaseViewController, UITextFieldDelegate {
    
    var pinInput = ""
    var phoneNumber = ""
    var login : Bool = false
    var logout : Bool = false
    var fingerPrintLogin : Bool = false
    var fingerPrintLogout : Bool = false
    var fingerPrintEnable : Bool = false
    var noFingerprintAdded : Bool = false
    var  disableBothPIN : Bool = false
    
    var chatId = String()
    
    
    public var verificationId = ""
    var isAuthorizedSuccess: Bool = false
    var secondsRemaining = passwordResetTimer
    var timer: Timer?
    var currentBackgroundDate = Date()
    
    public var verifyOTPViewModel : VerifyOTPViewModel!
    public var otpViewModel : OTPViewModel!
    
    var array = ["1","2","3","4","5","6","7","8","9","","0", "CLEAR"]
    
    @IBOutlet weak var resendHideView: UIView!
    
    @IBOutlet weak var resendOTP: UIButton!
    
    @IBOutlet weak var initialmainView: UIView!
    
    @IBOutlet weak var forgotpinBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var hideForgotView: UIView!
    
    @IBOutlet weak var forgotButtonoutlet: UIButton!
    
    @IBOutlet weak var txtFirst: UITextField!
    @IBOutlet weak var txtSecond: UITextField!
    @IBOutlet weak var txtThird: UITextField!
    @IBOutlet weak var txtForth: UITextField!
    @IBOutlet weak var txtFifth: UITextField!
    @IBOutlet weak var txtSixth: UITextField!
    
    @IBOutlet weak var timeout: UILabel!
    
    @IBOutlet weak var collectionview: UICollectionView!
    
    @IBOutlet weak var pinEnteredcollectionview: UICollectionView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        textfieldBackgroundcolour()
        configureDefaults()
        handleBackgroundAndForground()
        didMoveToBackground()
        willCometoForeground()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    func setupUI() {
        resendOTP.titleLabel?.font = UIFont.font14px_appRegular()
        txtFirst.font = UIFont.font16px_appSemibold()
        txtSecond.font = UIFont.font16px_appSemibold()
        txtThird.font = UIFont.font16px_appSemibold()
        txtForth.font = UIFont.font16px_appSemibold()
        txtFifth.font = UIFont.font16px_appSemibold()
        txtSixth.font = UIFont.font16px_appSemibold()
        hideForgotView.clipsToBounds = true
        hideForgotView.layer.cornerRadius = 15
        hideForgotView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        self.initialmainView.backgroundColor = UIColor.clear
        self.hideForgotView.isHidden = true
        if fingerPrintLogin == true || login == true{
            self.forgotButtonoutlet.isHidden = false
        }
        else if fingerPrintLogout == true || logout == true || disableBothPIN == true || fingerPrintEnable == true{
            self.forgotButtonoutlet.isHidden = true
        }
        
        txtFirst.addTarget(self, action: #selector(self.textFieldDidChange(textField:)), for: UIControl.Event.editingChanged)
        txtSecond.addTarget(self, action: #selector(self.textFieldDidChange(textField:)), for: UIControl.Event.editingChanged)
        txtThird.addTarget(self, action: #selector(self.textFieldDidChange(textField:)), for: UIControl.Event.editingChanged)
        txtForth.addTarget(self, action: #selector(self.textFieldDidChange(textField:)), for: UIControl.Event.editingChanged)
        txtFifth.addTarget(self, action: #selector(self.textFieldDidChange(textField:)), for: UIControl.Event.editingChanged)
        txtSixth.addTarget(self, action: #selector(self.textFieldDidChange(textField:)), for: UIControl.Event.editingChanged)
        txtFirst.delegate = self
        txtSecond.delegate = self
        txtThird.delegate = self
        txtForth.delegate = self
        txtFifth.delegate = self
        txtSixth.delegate = self
        txtFirst.textContentType = .oneTimeCode
        txtSecond.textContentType = .none
        txtThird.textContentType = .none
        txtForth.textContentType = .none
        txtFifth.textContentType = .none
        txtSixth.textContentType = .none
    }
    func textfieldBackgroundcolour(){
        txtFirst.backgroundColor = UIColor.white
        txtSecond.backgroundColor = UIColor.white
        txtThird.backgroundColor = UIColor.white
        txtForth.backgroundColor = UIColor.white
        txtFifth.backgroundColor = UIColor.white
        txtSixth.backgroundColor = UIColor.white
    }
    
    func configureDefaults(){
        
        self.timeout.text = "01:00"
        sheduletimer()
        txtFirst.textContentType = .username
        txtSecond.textContentType = .username
        txtThird.textContentType = .username
        txtForth.textContentType = .username
        txtFifth.textContentType = .username
        txtSixth.textContentType = .username
        txtFirst.delegate = self
        txtSecond.delegate = self
        txtThird.delegate = self
        txtForth.delegate = self
        txtFifth.delegate = self
        txtSixth.delegate = self
        verifyOTPViewModel =  VerifyOTPViewModel()
        otpViewModel = OTPViewModel()
        phoneNumber = FlyDefaults.myMobileNumber
        
        self.collectionview.register(UINib(nibName:Identifiers.authenticationPINCollectionViewCell, bundle: .main), forCellWithReuseIdentifier:Identifiers.authenticationPINCollectionViewCell)
        
        self.pinEnteredcollectionview.register(UINib(nibName: Identifiers.pinEnteredCollectionViewCell, bundle: .main), forCellWithReuseIdentifier: Identifiers.pinEnteredCollectionViewCell)
        self.collectionview.delegate = self
        self.collectionview.dataSource = self
        self.pinEnteredcollectionview.delegate = self
        self.pinEnteredcollectionview.dataSource = self
    }
    
    func clearTextFields() {
        txtFirst.text = ""
        txtSecond.text = ""
        txtThird.text = ""
        txtForth.text = ""
        txtFifth.text = ""
        txtSixth.text = ""
    }
    
    @objc override func didMoveToBackground() {
        self.currentBackgroundDate = Date()
        
    }
    
    @objc override func willCometoForeground() {
        self.stopTimer()
        let difference = Int(Date().timeIntervalSince(currentBackgroundDate))
        print(difference)
        print(self.secondsRemaining)
        isAuthorizedSuccess = false
        if secondsRemaining  > Int(difference) {
            self.secondsRemaining = secondsRemaining - difference
            print(  secondsRemaining - Int(difference))
            self.timeout.text = "\(Utility.timeString(time: TimeInterval(self.secondsRemaining)))"
            self.sheduletimer()
        }else {
            self.timeout.text = ""
        }
    }
    
    
    func sheduletimer() {
        self.resendHideView.isHidden = true
        self.timeout.isHidden = false
        resendOTP.setTitleColor (Color.resendButtonDisable, for: .normal)
        resendOTP.isUserInteractionEnabled = false
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) {  [weak self] (Timer) in
            if self?.secondsRemaining ?? 0 > 0 {
                self?.timeout.text = Utility.timeString(time: TimeInterval(self?.secondsRemaining ?? 0))
                self?.secondsRemaining -= 1
            } else {
                self?.timeout.text = ""
                self?.stopTimer()
            }
        }
    }
    
    func stopTimer () {
        self.timeout.isHidden = true
        self.resendHideView.isHidden = false
        resendOTP.setTitleColor( Color.resendButtonActivation, for: .normal)
        resendOTP.isUserInteractionEnabled = true
        timer?.invalidate()
    }
    override func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func closeKeyboard() {
        self.view.endEditing(true)
    }
    
    @objc override func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            forgotpinBottomConstraint.constant = keyboardSize.height - (UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0)
        }
    }
    
    @objc override func keyboardWillHide(notification: NSNotification) {
        forgotpinBottomConstraint.constant = 0
    }
    
    
    
    
    @IBAction func cancelButton(_ sender: Any) {
        clearTextFields()
        stopTimer()
        stopLoading()
        self.timeout.text = "01:00"
        secondsRemaining = passwordResetTimer
        resendHideView.isHidden = true
        timeout.isHidden = false
        
        self.initialmainView.backgroundColor = UIColor.clear
        self.hideForgotView.isHidden = true
    }
    
    @IBAction func resendOTPtapped(_ sender: Any) {
        closeKeyboard()
        //Request SMS
        if !phoneNumber.isEmpty {
            if NetworkReachability.shared.isConnected {
                startLoading(withText: resendOtpTxt)
                clearTextFields()
                textfieldBackgroundcolour()
                otpViewModel.requestOtp(phoneNumber: phoneNumber)  { [weak self] (verificationID, error) in
                    
                    if let error = error {
                        self?.stopLoading()
                        DispatchQueue.main.async {
                            let authError = error as NSError?
                            if (authError?.code == AuthErrorCode.tooManyRequests.rawValue) {
                                AppAlert.shared.showToast(message: ErrorMessage.otpAttempts)
                            }
                        }
                        return
                    }
                    DispatchQueue.main.async { [weak self] in
                        self?.stopTimer()
                        self?.stopLoading()
                        self?.secondsRemaining = passwordResetTimer
                        self?.sheduletimer()
                        AppAlert.shared.showToast(message: SuccessMessage.successOTP)
                        
                    }
                    if let verificationId = verificationID {
                        self?.verificationId = verificationId
                    }
                }
            }else {
                AppAlert.shared.showAlert(view: self, title: warning, message: ErrorMessage.noInternet, buttonTitle: okayButton)
            }
        }
    }
    
    
    @IBAction func verifyOTPtapped(_ sender: Any) {
        closeKeyboard()
        
        if  let txtFirst = txtFirst.text,  let txtSecond = txtSecond.text,  let txtThird = txtThird.text,  let txtForth = txtForth.text,  let txtFifth = txtFifth.text,  let txtSixth = txtSixth.text {
            let verificationCode = txtFirst + txtSecond + txtThird + txtForth + txtFifth + txtSixth
            if verificationCode.count == 6 {
                if NetworkReachability.shared.isConnected {
                    startLoading(withText: pleaseWait)
                    verifyOTPViewModel.verifyOtp(verificationId: verificationId, verificationCode: verificationCode) {[weak self]  (authResult, error) in
                        if let error = error {
                            let authError = error as NSError
                            DispatchQueue.main.async { [weak self] in
                                self?.stopLoading()
                                if authError.code == AuthErrorCode.invalidVerificationCode.rawValue{
                                    AppAlert.shared.showToast(message: ErrorMessage.invalidOtp)
                                }else if authError.code == AuthErrorCode.sessionExpired.rawValue {
                                    AppAlert.shared.showToast(message: ErrorMessage.sessionExpired)
                                }
                                self?.clearTextFields()
                                self?.textfieldBackgroundcolour()
                            }
                            return
                        }
                        self?.stopTimer()
                        DispatchQueue.main.async { [weak self] in
                            self?.stopLoading()
                            self?.hideForgotView.isHidden = true
                            self?.initialmainView.backgroundColor = UIColor.clear
                            let vc = AppLockPasswordViewController(nibName: "AppLockPasswordViewController", bundle: nil)
                            self?.navigationController?.pushViewController(vc, animated: true)
                        }
                        
                    }
                }else {
                    AppAlert.shared.showAlert(view: self, title: warning, message: ErrorMessage.noInternet, buttonTitle: okayButton)
                }
            }else if verificationCode.count == 0 {
                AppAlert.shared.showAlert(view: self, title: warning, message: ErrorMessage.enterOtp, buttonTitle: okayButton)
            }
            else {
                AppAlert.shared.showAlert(view: self, title: warning, message: ErrorMessage.otpMismatch, buttonTitle: okayButton)
            }
        }
    }
    
    //PIN VALIDATION
    func validateAppPIN() {
        
        if pinInput == FlyDefaults.appLockPassword  {
            if login == true {
                FlyDefaults.appLockenable = true
            }
            else if logout == true{
                FlyDefaults.appLockenable = false
                requestLogout()
            }
            else if FlyDefaults.appLockenable == true {
                if  disableBothPIN == true {
                    FlyDefaults.appLockenable = false
                    FlyDefaults.appFingerprintenable = false
                }
                else if fingerPrintEnable == true{
                    FlyDefaults.appFingerprintenable = true
                    FlyDefaults.appLockenable = true
                }
            }
            
            if FlyDefaults.appFingerprintenable == true && FlyDefaults.appLockenable == true {
                if fingerPrintLogin == true {
                    FlyDefaults.appFingerprintenable = true
                    FlyDefaults.appLockenable = true
                }
                else if fingerPrintLogout == true  {
                    FlyDefaults.appFingerprintenable = false
                }
            }
            if fingerPrintLogin || noFingerprintAdded{
                if noFingerprintAdded == true{
                    FlyDefaults.appFingerprintenable = false
                }
                FlyDefaults.showAppLock = false
                let storyboard = UIStoryboard(name: Storyboards.main, bundle: nil)
                let initialViewController = storyboard.instantiateViewController(withIdentifier: Identifiers.mainTabBarController) as! MainTabBarController
                let navigationController =  UINavigationController(rootViewController: initialViewController)
                UIApplication.shared.windows.first?.rootViewController = navigationController
                UIApplication.shared.windows.first?.makeKeyAndVisible()
            } else {
                FlyDefaults.showAppLock = false
                let storyboard = UIStoryboard(name: Storyboards.main, bundle: nil)
                let initialViewController = storyboard.instantiateViewController(withIdentifier: Identifiers.mainTabBarController) as! MainTabBarController
                let navigationController =  UINavigationController(rootViewController: initialViewController)
                UIApplication.shared.windows.first?.rootViewController = navigationController
                UIApplication.shared.windows.first?.makeKeyAndVisible()
            }
        }
        else {
            AppAlert.shared.showToast(message: ErrorMessage.validateAppLock)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.pinInput = ""
            self?.pinEnteredcollectionview.reloadData()
        }
    }
    
    @IBAction func forgotbutton(_ sender: Any) {
        phoneNumber = "+"+FlyDefaults.myMobileNumber
        if NetworkReachability.shared.isConnected {
            startLoading(withText: pleaseWait)
            //Request SMS
            otpViewModel.requestOtp(phoneNumber: phoneNumber) {
                (verificationID, error) in
                if let error = error {
                    self.stopLoading()
                    DispatchQueue.main.async {
                        let authError = error as NSError?
                        if (authError?.code == AuthErrorCode.tooManyRequests.rawValue) {
                            AppAlert.shared.showToast(message: ErrorMessage.otpAttempts)
                        }else if (authError?.code == AuthErrorCode.invalidPhoneNumber.rawValue) {
                            AppAlert.shared.showToast(message: ErrorMessage.validphoneNumber)
                        }
                    }
                    return
                }
                if let verificationId = verificationID {
                    DispatchQueue.main.async { [weak self] in
                        self?.stopLoading()
                        self?.stopTimer()
                        self?.sheduletimer()
                        AppAlert.shared.showToast(message: SuccessMessage.successOTP)
                        self?.initialmainView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
                        self?.hideForgotView.isHidden = false
                        self?.verificationId = verificationID ?? ""
                        print(verificationID)
                        
                    }
                    
                }
            }
        }
        
    }
}

extension AuthenticationPINViewController: UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionview == collectionView {
            return array.count
        }
        else {
            return 4
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        
        if collectionview == collectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AuthenticationPINCollectionViewCell", for: indexPath) as! AuthenticationPINCollectionViewCell
            cell.labeloutlet.text = array[indexPath.row]
            if cell.labeloutlet.text == ""{
                cell.labeloutlet.backgroundColor = .clear
            }
            if cell.labeloutlet.text == "CLEAR"{
                cell.labeloutlet.text = ""
                cell.labeloutlet.backgroundColor = .clear
                cell.labeloutlet.setImage(image: UIImage(named: ImageConstant.remove_PIN)!, with: "")
            }
            cell.labeloutlet.layer.cornerRadius = 27
            cell.labeloutlet.clipsToBounds = true
            
            return cell
        }
        else {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PINenteredCollectionViewCell", for: indexPath) as! PINenteredCollectionViewCell
            if pinInput.count > indexPath.item  {
                cell.passwordImage.image = UIImage(named: ImageConstant.otppinDatk)
            }
            else {
                cell.passwordImage.image = UIImage(named: ImageConstant.otpPin)
            }
            if (pinInput.count == 4 && indexPath.item == 3){
                validateAppPIN()
            }
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionview == collectionView {
            return CGSize(width: collectionview.frame.size.width/4, height: collectionview.frame.size.height/5 + 5)
        }
        else{
            return CGSize(width: 30, height: 40)
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionview == collectionView {
            print(array[indexPath.row])
            if indexPath.row != 11 && indexPath.row != 9{
                let text = array[indexPath.row]
                if (pinInput.count <= 4) {
                    pinInput.append(text)
                }
                print("pinInput",pinInput)
            }
            
            if indexPath.row == 11 {
                pinInput = String(pinInput.dropLast())
                print("Removing PIN",pinInput)
                
            }
            
            self.pinEnteredcollectionview.reloadData()
        }
        
    }
    
}

extension AuthenticationPINViewController:  CustomTextFieldDelegate{
    func textField(_ textField: UITextField, didDeleteBackwardAnd wasEmpty: Bool) {
    }
    
    
    @objc func textFieldDidChange(textField: UITextField) {
        let text = textField.text
        if  text?.count == 1 {
            switch textField {
            case txtFirst:
                txtSecond.becomeFirstResponder()
            case txtSecond:
                txtThird.becomeFirstResponder()
            case txtThird:
                txtForth.becomeFirstResponder()
            case txtForth:
                txtFifth.becomeFirstResponder()
            case txtFifth:
                txtSixth.becomeFirstResponder()
            case txtSixth:
                if txtFirst.text?.count == 1 && txtSecond.text?.count == 1 && txtThird.text?.count == 1 && txtForth.text?.count == 1 && txtFifth.text?.count == 1 && txtSixth.text?.count == 1 {
                    txtSixth.resignFirstResponder()
                }
            default:
                break
            }
        }
        if  text?.count == 0 {
            switch textField {
            case txtFirst:
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.txtFirst.text = ""
                }
                txtFirst.becomeFirstResponder()
            case txtSecond:
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.txtSecond.text = ""
                }
                txtFirst.becomeFirstResponder()
            case txtThird:
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.txtThird.text = ""
                }
                txtSecond.becomeFirstResponder()
            case txtForth:
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.txtForth.text = ""
                }
                txtThird.becomeFirstResponder()
            case txtFifth:
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.txtFifth.text = ""
                }
                txtForth.becomeFirstResponder()
            case txtSixth:
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.txtSixth.text = ""
                }
                txtFifth.becomeFirstResponder()
            default:
                break
            }
        }
        
        if (txtFirst.text?.count ?? 0) >= 1 && txtFirst.text != "" {
            txtFirst.backgroundColor = Color.textFieldBackground
        } else {
            txtFirst.backgroundColor = UIColor.white
        }
        if (txtSecond.text?.count ?? 0) >= 1 && txtSecond.text != "" {
            txtSecond.backgroundColor = Color.textFieldBackground
        } else {
            txtSecond.backgroundColor = UIColor.white
        }
        if (txtThird.text?.count ?? 0) >= 1 && txtThird.text != "" {
            txtThird.backgroundColor = Color.textFieldBackground
        } else {
            txtThird.backgroundColor = UIColor.white
        }
        if (txtForth.text?.count ?? 0) >= 1 && txtForth.text != "" {
            txtForth.backgroundColor = Color.textFieldBackground
        } else {
            txtForth.backgroundColor = UIColor.white
        }
        if (txtFifth.text?.count ?? 0) >= 1 && txtFifth.text != "" {
            txtFifth.backgroundColor = Color.textFieldBackground
        } else {
            txtFifth.backgroundColor = UIColor.white
        }
        if (txtSixth.text?.count ?? 0) >= 1 && txtSixth.text != "" {
            txtSixth.backgroundColor = Color.textFieldBackground
        } else {
            txtSixth.backgroundColor = UIColor.white
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if self.txtFirst.text?.count == 1
                && self.txtSecond.text?.count == 1
                && self.txtThird.text?.count == 1
                && self.txtForth.text?.count == 1
                && self.txtFifth.text?.count == 1
                && self.txtSixth.text?.count == 1 {
                if self.txtFirst.text != ""
                    && self.txtSecond.text != ""
                    && self.txtThird.text != ""
                    && self.txtForth.text != ""
                    && self.txtFifth.text != ""
                    && self.txtSixth.text != "" {
                    self.dismissKeyboard()
                } else {
                }
            } else {
            }
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if let text = textField.text,
           let textRange = Range(range, in: text) {
            let updatedText = text.replacingCharacters(in: textRange, with: string)
            if (updatedText.count) <= 1 {
                if string == "" {
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        textField.text = string
                    }
                }
            } else {
                if string == "" {
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        textField.text = string
                    }
                }
                if (updatedText.count) > 1 {
                    return false
                }
            }
        }
        return true
    }
    
}

