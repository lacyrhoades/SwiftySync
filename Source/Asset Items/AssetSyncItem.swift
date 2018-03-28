//
//  AssetSyncItem.swift
//  SwiftyDropboxSync
//
//  Created by Lacy Rhoades on 11/30/17.
//  Copyright © 2017 Lacy Rhoades. All rights reserved.
//

import Photos

public struct AssetSyncItem: SyncItem {
    public var id: String
    public var filename: String
    
    static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        return formatter
    }()
    
    public static func uniqueFilename(forDate date: Date, withType type: AssetSyncItemType, consideringFilenames existingFilenames: Set<String>) -> String {
        
        let baseFilename = AssetSyncItem.dateFormatter.string(from: date)
        let fileExtension = AssetSyncItemType.fileExtension(forType: type)
        var filename: String
        var index = 0
        
        repeat {
            let suffix = index > 0 ? String(format: "-%d", index) : ""
            filename = String(format: "%@%@.%@", baseFilename, suffix, fileExtension)
            index += 1
        } while existingFilenames.contains(filename) && index < MAX_INPUT
        
        return filename
    }
    
    public init(id: String, filename: String) {
        self.id = id
        self.filename = filename
    }
    
    public func fetchData() -> DataFetchResult {
        return AssetFetcher.syncFetchOriginalData(forID: self.id)
    }
    
    public var hashValue: Int {
        return self.id.hashValue
    }
    
    public static func == (lhs: AssetSyncItem, rhs: AssetSyncItem) -> Bool {
        return lhs.id == rhs.id
    }
    
    static func items(forAssetIDs assetIDs: [String]) -> Set<AssetSyncItem> {
        var existingFilenames = Set<String>()
        
        return Set(
            assetIDs.flatMap({ (eachID) -> AssetSyncItem? in
                if let info = AssetFetcher.info(forAssetID: eachID) {
                    let filename = AssetSyncItem.uniqueFilename(
                        forDate: info.createDate,
                        withType: info.type,
                        consideringFilenames: existingFilenames
                    )
                    
                    existingFilenames.insert(filename)
                    
                    return AssetSyncItem(id: eachID, filename: filename)
                }
                
                assert(false)
                return nil
            })
        )
    }
    
}

