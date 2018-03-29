//
//  DispatchTime+TimeInterval.swift
//  SwiftyDropboxSync
//
//  Created by Lacy Rhoades on 12/1/17.
//  Copyright © 2017 Lacy Rhoades. All rights reserved.
//

import Foundation

extension DispatchTime {
    static func seconds(_ seconds: TimeInterval) -> DispatchTime {
        return DispatchTime.now() + seconds
    }
}
