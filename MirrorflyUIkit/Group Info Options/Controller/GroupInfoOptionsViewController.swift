//
//  GroupInfoOptionsViewController.swift
//  MirrorflyUIkit
//
//  Created by Prabakaran M on 10/03/22.
//

import UIKit

class GroupInfoOptions {
    
    var title: String?
    
    init(title: String?) {
        self.title = title
    }
}

protocol GroupInfoOptionsDelegate: class {
    func makeGroupAdmin()
}

class GroupInfoOptionsViewController: UIViewController {
    
    // MARK: - Properties
    
    @IBOutlet weak var baseView: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    let groupInfoViewModel = GroupInfoViewModel()
    weak var delegate: GroupInfoOptionsDelegate? = nil
    
    var groupID = ""
    var userJid = ""
    
    var groupInfoOptionsArray = [GroupInfoOptions(title: "Start Chat"),
                                 GroupInfoOptions(title: "View Info"),
                                 GroupInfoOptions(title: "Remove from Group"),
                                 GroupInfoOptions(title: "Make Admin")]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpUI()
        hideViewWhenTappedAround()
    }
    
    private func setUpUI() {
        setUpStatusBar()
        navigationController?.navigationBar.isHidden = true
        baseView.layer.cornerRadius = 8
        baseView.layer.masksToBounds =  false
        baseView.clipsToBounds = true
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView?.register(UINib(nibName: Identifiers.groupInfoOptionsTableViewCell, bundle: .main),
                            forCellReuseIdentifier: Identifiers.groupInfoOptionsTableViewCell)
    }
    
    // MARK: - User Interactions
    
    func hideViewWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self,
                                         action: #selector(GroupInfoOptionsViewController.dismissView))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc
    func dismissView() {
        view.endEditing(true)
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Public Method
    
    private func refreshData() {
        tableView?.reloadData()
    }
    
    func makeGroupAdmin() {
        groupInfoViewModel.makeGroupAdmin(groupID: groupID, userJid: userJid) {
            [weak self] success in
            
            if success {
                self?.delegate?.makeGroupAdmin()
                AppAlert.shared.showToast(message: "Make admin successfully")
            }
        }
        hideViewWhenTappedAround()
        refreshData()
    }
}

extension GroupInfoOptionsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groupInfoOptionsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = (tableView.dequeueReusableCell(withIdentifier: Identifiers.groupInfoOptionsTableViewCell, for: indexPath) as? GroupInfoOptionsTableViewCell)!
        cell.titleLabel.text = groupInfoOptionsArray[indexPath.row].title
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        groupInfoOptionsArray[indexPath.row].title
        makeGroupAdmin()
    }
}
