//
//  SMBRequest.swift
//  SwiftyDropboxSync
//
//  Created by Lacy Rhoades on 5/10/18.
//  Copyright © 2018 Lacy Rhoades. All rights reserved.
//

import Foundation
import TOSMBClient

typealias ListSuccessAction = ([SyncFileMetadata]) -> ()
typealias DownloadSuccessAction = (Data, String) -> ()
typealias DownloadStartAction = (TOSMBSessionDownloadTask) -> ()
typealias ErrorAction = (String) -> ()
typealias SMBListRequestAction = (@escaping ListSuccessAction, @escaping ErrorAction) -> ()
typealias SMBDownloadRequestAction = (@escaping DownloadStartAction, @escaping DownloadSuccessAction, @escaping ErrorAction) -> ()

class SMBRequest: SyncRequest {
    private var queue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    func cancel() {
        self.downloadTask?.cancel()
        self.queue.cancelAllOperations()
    }
    
    func response(queue: DispatchQueue, andThen: @escaping (SyncFileCollection?, Error?) -> ()) -> SyncRequest {
        self.queue.addOperation {
            self.listAction?({
                files in
                queue.async {
                    andThen(SyncFileCollection(files: files, hasMore: false), nil)
                }
            }, {
                error in
                queue.async {
                    andThen(nil, SyncError(message: error))
                }
            })
            
            self.downloadAction?({
                task in
                self.downloadTask = task
                self.downloadTask?.resume()
            }, {
                data, identifier in
                queue.async {
                    andThen(SyncFileCollection(data: data, info: SyncDownloadInfo(id: identifier)), nil)
                }
            }, {
                error in
                queue.async {
                    andThen(nil, SyncError(message: error))
                }
            })
        }
        return self
    }
    
    init() {
        //
    }
    
    var listAction: SMBListRequestAction?
    var downloadAction: SMBDownloadRequestAction?
    var downloadTask: TOSMBSessionDownloadTask?
    init(list: @escaping SMBListRequestAction) {
        self.listAction = list
    }
    
    init(download: @escaping SMBDownloadRequestAction) {
        self.downloadAction = download
    }
}
