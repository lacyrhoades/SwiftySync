//
//  DeleteOperation.swift
//  SwiftyDropboxSync
//
//  Created by Lacy Rhoades on 12/1/17.
//  Copyright © 2017 Lacy Rhoades. All rights reserved.
//

import Foundation
import SwiftyDropbox

class DeleteOperation<T>: SyncOperation<T> where T: SyncItem {
    var item: T
    
    init(item: T, basePath: String, client: DropboxClient) {
        self.item = item
        super.init(basePath: basePath, client: client)
    }
    
    override func main() {
        let path = self.fullPath(forFilename: item.filename)
        
        let waitGroup = DispatchGroup()
        waitGroup.enter()
        
        let request = client.files.deleteV2(path: path).response(queue: self.notificationQueue) { (maybeResult, maybeError) in
            waitGroup.leave()
        }
        
        let _ = waitGroup.wait(timeout: DispatchTime.seconds(5))
        request.cancel()
    }
}
