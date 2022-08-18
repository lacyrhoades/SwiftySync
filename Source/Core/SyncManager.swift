//
//  SyncManager.swift
//  SwiftySync
//
//  Created by Lacy Rhoades on 11/30/17.
//  Copyright © 2017 Lacy Rhoades. All rights reserved.
//

import Foundation

public enum Direction {
    case up // sync some collection of fetchLocalItems() -> [T] to a remote destination
    case down // sync some remote destination to refreshRemoteItems([String]) and downloadComplete([Result])
}

public class SyncSettings {
    static var maximumNetworkTimeout: TimeInterval = 100.0
}

public class SyncManager<T> where T: SyncItem {
    var client: SyncClient
    public var basePath: String = "/"
    public var syncInterval: TimeInterval = 30.0
    
    private var syncAttempts: Int = 0
    private var repeatTimer: Timer?
    
    public init(client: SyncClient) {
        self.client = client
    }
    
    public typealias LocalCollectionRefreshAction = () -> (Set<T>)
    public var fetchLocalItems: LocalCollectionRefreshAction?
    
    public typealias RemoteCollectionRefreshAction = (Set<String>) -> ()
    public var refreshRemoteItems: RemoteCollectionRefreshAction?
    
    public typealias DownloadCompleteAction = (DownloadItemActionResult) -> ()
    public var downloadComplete: DownloadCompleteAction?
    
    public var finishedUploads: Set<T> = Set() {
        didSet {
            self.notifyStatsChanged()
        }
    }
    
    public var didSyncUp: (() -> ())?
    
    var failedUploads: Set<T> = Set() {
        didSet {
            self.notifyStatsChanged()
        }
    }
    
    public var uploadStatsDidChange: ((UploadStats) -> ())?
    
    public var finishedDownloads: Set<String> = Set()
    var finishedDownloadsDidChange: (() -> ())?
    
    var failedDownloads: Set<String> = Set()
    var failedDownloadsDidChange: (() -> ())?
    
    private var workQueue = DispatchQueue(label: "SwiftySync.backgroundWorkQueue")
    private var queue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    public func startSyncing(_ direction: Direction) {
        self.syncAttempts += 1
        
        if self.queue.operationCount == 0 {
            self.workQueue.async {
                switch direction {
                case .up:
                    self.syncUp()
                case .down:
                    self.syncDown()
                }
            }
        }
        
        self.queue.addOperation {
            self.repeatTimer?.invalidate()
            let timer = Timer(timeInterval: self.syncInterval, repeats: false, block: { (timer) in
                self.startSyncing(direction)
            })
            self.repeatTimer = timer
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    public func stopSyncing() {
        self.repeatTimer?.invalidate()
        self.syncAttempts = 0
        self.queue.cancelAllOperations()
        self.finishedUploads = Set()
    }

    func syncUp() {
        guard let fullCollection = self.fetchLocalItems?() else {
            precondition(false, "Cannot run sync in up direction without a source collection")
            return
        }
        
        totalCount = fullCollection.count
        
        var before = failedUploads.count
        
        if self.syncAttempts % 10 == 0 {
            // retry failures every 10 cycles
            failedUploads = []
        }
        
        // make sure all the failures still exist in the full set
        failedUploads = failedUploads.intersection(fullCollection)
        
        var after = failedUploads.count
        
        // Delete anything that's finished but that's gone away from the full collection
        let toBeDeleted = finishedUploads.subtracting(fullCollection)
        
        for item in toBeDeleted {
            self.queue.addOperation(
                DeleteOperation(item: item, basePath: self.basePath, client: self.client)
            )
        }
        
        before = finishedUploads.count
        
        // Make sure all the "finished" items are still from the full set
        finishedUploads = finishedUploads.intersection(fullCollection)
        
        after = finishedUploads.count
        
        // Do an upload for anything not mentioned as failed or finished
        let toBeUploaded = fullCollection.subtracting(failedUploads).subtracting(finishedUploads)
        
        let extractedExpr = SyncUpOperation(
            fullCollection: toBeUploaded,
            basePath: self.basePath,
            client: self.client,
            completion: {
                result in
                switch result {
                case .success(let item):
                    self.finishedUploads.insert(item)
                    self.notifyStatsChanged()
                case .fail(let item):
                    self.failedUploads.insert(item)
                    self.notifyStatsChanged()
                }
            }
        )
        self.queue.addOperation(
            extractedExpr
        )
        
        self.didSyncUp?()
    }
    
    var totalCount: Int = 0
    func notifyStatsChanged() {
        self.uploadStatsDidChange?(UploadStats(total: totalCount, done: finishedUploads.count, failed: failedUploads.count))
    }
    
    func syncDown() {
        guard let refreshRemoteItems = self.refreshRemoteItems else {
            precondition(false, "Should not run sync in down direction without refreshRemoteItems([T])")
            return
        }
        
        if self.syncAttempts % 10 == 0 {
            failedDownloads = []
            self.failedDownloadsDidChange?()
        }
        
        failedDownloads = failedDownloads.subtracting(finishedDownloads)
        
        self.queue.addOperation(
            SyncDownOperation<T>(
                finishedDownloads: finishedDownloads,
                failedDownloads: failedDownloads,
                refreshRemoteItems: {
                    allRemoteFilenames in
                    if self.finishedDownloads.subtracting(allRemoteFilenames).count > 0 {
                        self.finishedDownloads = allRemoteFilenames.union(self.finishedDownloads)
                        self.finishedDownloadsDidChange?()
                    }
                    refreshRemoteItems(allRemoteFilenames)
                },
                downloadComplete: {
                    result in
                    
                    self.downloadComplete?(result)
                    
                    switch result {
                    case .success(_, let filename, _):
                        self.finishedDownloads.insert(filename)
                        self.finishedDownloadsDidChange?()
                    case .fail(let filename):
                        self.failedDownloads.insert(filename)
                        self.failedDownloadsDidChange?()
                    }
            },
                basePath: basePath,
                client: client
            )
        )
    }
}

public struct UploadStats {
    public var total: Int
    public var done: Int
    public var failed: Int
}
