//
//  DropboxSyncClient.swift
//  SwiftyDropboxSync
//
//  Created by Lacy Rhoades on 5/9/18.
//  Copyright © 2018 Lacy Rhoades. All rights reserved.
//

import SwiftyDropbox

struct DropboxRequest: SyncRequest {
    
    var uploadRequest: UploadRequest<Files.FileMetadataSerializer, Files.UploadErrorSerializer>?
    init(_ req: UploadRequest<Files.FileMetadataSerializer, Files.UploadErrorSerializer>) {
        self.uploadRequest = req
    }
    
    var listRequest: RpcRequest<Files.ListFolderResultSerializer, Files.ListFolderErrorSerializer>?
    init(_ req: RpcRequest<Files.ListFolderResultSerializer, Files.ListFolderErrorSerializer>) {
        self.listRequest = req
    }
    
    var continueListRequest: RpcRequest<Files.ListFolderResultSerializer, Files.ListFolderContinueErrorSerializer>?
    init(_ req: RpcRequest<Files.ListFolderResultSerializer, Files.ListFolderContinueErrorSerializer>) {
        self.continueListRequest = req
    }
    
    var deleteRequest: RpcRequest<Files.DeleteResultSerializer, Files.DeleteErrorSerializer>?
    init(_ req: RpcRequest<Files.DeleteResultSerializer, Files.DeleteErrorSerializer>) {
        self.deleteRequest = req
    }
    
    var downloadRequest: DownloadRequestMemory<Files.FileMetadataSerializer, Files.DownloadErrorSerializer>?
    init(_ req: DownloadRequestMemory<Files.FileMetadataSerializer, Files.DownloadErrorSerializer>) {
        self.downloadRequest = req
    }
    
    func cancel() {
        self.uploadRequest?.cancel()
        self.listRequest?.cancel()
        self.continueListRequest?.cancel()
        self.downloadRequest?.cancel()
        self.deleteRequest?.cancel()
    }
    
    func response(queue: DispatchQueue, andThen: @escaping (SyncFileCollection?, Error?) -> ()) -> SyncRequest {
        
        self.uploadRequest?.response(queue: queue, completionHandler: { (maybeMetadata, maybeError) in
            if let error = maybeError {
                andThen(nil, SyncError(message: "Error uploading file \(self.downloadRequest.debugDescription) \(error.description)"))
            } else {
                andThen(nil, nil)
            }
        })
        
        self.listRequest?.response(queue: queue, completionHandler: { (maybeMetadata, maybeError) in
            if let error = maybeError {
                andThen(nil, SyncError(message: "Error listing folder contents \(self.downloadRequest.debugDescription) \(error.description)"))
            } else {
                let files = maybeMetadata?.entries.compactMap({ (each) -> SyncFileMetadata? in
                    if let file = (each as? Files.FileMetadata) {
                        return SyncFileMetadata(size: file.size, name: file.name)
                    } else {
                        return nil
                    }
                }) ?? []
                var collection = SyncFileCollection(files: files, hasMore: maybeMetadata?.hasMore ?? false)
                collection.cursor = maybeMetadata?.cursor
                andThen(collection, nil)
            }
        })
        
        self.continueListRequest?.response(queue: queue, completionHandler: { (maybeMetadata, maybeError) in
            if let error = maybeError {
                andThen(nil, SyncError(message: "Error continuing to list folder contents \(self.downloadRequest.debugDescription) \(error.description)"))
            } else {
                let files = maybeMetadata?.entries.compactMap({ (each) -> SyncFileMetadata? in
                    if let file = (each as? Files.FileMetadata) {
                        return SyncFileMetadata(size: file.size, name: file.name)
                    } else {
                        return nil
                    }
                }) ?? []
                var collection = SyncFileCollection(files: files, hasMore: maybeMetadata?.hasMore ?? false)
                collection.cursor = maybeMetadata?.cursor
                andThen(collection, nil)
            }
        })
        
        self.downloadRequest?.response(queue: queue, completionHandler: { (maybeMetadata, maybeError) in
            if let error = maybeError {
                andThen(nil, SyncError(message: "Error downloading file \(self.downloadRequest.debugDescription) \(error.description)"))
            } else if let id = maybeMetadata?.0.id, let data = maybeMetadata?.1 {
                let result = SyncFileCollection(data: data, info: SyncDownloadInfo(id: id))
                andThen(result, nil)
            } else {
                andThen(nil, SyncError(message: "Error downloading \(self.downloadRequest.debugDescription) Could not unwrap data/info"))
            }
        })
        
        self.deleteRequest?.response(queue: queue, completionHandler: { (maybeResult, maybeError) in
            if let error = maybeError {
                andThen(nil, SyncError(message: "Error deleting file \(self.downloadRequest.debugDescription) \(error.description)"))
            } else {
                andThen(nil, nil)
            }
        })
        
        return self
    }
    
}

class DropboxSyncClient: SyncClient {
    
    var dropboxClient: DropboxClient
    init(dropboxClient: DropboxClient) {
        self.dropboxClient = dropboxClient
    }
    
    var requiresLeadingSlashForRoot: Bool {
        return false
    }
    
    func download(path: String) -> SyncRequest {
        return DropboxRequest(dropboxClient.files.download(path: path))
    }
    
    func delete(path: String, andThen: () -> ()) -> SyncRequest {
        return DropboxRequest(dropboxClient.files.deleteV2(path: path))
    }
    
    func listFolder(path: String) -> SyncRequest {
        return DropboxRequest(dropboxClient.files.listFolder(path: path))
    }
    
    func listFolder(path: String, startingWithCursor cursor: String) -> SyncRequest {
        return DropboxRequest(dropboxClient.files.listFolderContinue(cursor: cursor))
    }
    
    func upload(data: Data, toPath path: String) -> SyncRequest {
        return DropboxRequest(dropboxClient.files.upload(path: path, input: data))
    }
}
