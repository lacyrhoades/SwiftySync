//
//  Functions.swift
//  SwiftyDropboxSync
//
//  Created by Lacy Rhoades on 11/30/17.
//  Copyright © 2017 Lacy Rhoades. All rights reserved.
//

import Foundation

func currentQueueName() -> String {
    let name = __dispatch_queue_get_label(nil)
    return String(cString: name, encoding: .utf8) ?? "nil"
}
