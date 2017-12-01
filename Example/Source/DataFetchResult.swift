//
//  DataFetchResult.swift
//  SwiftyDropboxSync
//
//  Created by Lacy Rhoades on 11/30/17.
//  Copyright © 2017 Lacy Rhoades. All rights reserved.
//

import Foundation

struct DataFetchResult {
    var data: Data? = nil
    var error: String? = nil
    
    init() {
    }
    
    init(error: String) {
        self.error = error
    }
    
    var isEmpty: Bool {
        return self.data?.isEmpty ?? true
    }
}
