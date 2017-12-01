//
//  SyncUpOperation.swift
//  SwiftyDropboxSync
//
//  Created by Lacy Rhoades on 12/1/17.
//  Copyright © 2017 Lacy Rhoades. All rights reserved.
//

import Foundation
import SwiftyDropbox

enum SyncItemActionResult<T> {
    case success(T)
    case fail(T)
}

typealias SyncItemAction<T> = (_: SyncItemActionResult<T>) -> ()

class SyncUpOperation<T>: SyncOperation<T> where T: SyncItem {
    var fullCollection: Set<T>
    var completion: SyncItemAction<T>
    
    init(fullCollection: Set<T>, basePath: String, client: DropboxClient, completion: @escaping SyncItemAction<T>) {
        self.fullCollection = fullCollection
        self.completion = completion
        super.init(basePath: basePath, client: client)
    }

    override func main() {
        var filenames: Set<String> = []
        
        let waitGroup = DispatchGroup()
        
        self.fetchBatch(usingGroup: waitGroup) {
            existingFilenames in
            filenames = filenames.union(existingFilenames)
        }
        
        let waitResult = waitGroup.wait(timeout: DispatchTime.seconds(15))
        
        switch waitResult {
        case .success:
            let missingItems: Set<T> = self.fullCollection.filter({ (eachItem) -> Bool in
                return filenames.contains(eachItem.filename) == false
            })
            
            OperationQueue.current?.addOperation(
                UploadOperation(items: missingItems, basePath: basePath, client: client, completion: completion)
            )
            
            let existingItems = fullCollection.subtracting(missingItems)
            
            for item in existingItems {
                completion(.success(item))
            }
        case .timedOut:
            break
        }
        
        for request in fetchRequests {
            request.cancel()
        }
        
        for request in continueRequests {
            request.cancel()
        }
    }
    
    var fetchRequests: [RpcRequest<Files.ListFolderResultSerializer, Files.ListFolderErrorSerializer>] = []
    var continueRequests: [RpcRequest<Files.ListFolderResultSerializer, Files.ListFolderContinueErrorSerializer>] = []
    
    func fetchBatch(usingGroup group: DispatchGroup, withCursor cursor: String? = nil, andThen: @escaping (_: Set<String>) -> ()) {
        
        if cursor == nil {
            print("Fetch with NO cursor")
        } else {
            print("Fetch using cursor")
        }
        
        var batch: Set<String> = []
        
        if let cursor = cursor {
            group.enter()
            let request = client.files.listFolderContinue(cursor: cursor)
            request.response(queue: self.notificationQueue) { (maybeResult, maybeError) in
                if let error = maybeError {
                    print(error)
                }
                
                for entry in maybeResult?.entries ?? [] {
                    batch.insert(entry.name)
                }
                
                andThen(batch)
                
                if maybeResult?.hasMore ?? false, let cursor = maybeResult?.cursor {
                    self.fetchBatch(usingGroup: group, withCursor: cursor, andThen: andThen)
                }
                
                group.leave()
            }
            self.continueRequests.append(request)
        } else {
            group.enter()
            let request = client.files.listFolder(path: basePath, recursive: false, includeMediaInfo: true, includeDeleted: true, includeHasExplicitSharedMembers: false, includeMountedFolders: false, limit: nil, sharedLink: nil)
            request.response(queue: self.notificationQueue) { (maybeResult, maybeError) in
                if let error = maybeError {
                    print(error)
                }
                
                for entry in maybeResult?.entries ?? [] {
                    batch.insert(entry.name)
                }
                
                andThen(batch)
                
                if maybeResult?.hasMore ?? false, let cursor = maybeResult?.cursor {
                    self.fetchBatch(usingGroup: group, withCursor: cursor, andThen: andThen)
                }
                
                group.leave()
            }
            self.fetchRequests.append(request)
        }
    }
}
