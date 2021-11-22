//
//  DateTimeProvider.swift
//  
//
//  Created by MainasuK on 2021/11/22.
//

import Foundation

public protocol DateTimeProvider {
    func shortTimeAgoSinceNow(to date: Date?) -> String?
}
