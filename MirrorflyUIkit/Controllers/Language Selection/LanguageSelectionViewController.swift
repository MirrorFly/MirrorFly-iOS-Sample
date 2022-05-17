
//
//  Created by user on 28/02/22.

import UIKit
import FlyCommon
import FlyTranslate

class LanguageSelectionViewController: UIViewController {
    
    @IBOutlet weak var languageSelectionTable: UITableView!
    var languageArray = [LanguageSelection]()
    var isSelected:Bool = false
    var checkedRow: Int?
    var test: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.languageSelectionTable.register(UINib(nibName: Identifiers.LanguageSelectionTableViewCell, bundle: nil), forCellReuseIdentifier: Identifiers.LanguageSelectionTableViewCell)
        self.languageSelectionTable.delegate = self
        self.languageSelectionTable.dataSource = self
        fetchSupportedLanguages()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
    }
    
    @IBAction func onTapBack(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func fetchSupportedLanguages() {
        FlyTranslationManager.shared.supportedTranslationLanguages(TargetLanguageCode: "en", GooogleAPIKey: googleApiKey_Translation){ (languageList,isSuccess,errorMessage) in
            if isSuccess {
                self.languageArray = languageList
                print("languageArray--->", self.languageArray)
            }
            else {
                print(errorMessage)
            }
            DispatchQueue.main.async {
                self.languageSelectionTable.reloadData()
            }
        }
    }
}

extension LanguageSelectionViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return languageArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell : LanguageSelectionTableViewCell = tableView.dequeueReusableCell(withIdentifier: Identifiers.LanguageSelectionTableViewCell, for: indexPath) as! LanguageSelectionTableViewCell
        //cell.selectedImageView.isHidden = true
        cell.languageLabel.text = self.languageArray[indexPath.row].name
        if checkedRow == indexPath.row || self.languageArray[indexPath.row].name == FlyDefaults.selectedLanguage {
            cell.selectedImageView.isHidden = false
        } else {
            cell.selectedImageView.isHidden = true
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.00
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        checkedRow = indexPath.row
        self.languageSelectionTable.reloadData()
        FlyDefaults.selectedLanguage = self.languageArray[indexPath.row].name ?? ""
        FlyDefaults.targetLanguageCode = self.languageArray[indexPath.row].language ?? ""
        self.navigationController?.popViewController(animated: true)
    }
}


