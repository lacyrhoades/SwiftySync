//
//  DownloadOperation.swift
//  SwiftySync
//
//  Created by Lacy Rhoades on 12/1/17.
//  Copyright © 2017 Lacy Rhoades. All rights reserved.
//

import Foundation

class DownloadOperation<T>: SyncOperation<T> where T: SyncItem {
    var filename: String
    var didDownload: SyncManager<T>.DownloadCompleteAction
    
    init(filename: String, basePath: String, client: SyncClient, didDownload: @escaping SyncManager<T>.DownloadCompleteAction) {
        self.filename = filename
        self.didDownload = didDownload
        super.init(basePath: basePath, client: client)
    }
    
    override func cancel() {
        super.cancel()
        self.request?.cancel()
    }
    
    var request: SyncRequest?
    
    override func main() {
        guard self.isCancelled == false else {
            return
        }
        
        print("DownloadOperation: \(self.filename)")
        
        let waitGroup = DispatchGroup()
        
        waitGroup.enter()
        
        self.request = client.download(path: self.fullPath(forFilename: filename)).response(queue: self.notificationQueue) { (maybeResult, maybeError) in
            if let error = maybeError {
                print(error)
            }
            
            if let data = maybeResult?.downloadData, let info = maybeResult?.downloadInfo {
                self.didDownload(.success(info.id, self.filename, data))
            } else {
                self.didDownload(.fail(self.filename))
            }
            
            waitGroup.leave()
        }
        
        let result = waitGroup.wait(timeout: DispatchTime.seconds(SyncSettings.maximumNetworkTimeout))
        
        switch result {
        case .success:
            break
        case .timedOut:
            print(String(format: "Downloads timed out"))
            request?.cancel()
        }
    }
}
