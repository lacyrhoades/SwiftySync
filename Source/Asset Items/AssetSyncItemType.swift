//
//  AssetSyncItemType.swift
//  SwiftyDropboxSync
//
//  Created by Lacy Rhoades on 12/2/17.
//  Copyright © 2017 Lacy Rhoades. All rights reserved.
//

import Foundation
import Photos

public enum AssetSyncItemType {
    case image
    case video
    
    static func fileExtension(forType type: AssetSyncItemType) -> String {
        switch type {
        case .image:
            return "jpg"
        case .video:
            return "mp4"
        }
    }
    
    public static func type(forMediaType: PHAssetMediaType) -> AssetSyncItemType? {
        switch forMediaType {
        case .image:
            return .image
        case .video:
            return .video
        default: return nil
        }
    }
}
