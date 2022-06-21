//
//  TwitterReplySettings.swift
//  
//
//  Created by MainasuK on 2022-6-16.
//

import Foundation
import CoreDataStack
import TwitterSDK

extension TwitterReplySettings {
    public var typed: Twitter.Entity.V2.Tweet.ReplySettings? {
        .init(rawValue: value)
    }
}
