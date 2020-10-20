//
//  File.swift
//  
//
//  Created by Cirno MainasuK on 2020-10-19.
//

import Foundation

extension Twitter.Response.V2 {
    public class DictContent {
        public let tweetDict: [Twitter.Entity.V2.Tweet.ID: Twitter.Entity.V2.Tweet]
        public let userDict: [Twitter.Entity.V2.User.ID: Twitter.Entity.V2.User]
        // TODO:
        
        public init(
            tweetDict: [Twitter.Entity.V2.Tweet.ID: Twitter.Entity.V2.Tweet],
            userDict: [Twitter.Entity.V2.User.ID: Twitter.Entity.V2.User]
        ) {
            self.tweetDict = tweetDict
            self.userDict = userDict
        }
        
        public convenience init(
            tweets: [Twitter.Entity.V2.Tweet],
            users: [Twitter.Entity.V2.User]
        ) {
            var tweetDict: [Twitter.Entity.V2.Tweet.ID: Twitter.Entity.V2.Tweet] = [:]
            for tweet in tweets {
                guard tweetDict[tweet.id] == nil else {
                    assertionFailure()
                    continue
                }
                tweetDict[tweet.id] = tweet
            }
            
            var userDict: [Twitter.Entity.V2.User.ID: Twitter.Entity.V2.User] = [:]
            for user in users {
                guard userDict[user.id] == nil else {
                    assertionFailure()
                    continue
                }
                
                userDict[user.id] = user
            }
            
            self.init(tweetDict: tweetDict, userDict: userDict)
        }
    }
}
