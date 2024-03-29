//
//  SMBSyncClient.swift
//  SwiftyDropboxSync
//
//  Created by Lacy Rhoades on 5/10/18.
//  Copyright © 2018 Lacy Rhoades. All rights reserved.
//

import Foundation
import TOSMBClient

public class SMBSyncClient: SyncClient {
    
    public var requiresLeadingSlashForRoot: Bool {
        return true
    }
    
    public func delete(path: String, andThen: () -> ()) -> SyncRequest {
        assert(false, "Not supported yet!")
        return SMBRequest()
    }
    
    public func listFolder(path: String) -> SyncRequest {
        let session = self.session
        let req = SMBRequest(list: { success, error in
            session.requestContentsOfDirectory(atFilePath: path, success: {
                results in
                let files = results?.compactMap({ (each) -> SyncFileMetadata? in
                    if let file = each as? TOSMBSessionFile {
                        return SyncFileMetadata(size: file.fileSize, name: file.name)
                    } else {
                        return nil
                    }
                }) ?? []
                success(files)
            }, error: {
                err in
                error(err?.localizedDescription ?? "Error!")
            })
        })
        return req
    }
    
    public func listFolder(path: String, startingWithCursor: String) -> SyncRequest {
        fatalError("Not supported")
    }
    
    public func upload(data: Data, named: String, atPath: String) -> SyncRequest {
        fatalError("Not supported")
    }
    
    public func download(path: String) -> SyncRequest {
        let session = self.session
        
        let req = SMBRequest(download: { start, success, error in
            let task = session.downloadTaskForFile(atPath: path, destinationPath: nil, progressHandler: { (_, _) in
                //
            }, completionHandler: { (info) in
                if let info = info {
                    let url = URL.init(fileURLWithPath: info)
                    if let data = try? Data.init(contentsOf: url) {
                        let identifier = String(format: "%@%d", path, data.count)
                        success(data, identifier)
                    } else {
                        error("Problem unwrapping data!")
                    }
                } else {
                    error("No download file path given!")
                }
            }, failHandler: { (err) in
                error(err?.localizedDescription ?? "Error!")
            })
            
            if let task = task {
                start(task)
            } else {
                error("No download task produced!")
            }
        })
        return req
    }
    
    var session: TOSMBSession
    public init(session: TOSMBSession) {
        self.session = session
    }
}
