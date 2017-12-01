//
//  SyncManager.swift
//  SwiftyDropboxSync
//
//  Created by Lacy Rhoades on 11/30/17.
//  Copyright © 2017 Lacy Rhoades. All rights reserved.
//

import SwiftyDropbox

class SyncManager<T> where T: SyncItem {
    var client: DropboxClient
    
    init(client: DropboxClient) {
        self.client = client
    }
    
    typealias CollectionRefreshAction = () -> (Set<T>)
    var collection: CollectionRefreshAction?
    
    var syncInterval: TimeInterval = 10.0
    var basePath: String = "/"
    
    private var queue = OperationQueue()
    
    private let uploadQueue = DispatchQueue(label: "SwiftyDropboxSync.uploadQueue")
    private let queryQueue = DispatchQueue(label: "SwiftyDropboxSync.queryQueue")
    private let deleteQueue = DispatchQueue(label: "SwiftyDropboxSync.queryQueue")
    
    var finished: Set<T> = Set()
    var finishedDidChange: (() -> ())?
    
    var failed: Set<T> = Set()
    var failedDidChange: (() -> ())?
    
    func beginSyncing() {
        queue.maxConcurrentOperationCount = 1
        
        let fullCollection = self.collection?() ?? []
        
        var before = failed.count
        failed = failed.filter({ (eachItem) -> Bool in
            return fullCollection.contains(eachItem)
        })
        var after = failed.count
        
        if before != after {
            self.failedDidChange?()
        }
        
        let newlyMissing = finished.subtracting(fullCollection)
        
        before = finished.count
        finished = finished.filter({ (eachItem) -> Bool in
            return fullCollection.contains(eachItem)
        })
        after = finished.count
        
        if before != after {
            self.finishedDidChange?()
        }
        
        for item in newlyMissing {
            self.queue.addOperation(
                DeleteOperation(item: item, basePath: self.basePath, client: self.client)
            )
        }
        
        let filtered = fullCollection.subtracting(failed)
        
        self.queue.addOperation(
            SyncUpOperation(
                fullCollection: filtered,
                basePath: self.basePath,
                client: self.client,
                completion: {
                    result in
                    switch result {
                    case .success(let item):
                        self.finished.insert(item)
                        self.finishedDidChange?()
                    case .fail(let item):
                        self.failed.insert(item)
                        self.failedDidChange?()
                    }
                }
            )
        )
        
        self.queue.addOperation {
            DispatchQueue.global().asyncAfter(deadline: DispatchTime.seconds(self.syncInterval)) {
                self.beginSyncing()
            }
        }
    }
}
