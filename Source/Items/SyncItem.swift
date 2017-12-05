//
//  SyncItem.swift
//  SwiftyDropboxSync
//
//  Created by Lacy Rhoades on 11/30/17.
//  Copyright © 2017 Lacy Rhoades. All rights reserved.
//

import Foundation

public protocol SyncItem: Hashable {
    var filename: String { get }
    func fetchData() -> DataFetchResult
}
