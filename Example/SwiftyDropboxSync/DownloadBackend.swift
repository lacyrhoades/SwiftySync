//
//  DownloadBackend.swift
//  SwiftyDropboxSync
//
//  Created by Lacy Rhoades on 12/1/17.
//  Copyright © 2017 Lacy Rhoades. All rights reserved.
//

import UIKit

class DownloadsBackend: NSObject {
    func register(forTableView tableView: UITableView) {
        tableView.register(AssetCell.self, forCellReuseIdentifier: AssetCell.identifier)
    }
    
    func refresh() {
        downloadsChanged?()
    }
    
    var downloadsChanged: (() -> ())?
    var downloadableFilenames: [String] = []
    var failedFilenames: Set<String> = []
    var finishedFilenames: Set<String> = []
    var downloadedItems: [String: AssetSyncItem] = [:]
    
    func add(_ data: Data, forFilename: String, andThen: @escaping () -> ()) {
        print("Save data to camera roll: \(data.count)")
//        if let image = UIImage(data: data) {
//            ImageUtil.save(image, toAlbumNamed: "SwiftySync") { (maybeAssetID) in
//                if let assetID = maybeAssetID {
//                    self.downloadedItems[forFilename] = AssetSyncItem(id: assetID, filename: forFilename)
//                    andThen()
//                }
//            }
//        }
    }
}

extension DownloadsBackend: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100.0
    }
}

extension DownloadsBackend: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.downloadableFilenames.count
    }
    
    static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter
    }()
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AssetCell.identifier)! as! AssetCell
        
        if let assetID = self.assetID(at: indexPath) {
            cell.isDownloading = true
            
            let fetchID = AssetFetcher.fetchThumbnail(forID: assetID, size: CGSize(width: 200, height: 200)) { (thumbnail, date) in
                
                cell.isDownloading = false
                
                cell.imageView?.image = thumbnail
                if let date = date {
                    cell.textLabel?.text = AssetBackend.dateFormatter.string(from: date)
                } else {
                    cell.textLabel?.text = "Unknown Date"
                }
                cell.setNeedsLayout()
            }
            
            if let id = fetchID {
                cell.tag = Int(id)
            } else {
                cell.tag = 0
            }
        } else if indexPath.row < self.downloadableFilenames.count {

            let filename = self.downloadableFilenames[indexPath.row]
            cell.textLabel?.text = filename
            
            if self.failedFilenames.contains(filename) {
                cell.backgroundColor = .red
                cell.isDownloading = false
            } else {
                cell.backgroundColor = .white
                cell.isDownloading = self.finishedFilenames.contains(filename) == false
            }
        }
        
        return cell
    }
    
    func assetID(at index: IndexPath) -> String? {
        guard index.row < self.downloadableFilenames.count else {
            return nil
        }
        
        let filename = self.downloadableFilenames[index.row]
        
        let asset = self.downloadedItems[filename]
        
        return asset?.id
    }
}
