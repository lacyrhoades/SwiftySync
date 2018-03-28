//
//  SyncOperation.swift
//  SwiftyDropboxSync
//
//  Created by Lacy Rhoades on 12/1/17.
//  Copyright © 2017 Lacy Rhoades. All rights reserved.
//

import Foundation
import SwiftyDropbox

class SyncOperation<T>: Operation where T: SyncItem {    
    var basePath: String
    var fileSizeLimit: Int64 = 1024 * 1024 * 5
    var client: DropboxClient
    let notificationQueue = DispatchQueue(label: "SwiftyDropboxSync.operationNotification")
    
    init(basePath: String, client: DropboxClient) {
        var basePath = basePath
        
        if basePath.isEmpty || basePath == "/" {
            basePath = ""
        } else if basePath.starts(with: "/") == false {
            basePath = "/".appending(basePath)
        }
        
        self.basePath = basePath
        self.client = client
        super.init()
    }
    
    func fullPath(forFilename: String) -> String {
        return basePath.appending("/").appending(forFilename)
    }
    
    var fetchRequests: [RpcRequest<Files.ListFolderResultSerializer, Files.ListFolderErrorSerializer>] = []
    var continueRequests: [RpcRequest<Files.ListFolderResultSerializer, Files.ListFolderContinueErrorSerializer>] = []
    
    func fetchBatch(includingDeleted: Bool, usingGroup group: DispatchGroup, withCursor cursor: String? = nil, andThen: @escaping (_: Set<String>) -> ()) {
        
        if let cursor = cursor {
            group.enter()
            let request = client.files.listFolderContinue(cursor: cursor)
            request.response(queue: self.notificationQueue) { (maybeResult, maybeError) in
                if let error = maybeError {
                    print(error)
                }
                
                andThen(Set(
                    (maybeResult?.entries ?? []).flatMap({ (eachMetadata) -> String? in
                        guard let file = (eachMetadata as? Files.FileMetadata) else {
                            // not a file
                            return nil
                        }
                            
                        if file.size > self.fileSizeLimit {
                            // too big
                            return nil
                        }

                        // Anything else needs to be sorted out by the user!
                        return file.name
                    })
                ))
                
                if (maybeResult?.entries.isEmpty ?? true) == false,
                    maybeResult?.hasMore ?? false,
                    let cursor = maybeResult?.cursor {
                    self.fetchBatch(includingDeleted: includingDeleted, usingGroup: group, withCursor: cursor, andThen: andThen)
                }
                
                group.leave()
            }
            self.continueRequests.append(request)
        } else {
            group.enter()
            let request = client.files.listFolder(path: basePath, recursive: false, includeMediaInfo: false, includeDeleted: includingDeleted, includeHasExplicitSharedMembers: false)
            request.response(queue: self.notificationQueue) { (maybeResult, maybeError) in
                if let error = maybeError {
                    print(error)
                }
                
                andThen(Set(
                    (maybeResult?.entries ?? []).flatMap({ (eachMetadata) -> String? in
                        guard let file = (eachMetadata as? Files.FileMetadata) else {
                            // not a file
                            return nil
                        }
                        
                        if file.size > self.fileSizeLimit {
                            // too big
                            return nil
                        }
                        
                        // Anything else needs to be sorted out by the user!
                        return file.name
                    })
                ))
                
                if (maybeResult?.entries.isEmpty ?? true) == false,
                    maybeResult?.hasMore ?? false,
                    let cursor = maybeResult?.cursor {
                    self.fetchBatch(includingDeleted: includingDeleted, usingGroup: group, withCursor: cursor, andThen: andThen)
                }
                
                group.leave()
            }
            self.fetchRequests.append(request)
        }
    }
}
