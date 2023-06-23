//
//  GoogleRequest.swift
//  SwiftySync
//
//  Created by Lacy Rhoades on 8/2/22.
//

import GoogleAPIClientForREST

typealias GoogleErrorAction = (String) -> ()

typealias GoogleListSuccessAction = ([SyncFileMetadata], String?) -> ()
typealias GoogleListRequestAction = (@escaping GoogleListSuccessAction, @escaping GoogleErrorAction) -> ()

typealias GoogleUploadResult = (String?) -> ()
typealias GoogleUploadRequestAction = (@escaping GoogleUploadResult) -> ()

struct GoogleRequest: SyncRequest {
    private var queue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    func cancel() {
        self.queue.cancelAllOperations()
    }
    
    func response(queue: DispatchQueue, andThen: @escaping (SyncFileCollection?, Error?) -> ()) -> SyncRequest {
        self.queue.addOperation {
            self.listAction?({ files, cursor in
                queue.async {
                    let hasMore = (cursor != nil)
                    var collection = SyncFileCollection(files: files, hasMore: hasMore)
                    collection.cursor = cursor
                    andThen(collection, nil)
                    
                }
            }, {
                error in
                queue.async {
                    andThen(nil, SyncError(message: error))
                }
            })
            self.uploadAction?({ error in
                if let error = error {
                    andThen(nil, SyncError(message: error))
                } else {
                    andThen(nil, nil)
                }
            })
        }
        return self
    }
    
    var listAction: GoogleListRequestAction?
    init(list: @escaping GoogleListRequestAction) {
        self.listAction = list
    }
    
    var uploadAction: GoogleUploadRequestAction?
    init(upload: @escaping GoogleUploadRequestAction) {
        self.uploadAction = upload
    }
}
