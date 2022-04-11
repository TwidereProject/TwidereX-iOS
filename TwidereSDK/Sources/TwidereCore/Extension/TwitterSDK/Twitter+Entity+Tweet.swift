//
//  Twitter+Entity+Tweet.swift
//  
//
//  Created by MainasuK on 2022-3-31.
//

import Foundation
import TwitterSDK

extension Twitter.Entity.Tweet {
    public var statusURL: URL {
        return URL(string: "https://twitter.com/\(user.screenName)/status/\(idStr)")!
    }
}
