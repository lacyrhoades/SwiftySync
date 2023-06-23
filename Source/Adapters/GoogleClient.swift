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
        return GoogleRequest(list: { [unowned self] success, failure in
            self.service.findFileID(forPath: path, then: { parentID in
                self.service.listContents(using: parentID) { contents, cursor, error in
                    if let error = error {
                        failure(error.localizedDescription)
                    } else if let contents = contents {
                        success(contents, cursor)
                    }
                }
            }, orElse: {
                failure("File not found")
            })
        })
    }
    
    public func listFolder(path: String, startingWithCursor cursor: String) -> SyncRequest {
        return GoogleRequest(list: { [unowned self] success, failure in
            self.service.findFileID(forPath: path, then: { parentID in
                self.service.listContents(using: parentID, afterCursor: cursor) { contents, cursor, error in
                    if let error = error {
                        failure(error.localizedDescription)
                    } else if let contents = contents {
                        success(contents, cursor)
                    }
                }
            }, orElse: {
                failure("File not found")
            })
        })
    }
    
    public func upload(data: Data, named name: String, atPath path: String) -> SyncRequest {
        return GoogleRequest(upload: { [unowned self] result in
            self.service.findFileID(forPath: path) { fileID in
                self.service.doUpload(data: data, named: name, inParent: fileID) { error in
                    result(error)
                }
            } orElse: {
                result("File not found")
            }
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
    
    static func mimeType(basedOn name: String) -> String {
        var mimeType = "image/jpeg"
        if name.debugDescription.localizedCaseInsensitiveContains(".png") {
            mimeType = "image/png"
        }
        if name.debugDescription.localizedCaseInsensitiveContains(".mp4") {
            mimeType = "video/mp4"
        }
        if name.debugDescription.localizedCaseInsensitiveContains(".mov") {
            mimeType = "video/mov"
        }
        return mimeType
    }
}

extension Array {
    public func appending(_ suffix: Element) -> Array<Element> {
        var contents = self
        contents.append(suffix)
        return contents
    }
}

extension GTLRDriveService {
    func findFileID(forPath path: String, then: @escaping (String) -> (), orElse: @escaping () -> ()) {
        self.findFileID(forPath: path, inParent: nil, then: then, orElse: orElse)
    }
    
    func findFileID(forPath path: String, inParent parentID: String?, then: @escaping (String) -> (), orElse: @escaping () -> ()) {
        var path = path
        
        if path.starts(with: "/") {
            path.removeFirst()
        }
        
        let parts = path.components(separatedBy: GoogleDriveFile.pathSeparator)
        
        if parts.count == 1 {
            self.queryFileID(forFilename: path, inParent: parentID, then: then, orElse: orElse)
        } else if let first = parts.first {
            self.queryFileID(
                forFilename: first,
                inParent: parentID,
                then: { fileID in
                    let remainder = parts.dropFirst().joined(separator: GoogleDriveFile.pathSeparator)
                    self.findFileID(forPath: remainder, inParent: fileID, then: then, orElse: orElse)
                },
                orElse: orElse
            )
        }
    }
    
    func queryFileID(forFilename filename: String, inParent parentID: String?, then: @escaping (String) -> (), orElse: @escaping () -> ()) {
        
        let parentID: String = parentID ?? "root"
        
        let query = GTLRDriveQuery_FilesList.query()
        query.q = "name = '\(filename)' and '\(parentID)' in parents"
        query.fields = "files(id)"
        
        self.executeQuery(query, completionHandler: { (ticket, result, err) in
            let matchingFiles = (result as? GTLRDrive_FileList)?.files ?? []
            
            if let file = matchingFiles.first, let id = file.identifier {
                then(id)
            } else {
                orElse()
            }
        })
    }
    
    func listContents(using fileID: String, afterCursor cursor: String? = nil, then: @escaping ([SyncFileMetadata]?, String?, Error?) -> ()) {
        let query = GTLRDriveQuery_FilesList.query()
        query.q = "'\(fileID)' in parents"
        query.pageSize = 1000
        query.fields = "files(name,size),nextPageToken"
        query.pageToken = cursor
        
        self.executeQuery(query, completionHandler: { (ticket, what, err) in
            if let err = err {
                then(nil, nil, err)
                return
            }
            
            var results: [SyncFileMetadata] = []
           
            guard let list = (what as? GTLRDrive_FileList) else {
                then(nil, nil, GoogleClientError.invalidResponse)
                return
            }
            
            let all = list.files ?? []
            
            for file in all {
                if let size = file.size, let name = file.name {
                    results.append(SyncFileMetadata(size: UInt64(truncating: size), name: name))
                }
            }
            
            let cursor = list.nextPageToken
            
            DispatchQueue.main.async {
                then(results, cursor, nil)
            }
        })
    }

    func doUpload(data: Data, named name: String, inParent parentID: String, then: @escaping (String?) -> ()) {
        let mimeType = GoogleDriveFile.mimeType(basedOn: name)
        
        let metadata = GTLRDrive_File()
        metadata.name = name
        metadata.mimeType = mimeType
        metadata.parents = [parentID]
        
        let params = GTLRUploadParameters(data: data , mimeType: mimeType)
        params.shouldUploadWithSingleRequest = true
        
        let query = GTLRDriveQuery_FilesCreate.query(withObject: metadata, uploadParameters: params)
        query.fields = "id"
        
        self.executeQuery(query, completionHandler: { (ticket, what, err) in
            if let err = err {
                then(err.localizedDescription)
            } else {
                then(nil)
            }
        })
    }
}

enum GoogleClientError: Error {
    case invalidResponse
}
