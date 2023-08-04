//
//  AuthenticationContext+TwitterRateLimit.swift
//  
//
//  Created by MainasuK on 2022-8-12.
//

import Foundation
import TwidereCommon

extension AuthenticationContext {

    /// Client side rate limit
    public struct RateLimit: Codable {
        public var remaining: Int
        public let limit: Int
        public let reset: Date

        public init(limit: Int, remaining: Int, reset: Date) {
            self.limit = limit
            self.remaining = remaining
            self.reset = reset
        }

        /// Rate limit scope
        public enum Scope: String, Hashable {
            /// Post publish endpoint
            case publish
        }

    }

    private func key(scope: RateLimit.Scope) -> String {
        return "com.twidere.TwidereCore.TwitterRateLimit.\(scope.rawValue).\(acct.rawValue)"
    }

    public func rateLimit(scope: RateLimit.Scope) -> RateLimit? {
        let key = key(scope: scope)
        guard let encoded = AppSecret.keychain[key],
              let data = Data(base64Encoded: encoded),
              let rateLimit = try? JSONDecoder().decode(AuthenticationContext.RateLimit.self, from: data)
        else {
            return nil
        }
        
        return rateLimit
    }
    
    @discardableResult
    public func updateRateLimit(scope: RateLimit.Scope, now: Date) -> RateLimit {
        if var rateLimit = rateLimit(scope: scope), now < rateLimit.reset {
            rateLimit.remaining = max(0, rateLimit.remaining - 1)
            return rateLimit
        } else {
            let reset = Calendar.current.date(byAdding: .minute, value: 10, to: now) ?? now.addingTimeInterval(10 * 60)     // 10 min
            
            let limit = 5
            let rateLimit = RateLimit(
                limit: limit,
                remaining: limit - 1,
                reset: reset
            )
            
            let key = key(scope: scope)
            AppSecret.keychain[key] = {
                guard let data = try? JSONEncoder().encode(rateLimit) else { return nil }
                let encoded = data.base64EncodedString()
                return encoded
            }()
            
            return rateLimit
        }
    }

}
