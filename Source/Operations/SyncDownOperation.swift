//
//  SyncDownOperation.swift
//  SwiftySync
//
//  Created by Lacy Rhoades on 12/1/17.
//  Copyright © 2017 Lacy Rhoades. All rights reserved.
//

import Foundation

public enum DownloadItemActionResult {
    case success(_: String, _: String, _: Data)
    case fail(_: String)
}

class SyncDownOperation<T>: SyncOperation<T> where T: SyncItem {
    var finishedFilenames: Set<String>
    var failedFilenames: Set<String>
    var refreshRemoteFilenames: SyncManager<T>.RemoteCollectionRefreshAction
    var didDownload: SyncManager<T>.DownloadCompleteAction

    init(
        finishedDownloads: Set<String>,
        failedDownloads: Set<String>,
        refreshRemoteItems: @escaping SyncManager<T>.RemoteCollectionRefreshAction,
        downloadComplete: @escaping SyncManager<T>.DownloadCompleteAction,
        basePath: String,
        client: SyncClient
    ) {
        self.finishedFilenames = finishedDownloads
        self.failedFilenames = failedDownloads
        self.refreshRemoteFilenames = refreshRemoteItems
        self.didDownload = downloadComplete
        super.init(basePath: basePath, client: client)
    }
    
    override func cancel() {
        super.cancel()
        
        for req in fetchRequests {
            req.cancel()
        }
        
        for req in continueRequests {
            req.cancel()
        }
    }
    
    override func main() {
        guard self.isCancelled == false else {
            return
        }
        
        print("SyncDownOperation: main()")
        
        var allRemoteFilenames: Set<String> = []
        
        let waitGroup = DispatchGroup()
        
        self.fetchBatch(includingDeleted: false, usingGroup: waitGroup) {
            existingFilenames in
            allRemoteFilenames = allRemoteFilenames.union(existingFilenames)
        }
        
        let waitResult = waitGroup.wait(timeout: DispatchTime.seconds(SyncSettings.maximumNetworkTimeout))
        
        switch waitResult {
        case .success:
            self.refreshRemoteFilenames(allRemoteFilenames)
            
            let notYetDownloaded: Set<String> = allRemoteFilenames
                .subtracting(self.finishedFilenames)
                .subtracting(self.failedFilenames)

            for filename in notYetDownloaded {
                if self.isCancelled {
                    break
                }
                
                OperationQueue.current?.addOperation(
                    DownloadOperation<T>(
                        filename: filename,
                        basePath: basePath,
                        client: client,
                        didDownload: didDownload
                    )
                )
            }
        case .timedOut:
            print("SyncDownOperation: Remote listing timed out")
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
