//
//  GoogleRequest.swift
//  SwiftySync
//
//  Created by Lacy Rhoades on 8/2/22.
//

import GoogleAPIClientForREST

typealias GoogleErrorAction = (String) -> ()

typealias GoogleListSuccessAction = ([SyncFileMetadata]) -> ()
typealias GoogleListRequestAction = (@escaping GoogleListSuccessAction, @escaping GoogleErrorAction) -> ()

typealias GoogleUploadSuccessAction = () -> ()
typealias GoogleUploadRequestAction = (Data, String, @escaping GoogleUploadSuccessAction, @escaping GoogleErrorAction) -> ()

struct GoogleRequest: SyncRequest {
    func cancel() {
        fatalError()
    }
    
    func response(queue: DispatchQueue, andThen: @escaping (SyncFileCollection?, Error?) -> ()) -> SyncRequest {
        fatalError()
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
