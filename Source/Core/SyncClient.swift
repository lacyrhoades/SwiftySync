//
//  SyncClient.swift
//  SwiftySync
//
//  Created by Lacy Rhoades on 5/9/18.
//  Copyright © 2018 Lacy Rhoades. All rights reserved.
//

import Foundation

public protocol SyncClient {
    func delete(path: String, andThen: () -> ()) -> SyncRequest
    func listFolder(path: String) -> SyncRequest
    func listFolder(path: String, startingWithCursor: String) -> SyncRequest
    func upload(data: Data, toPath: String) -> SyncRequest
    func download(path: String) -> SyncRequest
    var requiresLeadingSlashForRoot: Bool { get }
}
