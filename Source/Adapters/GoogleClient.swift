//
//  GoogleClient.swift
//  SwiftySync
//
//  Created by Lacy Rhoades on 8/2/22.
//

import GoogleAPIClientForREST

public class GoogleClient: SyncClient {
    
    var service: GTLRDriveService
    public init(_ service: GTLRDriveService) {
        self.service = service
    }
    
    public var requiresLeadingSlashForRoot: Bool {
        return false
    }
    
    public func download(path: String) -> SyncRequest {
        fatalError()
    }
    
    public func delete(path: String, andThen: () -> ()) -> SyncRequest {
        fatalError()
    }
    
    public func listFolder(path: String) -> SyncRequest {
        return GoogleRequest(list: { [unowned self] success, error in
            
            let fileID = self.fileID(forPath: path)
            let pathComponents = GoogleDriveFile.pathComponents(using: path)
            
            let query = GTLRDriveQuery_FilesList.query()
            query.q = "'\(fileID)' in parents"
            query.pageSize = 100
            query.fields = "files(id,kind,mimeType,name,size,iconLink,thumbnailLink,parents)"
            query.orderBy = "folder,modifiedTime desc,name"
            
            var results: [SyncFileMetadata] = []
            self.service.executeQuery(query, completionHandler: { (ticket, what, err) in
                if let err = err {
                    error(err.localizedDescription)
                    return
                }
                
                for file in (what as? GTLRDrive_FileList)?.files ?? [] {
                    let item = GoogleDriveFile(file, atPath: pathComponents)
                    self.addFileID(item.id, forPathKey: item.pathKey)
                    if let size = file.size, let name = file.name {
                        results.append(SyncFileMetadata(size: UInt64(truncating: size), name: name))
                    }
                }
                
                DispatchQueue.main.async {
                    success(results)
                }
            })
        })
    }
    
    public func listFolder(path: String, startingWithCursor cursor: String) -> SyncRequest {
        fatalError()
    }
    
    public func upload(data: Data, toPath path: String) -> SyncRequest {
        return GoogleRequest(upload: { [unowned self] data, path, success, error in
            let metadata = GTLRDrive_File()
            metadata.name = "last path component"
            metadata.mimeType = "weird google style type"
            metadata.parents = ["fileId of parent folder"]
            
            let params = GTLRUploadParameters(data: data , mimeType: "image/jpg")
            params.shouldUploadWithSingleRequest = true
            
            let query = GTLRDriveQuery_FilesCreate.query(withObject: metadata, uploadParameters: params)
            query.fields = "id"
            
            self.service.executeQuery(query, completionHandler: { (ticket, what, err) in
                if let err = err {
                    error(err.localizedDescription)
                    return
                }
                
                success()
            })
        })
    }
    
    var fileIDs: [String: String] = [:]
    
    func fileID(forPath: String) -> String {
        if let id = self.fileIDs[forPath] {
            return id
        }
        
        return "root"
    }
    
    func addFileID(_ id: String, forPathKey pathKey: String) {
        self.fileIDs[pathKey] = id
    }
}

struct GoogleDriveFile {
    enum FileType {
        case file
        case image
        case folder
    }
    
    static let pathSeparator = "/-π-/"
    var id: String
    var type: FileType = .file
    var name: String
    var path: [String]
    var pathKey: String {
        return path.appending(self.name).joined(separator: GoogleDriveFile.pathSeparator)
    }
    var size: Int
    var thumbnailURL: String? = nil
    init(_ file: GTLRDrive_File, atPath path: [String]) {
        self.id = file.identifier!
        
        self.name = file.name!
        
        self.path = path
        
        self.size = file.size?.intValue ?? 0
        
        switch file.mimeType! {
        case "application/vnd.google-apps.folder":
            self.type = .folder
        case "image/png":
            self.type = .image
        case "image/jpeg":
            self.type = .image
        case "application/vnd.google-apps.document":
            break
        default:
            break
        }
        
        self.thumbnailURL = file.thumbnailLink
    }
    
    static func pathComponents(using path: String) -> [String] {
        return path.components(separatedBy: GoogleDriveFile.pathSeparator)
    }
}

extension Array {
    public func appending(_ suffix: Element) -> Array<Element> {
        var contents = self
        contents.append(suffix)
        return contents
    }
}
