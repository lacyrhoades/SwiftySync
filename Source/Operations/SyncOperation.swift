//
//  SyncOperation.swift
//  SwiftySync
//
//  Created by Lacy Rhoades on 12/1/17.
//  Copyright © 2017 Lacy Rhoades. All rights reserved.
//

import Foundation

class SyncOperation<T>: Operation where T: SyncItem {    
    var basePath: String
    var fileSizeLimit: Int64 = 1024 * 1024 * 5
    var client: SyncClient
    let notificationQueue = DispatchQueue(label: "SwiftySync.operationNotification")
    
    init(basePath: String, client: SyncClient) {
        var basePath = basePath
        
        if client.requiresLeadingSlashForRoot && (basePath.isEmpty || basePath == "/") {
            basePath = ""
        } else if basePath.starts(with: "/") == false {
            basePath = "/".appending(basePath)
        }
        
        if basePath.count > 1 && basePath.last == "/" {
            basePath.removeLast()
        }
        
        self.basePath = basePath
        self.client = client
        super.init()
    }
    
    func fullPath(forFilename: String) -> String {
        return basePath.appending("/").appending(forFilename)
    }
    
    var fetchRequests: [SyncRequest] = []
    var continueRequests: [SyncRequest] = []
    
    func fetchBatch(includingDeleted: Bool, usingGroup group: DispatchGroup, withCursor cursor: String? = nil, andThen: @escaping (_: Set<String>) -> ()) {
        
        if let cursor = cursor {
            group.enter()
            let request = client.listFolder(path: basePath, startingWithCursor: cursor)
            request.response(queue: self.notificationQueue) { (maybeResult, maybeError) in
                if let error = maybeError {
                    print(error)
                }
                
                andThen(Set(
                    (maybeResult?.files ?? []).flatMap({ (eachFile) -> String? in
                        if eachFile.size > self.fileSizeLimit {
                            // too big
                            return nil
                        }

                        // Anything else needs to be sorted out by the user!
                        return eachFile.name
                    })
                ))
                
                if (maybeResult?.files.isEmpty ?? true) == false,
                    maybeResult?.hasMore ?? false,
                    let cursor = maybeResult?.cursor {
                    self.fetchBatch(includingDeleted: includingDeleted, usingGroup: group, withCursor: cursor, andThen: andThen)
                }
                
                group.leave()
            }
            self.continueRequests.append(request)
        } else {
            group.enter()
            let request = client.listFolder(path: basePath).response(queue: self.notificationQueue) { (maybeResult, maybeError) in
                if let error = maybeError {
                    print(error)
                }
                
                andThen(Set(
                    (maybeResult?.files ?? []).compactMap({ (eachFile) -> String? in
                        if eachFile.size > self.fileSizeLimit {
                            // too big
                            return nil
                        }
                        
                        // Anything else needs to be sorted out by the user!
                        return eachFile.name
                    })
                ))
                
                if (maybeResult?.files.isEmpty ?? true) == false,
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
