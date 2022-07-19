//
//  String+Escape.swift
//  NotificationService
//
//  Created by MainasuK on 2022-7-7.
//  Copyright © 2022 Twidere. All rights reserved.
//

import Foundation

extension String {
    func escape() -> String {
        return self
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&apos;", with: "'")
            .replacingOccurrences(of: "&#39;", with: "’")

    }
}
