//
//  AppLockViewController.swift
//  UiKitQa
//
//  Created by Ramakrishnan on 08/11/22.
//

import UIKit
import FlyCommon
import LocalAuthentication

enum AppLockList: String, CaseIterable {
    case pinlock = "PIN Lock"
    case fingerPrintID = "FingerPrint ID"
    
}

class AppLockViewController: UIViewController {
    
    var pinDisable : Bool = false
    
    private var AppLockSettingsArray = AppLockList.allCases
    
    let selectedCellHeight: CGFloat = 120.0
    let unselectedCellHeight: CGFloat = 70.0
    
    @IBOutlet weak var AppLockTableview: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.AppLockTableview.register(UINib(nibName: Identifiers.appLockTableViewCell, bundle: nil), forCellReuseIdentifier: Identifiers.appLockTableViewCell)
        self.AppLockTableview.delegate = self
        self.AppLockTableview.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if FlyDefaults.appLockPassword == "" {
            FlyDefaults.appLockenable = false
            FlyDefaults.appFingerprintenable = false
        }
        
        AppLockTableview.reloadData()
    }
    
    @IBAction func onTapBack(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
}

extension AppLockViewController: UITableViewDelegate,UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return AppLockSettingsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell : AppLockTableViewCell = tableView.dequeueReusableCell(withIdentifier: Identifiers.appLockTableViewCell, for: indexPath) as! AppLockTableViewCell
        
        switch AppLockSettingsArray[indexPath.row]{
        case .pinlock:
            cell.lblTitle.text = self.AppLockSettingsArray[indexPath.row].rawValue
            cell.helpTextLabel.text = addMoresecurityWith4DigitsecretPIN
            cell.doubleTapLabel.text = changeThe4DigitSecurityPIN
            cell.ChooseLangugaeLabel.text = changePIN
            let tap = UITapGestureRecognizer(target: self, action: #selector(self.PinLock(_:)))
            let formaImageViewTap = UITapGestureRecognizer(target: self, action: #selector(self.PinLock(_:)))
            cell.helpTextView.addGestureRecognizer(tap)
            cell.formaImageView.isUserInteractionEnabled = true
            cell.formaImageView.addGestureRecognizer(formaImageViewTap)
            cell.switchOutlet.isOn = FlyDefaults.appLockenable
            cell.separaterView.isHidden = FlyDefaults.appLockenable ? false : true
            cell.switchOutlet.addTarget(self, action:#selector(AppLockViewController.categorySwitchValueChanged(_:)), for: .valueChanged)
            break
        case .fingerPrintID:
            cell.lblTitle.text = self.AppLockSettingsArray[indexPath.row].rawValue
            cell.helpTextLabel.text = useFingerPrintIDorFaceID
            cell.helpTextView.isHidden = true
            cell.separaterView.isHidden = true
            cell.switchOutlet.isOn = FlyDefaults.appFingerprintenable 
            cell.switchOutlet.addTarget(self, action:#selector(AppLockViewController.categorySwitchFingerPrintValueChanged(_:)), for: .valueChanged)
            
       
            break
        }
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell:AppLockTableViewCell = tableView.cellForRow(at: indexPath) as! AppLockTableViewCell
        switch AppLockSettingsArray[indexPath.row]{
        case .pinlock:
            break
            
        case .fingerPrintID:
            break
            
        }
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch AppLockSettingsArray[indexPath.row]{
        case.pinlock:
            if FlyDefaults.appLockenable {
                return selectedCellHeight
            }
            else {
                return unselectedCellHeight
            }
        case.fingerPrintID:
            return unselectedCellHeight
        }
    }
    
    @objc func PinLock(_ sender: UITapGestureRecognizer? = nil) {
        let vc = ChangeAppLockViewController(nibName:Identifiers.changeAppLockViewController, bundle: nil)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func categorySwitchValueChanged(_ sender : UISwitch!){
        if !FlyDefaults.appLockenable {
            if FlyDefaults.appLockPassword != "" {
                FlyDefaults.appLockenable = true
            }
            else {
                let vc = AppLockPasswordViewController(nibName:Identifiers.appLockPasswordViewController, bundle: nil)
                self.navigationController?.pushViewController(vc, animated: true)
                
            }
        }
        
        else {
            let vc = AuthenticationPINViewController(nibName:Identifiers.authenticationPINViewController, bundle: nil)
            self.navigationController?.pushViewController(vc, animated: true)
            vc.disableBothPIN = true
        }
      
        self.AppLockTableview.reloadData()
    }
    @objc func categorySwitchFingerPrintValueChanged(_ sender : UISwitch!){
        let context = LAContext()
        var error: NSError?
        
        if !context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error){
            AppAlert.shared.showToast(message: ErrorMessage.pleaseEnablefingerPrintonYourdevice)
        }
        
        if !FlyDefaults.appFingerprintenable && context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error){
            
            if FlyDefaults.appLockPassword != "" && FlyDefaults.appLockenable == true{
                FlyDefaults.appLockenable = true
                let vc = AuthenticationPINViewController(nibName:Identifiers.authenticationPINViewController, bundle: nil)
                self.navigationController?.pushViewController(vc, animated: true)
                vc.fingerPrintEnable = true
            }
            
            else if FlyDefaults.appLockPassword == "" && FlyDefaults.appLockenable == false || FlyDefaults.appLockPassword != "" && FlyDefaults.appLockenable == false{
                AppAlert.shared.showAlert(view: self, title: warning, message: biometricAuthentication, buttonTitle: okButton)
                AppAlert.shared.onAlertAction = { [weak self] (result)  ->
                    Void in
                    if result == 0 {
                        let vc = AppLockPasswordViewController(nibName:Identifiers.appLockPasswordViewController, bundle: nil)
                        self?.navigationController?.pushViewController(vc, animated: true)
                        vc.fingerPINisOn = true
                    }
                }
                
            }
        }
       
        else if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) && FlyDefaults.appFingerprintenable == true {
            let vc = AuthenticationPINViewController(nibName:Identifiers.authenticationPINViewController, bundle: nil)
            self.navigationController?.pushViewController(vc, animated: true)
            vc.fingerPrintLogout = true
        }
       
        self.AppLockTableview.reloadData()
    }
}
