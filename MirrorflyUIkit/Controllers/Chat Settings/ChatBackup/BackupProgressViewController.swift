//
//  BackupProgressViewController.swift
//  MirrorflyUIkit
//
//  Created by Gowtham on 21/11/22.
//

import UIKit
import FlyCore

class BackupProgressViewController: UIViewController {

    @IBOutlet weak var progressLabel: UILabel!
    
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    var delegate: BackupOptionDelegate?
    var isDownload = false
    var iCloudManager = iCloudmanager()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        BackupManager.shared.backupDelegate = self
        startbackup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        activityIndicatorView.startAnimating()
    }

    func startbackup() {
        BackupManager.shared.startBackup()
    }

}
extension BackupProgressViewController: BackupEventDelegate {
    
    func backupProgressDidReceive(completedCount: String, completedSize: String) {
        progressLabel.text = "Please wait a moment (\(completedCount)%)"
    }
    
    func backupDidFinish(fileUrl: String) {
        print(fileUrl)
        if isDownload {
            self.dismiss(animated: true)
            self.delegate?.progressFinished(url: fileUrl)
        } else {
            iCloudManager.uploadBackupFile(fileUrl: fileUrl)
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                self.dismiss(animated: true)
            }
        }
       
    }
    func backupDidFailed(errorMessage: String) {
        self.delegate?.progressFailed(errorMessage: errorMessage)
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
            self.dismiss(animated: true)
        }
    }
    
    
}
