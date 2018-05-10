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

    var direction: Direction = .down
    var sync: SyncManager<AssetSyncItem>?
    
    var folderInput = UITextField()
    
    var assetTableView = UITableView()
    var assetBackend = AssetBackend()
    
    var downloadsTableView = UITableView()
    var downloadsBackend = DownloadsBackend()
    
    var enableLabel = statusLabel()
    var enableToggle = UISwitch()
    
    var directionLabel = statusLabel()
    var directionToggle = UISwitch()
    
    var selectedStatusLabel = statusLabel()
    var selectButton = UIButton()
    
    var syncedStatusLabel = statusLabel()
    
    var connectButton = UIButton()
    
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
        
        sync?.basePath = self.defaultBasePath ?? ""
        
        // What local items do you have available for an "UP" sync?
        sync?.fetchLocalItems = {
            return AssetSyncItem.items(forAssetIDs: self.assetBackend.selectedAssetIDs)
        }
        
        // All possible downloadable items presented here, periodically
        sync?.refreshRemoteItems = {
            allItems in
            self.downloadsBackend.downloadableFilenames = allItems.sorted(by: { (filename1, filename2) -> Bool in
                return filename2.lexicographicallyPrecedes(filename1)
            })
            self.downloadsBackend.refresh()
        }
        
        // If an item is downloaded...
        sync?.downloadComplete = {
            result in
            
            switch result {
            case .success(let guid, let filename, let data):
                self.downloadsBackend.add(data, withGUID: guid, forFilename: filename) {
                    self.downloadsBackend.refresh()
                }
            case .fail(let filename):
                // mark item as failed / allow retry somehow
                print(String(format: "Error downloading: %@", filename))
            }
        }
        
        assetBackend.register(forTableView: assetTableView)
        downloadsBackend.register(forTableView: downloadsTableView)
        
        sync?.finishedUploadsDidChange = {
            self.refreshStatusLabels()
        }
        
        sync?.failedUploadsDidChange = {
            self.refreshStatusLabels()
        }
        
        sync?.finishedDownloadsDidChange = {
            self.refreshStatusLabels()
            self.downloadsBackend.finishedFilenames = self.sync?.finishedDownloads ?? []
            self.downloadsBackend.refresh()
        }
        
        sync?.failedDownloadsDidChange = {
            self.refreshStatusLabels()
            self.downloadsBackend.failedFilenames = self.sync?.failedDownloads ?? []
            self.downloadsBackend.refresh()
        }
        
        folderInput.backgroundColor = .lightGray
        folderInput.textAlignment = .center
        folderInput.delegate = self
        folderInput.text = self.defaultBasePath
        
        enableToggle.addTarget(self, action: #selector(didToggleEnabled), for: .valueChanged)
        directionToggle.isOn = false
        didToggleEnabled(enableToggle)
        
        directionToggle.addTarget(self, action: #selector(didToggleDirection), for: .valueChanged)
        directionToggle.isOn = self.direction == .down
        didToggleDirection(directionToggle)
        
        selectButton.backgroundColor = UIColor.lightGray
        selectButton.setTitle("Select All", for: .normal)
        selectButton.setTitle("Select None", for: .selected)
        selectButton.addTarget(self, action: #selector(didTapSelectButton), for: .touchUpInside)
        
        assetBackend.selectedChanged = {
            self.refreshStatusLabels()
        }
        
        assetBackend.assetsChanged = {
            DispatchQueue.main.async {
                self.assetTableView.reloadData()
            }
            self.refreshStatusLabels()
        }
        
        assetTableView.allowsMultipleSelection = true
        assetTableView.delegate = assetBackend
        assetTableView.dataSource = assetBackend
        
        downloadsTableView.allowsSelection = false
        downloadsTableView.delegate = downloadsBackend
        downloadsTableView.dataSource = downloadsBackend
        
        downloadsBackend.downloadsChanged = {
            DispatchQueue.main.async {
                self.downloadsTableView.reloadData()
            }
            self.refreshStatusLabels()
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
        
        stackView.addArrangedSubview(WrapperView([assetTableView, downloadsTableView], axis: .horizontal, centered: false))
        
        stackView.addArrangedSubview(
            WrapperView([
                enableLabel, enableToggle,
                directionLabel, directionToggle
            ], axis: .horizontal, centered: false)
        )
        
        stackView.addArrangedSubview(
            WrapperView([selectedStatusLabel, selectButton], axis: .horizontal, centered: true)
        )
        
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
        
        if #available(iOS 11, *) {
            let guide = view.safeAreaLayoutGuide
            NSLayoutConstraint.activate([
                stackView.topAnchor.constraintEqualToSystemSpacingBelow(guide.topAnchor, multiplier: 1.0),
                guide.bottomAnchor.constraintEqualToSystemSpacingBelow(stackView.bottomAnchor, multiplier: 1.0)
            ])
        } else {
            let space: CGFloat = 8.0
            NSLayoutConstraint.activate([
                self.stackView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor, constant: space),
                bottomLayoutGuide.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: space)
            ])
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(dropboxAuthChanged), name: DropboxUtil.authorizationChangedNotificationName, object: nil)
        
        self.refreshStatusLabels()
    }
    
    func refreshStatusLabels() {
        let selected = assetBackend.selected.count

        var total: Int
        var loaded: Int
        var failed: Int
        
        switch direction {
        case .up:
            total = assetBackend.assetRequest?.count ?? 0
            loaded = sync?.finishedUploads.count ?? 0
            failed = sync?.failedUploads.count ?? 0
        case .down:
            total = downloadsBackend.downloadableFilenames.count
            loaded = sync?.finishedDownloads.count ?? 0
            failed = sync?.failedDownloads.count ?? 0
        }
        
        DispatchQueue.main.async {
            self.selectButton.isSelected = selected == total
            
            switch self.direction {
            case .up:
                self.selectedStatusLabel.text = String(format: "Selected: %d of %d", selected, total)
                self.syncedStatusLabel.text = String(format: "Uploaded: %d of %d (%d failures)", loaded, selected, failed)
            case .down:
                self.selectedStatusLabel.text = String(format: "Remote Files: %d", total)
                self.syncedStatusLabel.text = String(format: "Downloaded: %d of %d (%d failures)", loaded, total, failed)
            }
            
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
    
    @objc func didTapSelectButton(_ button: UIButton) {
        button.isSelected = !button.isSelected
        
        if button.isSelected {
            for r in 1...assetTableView.numberOfRows(inSection: 0) {
                let path = IndexPath(row: (r - 1), section: 0)
                assetTableView.selectRow(at: path, animated: false, scrollPosition: .none)
                assetBackend.tableView(assetTableView, didSelectRowAt: path)
            }
        } else {
            for r in 1...assetTableView.numberOfRows(inSection: 0) {
                let path = IndexPath(row: (r - 1), section: 0)
                assetTableView.deselectRow(at: path, animated: false)
                assetBackend.tableView(assetTableView, didDeselectRowAt: path)
            }
        }
    }
    
    @objc func didToggleDirection(_ toggle: UISwitch) {
        if toggle.isOn {
            self.directionLabel.text = "Sync Down"
            self.direction = .down
            self.assetTableView.isHidden = true
            self.selectButton.isHidden = true
            self.downloadsTableView.isHidden = false
            self.downloadsBackend.refresh()
        } else {
            self.directionLabel.text = "Sync Up"
            self.direction = .up
            self.downloadsTableView.isHidden = true
            self.selectButton.isHidden = false
            self.assetTableView.isHidden = false
            self.assetBackend.refresh()
        }
        
        self.refreshStatusLabels()
    }
    
    @objc func didToggleEnabled(_ toggle: UISwitch) {
        if toggle.isOn {
            self.enableLabel.text = "Now Syncing"
            self.sync?.startSyncing(self.direction)
        } else {
            self.enableLabel.text = "Syncing Off"
            self.sync?.stopSyncing()
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
