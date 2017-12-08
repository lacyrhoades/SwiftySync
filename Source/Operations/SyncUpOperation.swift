//
//  SyncUpOperation.swift
//  SwiftyDropboxSync
//
//  Created by Lacy Rhoades on 12/1/17.
//  Copyright © 2017 Lacy Rhoades. All rights reserved.
//

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
    
    override func cancel() {
        super.cancel()
        
        for request in fetchRequests {
            request.cancel()
        }
        
        for request in continueRequests {
            request.cancel()
        }
    }

    override func main() {
        if self.isCancelled {
            return
        }
        
        print("SyncUpOperation")
        
        var remoteFilenames: Set<String> = []
        
        let waitGroup = DispatchGroup()
        
        self.fetchBatch(includingDeleted: true, usingGroup: waitGroup) {
            batchOfFilenames in
            remoteFilenames = remoteFilenames.union(batchOfFilenames)
        }
        
        let waitResult = waitGroup.wait(timeout: DispatchTime.seconds(SyncSettings.maximumNetworkTimeout))
        
        switch waitResult {
        case .success:
            let missingItems: Set<T> = self.fullCollection.filter({ (eachItem) -> Bool in
                return remoteFilenames.contains(eachItem.filename) == false
            })
            
            for missingItem in missingItems {
                OperationQueue.current?.addOperation(
                    UploadOperation(item: missingItem, basePath: basePath, client: client, completion: completion)
                )
            }
            
            
            let existingItems = fullCollection.subtracting(missingItems)
            
            for item in existingItems {
                completion(.success(item))
            }
        case .timedOut:
            print("SyncUpOperation: Remote listing timed out")
            break
        }
        
        for request in fetchRequests {
            request.cancel()
        }
        
        for request in continueRequests {
            request.cancel()
        }
    }
}
