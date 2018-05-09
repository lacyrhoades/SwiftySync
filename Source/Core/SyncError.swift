//
//  SyncError.swift
//  SwiftySync
//
//  Created by Lacy Rhoades on 5/9/18.
//  Copyright © 2018 Lacy Rhoades. All rights reserved.
//

import Foundation

public struct SyncError: LocalizedError {
    var message: String
    init(message: String) {
        self.message = message
    }
}
