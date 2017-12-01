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
}
