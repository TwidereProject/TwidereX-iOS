//
//  TwitterResponseContent.swift
//  TwitterResponseContent
//
//  Created by Cirno MainasuK on 2021-8-24.
//  Copyright © 2021 Twidere. All rights reserved.
//


#if DEBUG
import os.log
import Foundation
import TwitterSDK

extension Twitter.Response.Content {
    public func logRateLimit() {
        guard let date = self.date, let rateLimit = self.rateLimit else { return }
        
        let responseNetworkDate = date
        let resetTimeInterval = rateLimit.reset.timeIntervalSince(responseNetworkDate)
        
        let resetTimeIntervalInMin = resetTimeInterval / 60.0
        os_log(.info, log: OSLog.api, "%{public}s[%{public}ld], %{public}s: [RateLimit]  %{public}ld/%{public}ld, reset at %{public}s, left: %.2fm (%.2fs)", ((#file as NSString).lastPathComponent), #line, #function, rateLimit.remaining, rateLimit.limit, rateLimit.reset.debugDescription, resetTimeIntervalInMin, resetTimeInterval)
    }
}
#endif
