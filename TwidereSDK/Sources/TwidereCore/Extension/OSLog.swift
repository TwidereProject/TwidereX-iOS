//
//  OSLog.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-4.
//

import os
import Foundation
import CommonOSLog

extension OSLog {
    public static let api: OSLog = {
        #if DEBUG
        return OSLog(subsystem: OSLog.subsystem + ".api", category: "api")
        #else
        return OSLog.disabled
        #endif
    }()
}
