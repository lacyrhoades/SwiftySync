//
//  DeleteOperation.swift
//  SwiftySync
//
//  Created by Lacy Rhoades on 12/1/17.
//  Copyright © 2017 Lacy Rhoades. All rights reserved.
//

import Foundation

class DeleteOperation<T>: SyncOperation<T> where T: SyncItem {
    var item: T
    
    init(item: T, basePath: String, client: SyncClient) {
        self.item = item
        super.init(basePath: basePath, client: client)
    }
    
    override func main() {
        print("DeleteOperation")
        
        let path = self.fullPath(forFilename: item.filename)
        
        let waitGroup = DispatchGroup()
        waitGroup.enter()
        
        let request = client.delete(path: path) {
            waitGroup.leave()
        }
        
        let _ = waitGroup.wait(timeout: DispatchTime.seconds(5))
        request.cancel()
    }
}
