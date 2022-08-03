//
//  DropboxSyncClient.swift
//  SwiftyDropboxSync
//
//  Created by Lacy Rhoades on 5/9/18.
//  Copyright © 2018 Lacy Rhoades. All rights reserved.
//

import SwiftyDropbox

public class DropboxSyncClient: SyncClient {
    
    var dropboxClient: DropboxClient
    public init(dropboxClient: DropboxClient) {
        self.dropboxClient = dropboxClient
    }
    
    public var requiresLeadingSlashForRoot: Bool {
        return false
    }
    
    public func download(path: String) -> SyncRequest {
        return DropboxRequest(dropboxClient.files.download(path: path))
    }
    
    public func delete(path: String, andThen: () -> ()) -> SyncRequest {
        return DropboxRequest(dropboxClient.files.deleteV2(path: path))
    }
    
    public func listFolder(path: String) -> SyncRequest {
        return DropboxRequest(dropboxClient.files.listFolder(path: path))
    }
    
    public func listFolder(path: String, startingWithCursor cursor: String) -> SyncRequest {
        return DropboxRequest(dropboxClient.files.listFolderContinue(cursor: cursor))
    }
    
    public func upload(data: Data, named name: String, atPath basePath: String) -> SyncRequest {
        let path = basePath + "/" + name
        return DropboxRequest(dropboxClient.files.upload(path: path, input: data))
    }
}
