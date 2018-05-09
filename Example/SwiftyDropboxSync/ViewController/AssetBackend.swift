//
//  AssetBackend.swift
//  SwiftyDropboxSync
//
//  Created by Lacy Rhoades on 11/30/17.
//  Copyright © 2017 Lacy Rhoades. All rights reserved.
//

import Photos

class AssetBackend: NSObject {
    func register(forTableView tableView: UITableView) {
        tableView.register(AssetCell.self, forCellReuseIdentifier: AssetCell.identifier)
    }
    
    func refresh() {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        self.assetRequest = PHAsset.fetchAssets(with: options)
        assetsChanged?()
    }
    
    var assetRequest: PHFetchResult<PHAsset>?
    
    var selected: Set<IndexPath> = Set()
    var selectedAssetIDs: [String] {
        return selected.flatMap({ (eachIndex) -> String? in
            return self.assetID(at: eachIndex)
        }).sorted()
    }
    
    var selectedChanged: (() -> ())?
    var assetsChanged: (() -> ())?
}

extension AssetBackend: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selected.insert(indexPath)
        self.selectedChanged?()
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        selected.remove(indexPath)
        self.selectedChanged?()
    }
}

extension AssetBackend: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.assetRequest?.count ?? 0
    }
    
    static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter
    }()
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AssetCell.identifier)!
        
        if let assetID = self.assetID(at: indexPath) {
            let fetchID = AssetFetcher.fetchThumbnail(forID: assetID, size: CGSize(width: 200, height: 200)) { (thumbnail, date) in
                cell.imageView?.image = thumbnail
                if let date = date {
                    cell.textLabel?.text = AssetBackend.dateFormatter.string(from: date)
                } else {
                    cell.textLabel?.text = "Unknown Date"
                }
                cell.setNeedsLayout()
            }
        }
        
        return cell
    }
    
    func assetID(at index: IndexPath) -> String? {
        guard let assets = self.assetRequest else {
            return nil
        }
        
        if index.row >= assets.count {
            return nil
        }
        
        return assets[index.row].localIdentifier
    }
}
