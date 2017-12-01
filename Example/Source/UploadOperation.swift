//
//  UploadOperation.swift
//  SwiftyDropboxSync
//
//  Created by Lacy Rhoades on 12/1/17.
//  Copyright © 2017 Lacy Rhoades. All rights reserved.
//

import Foundation
import SwiftyDropbox

class UploadOperation<T>: SyncOperation<T> where T: SyncItem {
    var items: Set<T>
    var completion: SyncItemAction<T>
    
    init(items: Set<T>, basePath: String, client: DropboxClient, completion: @escaping SyncItemAction<T>) {
        self.items = items
        self.completion = completion
        super.init(basePath: basePath, client: client)
    }
    
    override func main() {
        let waitGroup = DispatchGroup()
        
        for item in items {
            waitGroup.enter()
            let result = item.fetchData()
            
            if result.isEmpty == false, let data = result.data {
                let path = self.fullPath(forFilename: item.filename)
                client.files.upload(path: path, input: data).response(queue: self.notificationQueue, completionHandler: { (maybeMetadata, maybeError) in
                    if maybeError == nil {
                        self.completion(.success(item))
                    } else {
                        self.completion(.fail(item))
                    }
                    waitGroup.leave()
                })
            }
        }

        let result = waitGroup.wait(timeout: DispatchTime.seconds(15))
        
        switch result {
        case .success:
            break
        case .timedOut:
            break
        }
    }
}
