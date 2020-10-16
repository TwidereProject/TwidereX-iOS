//
//  Twitter+API+ResponseContent.swift
//  
//
//  Created by Cirno MainasuK on 2020-10-16.
//

import Foundation

extension Twitter.API {
    public class ResponseContent {
        public let tweetDict: [Twitter.Entity.TweetV2.ID: Twitter.Entity.TweetV2]
        public let userDict: [Twitter.Entity.UserV2.ID: Twitter.Entity.UserV2]
        // TODO:

        public init(
            tweetDict: [Twitter.Entity.TweetV2.ID: Twitter.Entity.TweetV2],
            userDict: [Twitter.Entity.UserV2.ID: Twitter.Entity.UserV2]
        ) {
            self.tweetDict = tweetDict
            self.userDict = userDict
        }
    }
}
