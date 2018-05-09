//
//  SyncRequest.swift
//  SwiftySync
//
//  Created by Lacy Rhoades on 5/9/18.
//  Copyright © 2018 Lacy Rhoades. All rights reserved.
//

import Foundation

public struct SyncFileMetadata {
    var size: UInt64
    var name: String
}

public struct SyncDownloadInfo {
    var id: String
}

public struct SyncFileCollection {
    var files: [SyncFileMetadata]
    var hasMore: Bool
    var cursor: String?
    var downloadData: Data?
    var downloadInfo: SyncDownloadInfo?
    
    init(data: Data, info: SyncDownloadInfo) {
        self.files = []
        self.hasMore = false
        self.downloadData = data
        self.downloadInfo = info
    }
    
    init (files: [SyncFileMetadata], hasMore: Bool) {
        self.files = files
        self.hasMore = hasMore
    }
}

public protocol SyncRequest {
    func cancel()
    func response(queue: DispatchQueue, andThen: @escaping (SyncFileCollection?, Error?) -> ()) -> SyncRequest
}
