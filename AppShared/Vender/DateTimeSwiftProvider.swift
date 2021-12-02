//
//  DateTimeSwiftProvider.swift
//  TwidereX
//
//  Created by MainasuK on 2021/11/22.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import TwidereCore
import DateToolsSwift

public class DateTimeSwiftProvider: DateTimeProvider {
    public func shortTimeAgoSinceNow(to date: Date?) -> String? {
        return date?.shortTimeAgoSinceNow
    }
    
    public init() { }
}
