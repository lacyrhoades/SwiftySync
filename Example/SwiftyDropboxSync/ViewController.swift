//
//  ViewController.swift
//  SwiftyDropboxSync
//
//  Created by Lacy Rhoades on 11/29/17.
//  Copyright © 2017 Lacy Rhoades. All rights reserved.
//

import UIKit
import SwiftyDropbox

class ViewController: UIViewController {

    var assetTableView = UITableView()
    var downloadsTableView = UITableView()
    
    var folderInput = UITextField()
    
    var directionLabel = statusLabel()
    var directionToggle = UISwitch()
    
    var selectedStatusLabel = statusLabel()
    var syncedStatusLabel = statusLabel()
    
    var connectButton = UIButton()
    
    var assetBackend = AssetBackend()
    var downloadsBackend = DownloadsBackend()
    
    var sync: SyncManager<AssetSyncItem>?
    
    var stackView = UIStackView()
    
    var defaultBasePath: String? {
        get {
            return UserDefaults.standard.string(forKey: "DefaultSyncPath")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "DefaultSyncPath")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        assetBackend.register(forTableView: assetTableView)
        downloadsBackend.register(forTableView: downloadsTableView)
        
        sync?.finishedDidChange = {
            self.refreshStatusLabels()
        }
        
        sync?.failedDidChange = {
            self.refreshStatusLabels()
        }
        
        folderInput.backgroundColor = .lightGray
        folderInput.textAlignment = .center
        folderInput.delegate = self
        folderInput.text = self.defaultBasePath
        
        directionToggle.addTarget(self, action: #selector(didToggleDirection), for: .touchUpInside)
        didToggleDirection(directionToggle)
        
        assetBackend.selectedChanged = {
            self.refreshStatusLabels()
        }
        
        assetBackend.assetsChanged = {
            self.assetTableView.reloadData()
            self.refreshStatusLabels()
        }
        
        assetTableView.allowsMultipleSelection = true
        assetTableView.delegate = assetBackend
        assetTableView.dataSource = assetBackend
        
        downloadsTableView.allowsSelection = false
        downloadsTableView.delegate = downloadsBackend
        downloadsTableView.dataSource = downloadsBackend
        
        downloadsBackend.downloadsChanged = {
            self.downloadsTableView.reloadData()
        }
        
        connectButton.addTarget(self, action: #selector(didTapConnectButton), for: .touchUpInside)
        
        connectButton.backgroundColor = .gray
        connectButton.setTitle("Connect Dropbox", for: .normal)
        connectButton.setTitle("Disconnect Dropbox", for: .selected)
        
        stackView.axis = .vertical
        stackView.spacing = 20.0
        
        let folderLabel = statusLabel()
        folderLabel.text = "Sync to path:"
        stackView.addArrangedSubview(folderLabel)
        folderInput.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(folderInput)
        
        downloadsTableView.isHidden = true
        stackView.addArrangedSubview(WrapperView([assetTableView, downloadsTableView], axis: .horizontal, centered: false))
        
        stackView.addArrangedSubview(WrapperView([directionLabel, directionToggle], axis: .horizontal, centered: true))
        stackView.addArrangedSubview(selectedStatusLabel)
        stackView.addArrangedSubview(syncedStatusLabel)
        stackView.addArrangedSubview(connectButton)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: folderInput, attribute: .height, relatedBy: .equal, toItem: folderLabel, attribute: .height, multiplier: 3.0, constant: 0)
        ])
        
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: stackView, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: stackView, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: 0),
        ])
        
        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            self.stackView.topAnchor.constraintEqualToSystemSpacingBelow(guide.topAnchor, multiplier: 1.0),
            guide.bottomAnchor.constraintEqualToSystemSpacingBelow(self.stackView.bottomAnchor, multiplier: 1.0)
            ]
        )
        
        NotificationCenter.default.addObserver(self, selector: #selector(dropboxAuthChanged), name: DropboxUtil.authorizationChangedNotificationName, object: nil)
        
        self.refreshStatusLabels()
    }
    
    func refreshStatusLabels() {
        let selected = assetBackend.selected.count
        let total = assetBackend.assetRequest?.count ?? 0
        let synced = sync?.finished.count ?? 0
        let failed = sync?.failed.count ?? 0
        
        DispatchQueue.main.async {
            self.selectedStatusLabel.text = String(format: "Selected: %d of %d", selected, total)
            self.syncedStatusLabel.text = String(format: "Synced: %d of %d (%d failures)", synced, selected, failed)
        }
    }
    
    @objc func didTapConnectButton() {
        if DropboxUtil.isLoggedIn {
            DropboxUtil.logOut()
        } else {
            DropboxUtil.doAuth(from: self)
        }
    }
    
    @objc func dropboxAuthChanged() {
        connectButton.isSelected = DropboxClientsManager.authorizedClient != nil
    }
    
    override func viewDidAppear(_ animated: Bool) {
        connectButton.isSelected = DropboxClientsManager.authorizedClient != nil
        assetBackend.refresh()
    }
    
    @objc func didToggleDirection(_ toggle: UISwitch) {
        DispatchQueue.main.async {
            if toggle.isOn {
                self.directionLabel.text = "Sync Down from Dropbox"
                self.assetTableView.isHidden = true
                self.downloadsTableView.isHidden = false
                self.downloadsBackend.refresh()
            } else {
                self.directionLabel.text = "Sync Up to Dropbox"
                self.downloadsTableView.isHidden = true
                self.assetTableView.isHidden = false
                self.assetBackend.refresh()
            }
        }
    }
    
}

func statusLabel() -> UILabel {
    let label = UILabel()
    label.textAlignment = .center
    return label
}

extension ViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        let input = textField.text ?? ""
        self.defaultBasePath = input
        sync?.basePath = input
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(false)
        return false
    }
}
