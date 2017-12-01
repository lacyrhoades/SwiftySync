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
        return 0
    }
    
    static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter
    }()
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AssetCell.identifier)!
        
        if let assetID = self.assetID(at: indexPath) {
            AssetFetcher.fetchThumbnail(forID: assetID) { (thumbnail, date) in
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
        return nil
    }
}
