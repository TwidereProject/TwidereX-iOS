//
//  Mastodon+Response+Content.swift
//  
//
//  Created by MainasuK on 2022-6-28.
//

#if DEBUG
import os.log
import Foundation
import MastodonSDK

extension Mastodon.Response.Content {
    public func logRateLimit(category: String? = nil) {
        guard let date = self.date, let rateLimit = self.rateLimit else { return }
        
        let responseNetworkDate = date
        let resetTimeInterval = rateLimit.reset.timeIntervalSince(responseNetworkDate)
        
        let resetTimeIntervalInMin = resetTimeInterval / 60.0
        let category = [
            "RateLimit", category
        ]
        .compactMap { $0 }
        .joined(separator: "|")
        os_log(.info, log: OSLog.api, "%{public}s[%{public}ld], %{public}s: [%s]  %{public}ld/%{public}ld, reset at %{public}s, left: %.2fm (%.2fs)", ((#file as NSString).lastPathComponent), #line, #function, category, rateLimit.remaining, rateLimit.limit, rateLimit.reset.debugDescription, resetTimeIntervalInMin, resetTimeInterval)
    }
}
#endif
