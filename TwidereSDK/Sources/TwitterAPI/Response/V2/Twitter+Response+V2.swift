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
        public let mediaDict: [Twitter.Entity.V2.Media.ID: Twitter.Entity.V2.Media]
        
        public init(
            tweetDict: [Twitter.Entity.V2.Tweet.ID: Twitter.Entity.V2.Tweet],
            userDict: [Twitter.Entity.V2.User.ID: Twitter.Entity.V2.User],
            mediaDict: [Twitter.Entity.V2.Media.ID: Twitter.Entity.V2.Media]
        ) {
            self.tweetDict = tweetDict
            self.userDict = userDict
            self.mediaDict = mediaDict
        }
        
        public convenience init(
            tweets: [Twitter.Entity.V2.Tweet],
            users: [Twitter.Entity.V2.User],
            media: [Twitter.Entity.V2.Media]
        ) {
            var tweetDict: [Twitter.Entity.V2.Tweet.ID: Twitter.Entity.V2.Tweet] = [:]
            for tweet in tweets {
                guard tweetDict[tweet.id] == nil else {
                    continue
                }
                tweetDict[tweet.id] = tweet
            }
            
            var userDict: [Twitter.Entity.V2.User.ID: Twitter.Entity.V2.User] = [:]
            for user in users {
                guard userDict[user.id] == nil else {
                    continue
                }
                userDict[user.id] = user
            }
            
            var mediaDict: [Twitter.Entity.V2.Media.ID: Twitter.Entity.V2.Media] = [:]
            for media in media {
                guard mediaDict[media.mediaKey] == nil else {
                    continue
                }
                mediaDict[media.mediaKey] = media
            }
            
            self.init(tweetDict: tweetDict, userDict: userDict, mediaDict: mediaDict)
        }
    }
}

extension Twitter.Response.V2.DictContent {
    public func media(for tweet: Twitter.Entity.V2.Tweet) -> [Twitter.Entity.V2.Media]? {
        guard let mediaKeys = tweet.attachments?.mediaKeys else { return nil }
        var array: [Twitter.Entity.V2.Media] = []
        for mediaKey in mediaKeys {
            guard let media = mediaDict[mediaKey] else { continue }
            array.append(media)
        }
        guard !array.isEmpty else { return nil }
        return array
    }
}
