//
//  UploadOperation.swift
//  SwiftyDropboxSync
//
//  Created by Lacy Rhoades on 12/1/17.
//  Copyright © 2017 Lacy Rhoades. All rights reserved.
//

import SwiftyDropbox

class UploadOperation<T>: SyncOperation<T> where T: SyncItem {
    var item: T
    var completion: SyncItemAction<T>
    
    init(item: T, basePath: String, client: DropboxClient, completion: @escaping SyncItemAction<T>) {
        self.item = item
        self.completion = completion
        super.init(basePath: basePath, client: client)
    }
    
    override func main() {
        print(String(format: "UploadOperation: %@", item.filename))
        
        let waitGroup = DispatchGroup()
        waitGroup.enter()
        
        // blocking call to gather data for upload
        let fetchResult = item.fetchData()
        
        var request: UploadRequest<Files.FileMetadataSerializer, Files.UploadErrorSerializer>?
        
        if let data = fetchResult.validData {
            let path = self.fullPath(forFilename: item.filename)
            
            print(String(format: "UploadOperation: Item upload start to path: %@", path))
            
            request = client.files.upload(path: path, input: data).response(queue: self.notificationQueue, completionHandler: { (maybeMetadata, maybeError) in
                if maybeError == nil {
                    self.completion(.success(self.item))
                } else {
                    self.completion(.fail(self.item))
                }
                waitGroup.leave()
            })
        } else {
            self.completion(.fail(item))
            waitGroup.leave()
        }

        let result = waitGroup.wait(timeout: DispatchTime.seconds(120))
        
        switch result {
        case .success:
            break
        case .timedOut:
            print(String(format: "Upload timed out for file: %@", item.filename))
            request?.cancel()
        }
    }
}
