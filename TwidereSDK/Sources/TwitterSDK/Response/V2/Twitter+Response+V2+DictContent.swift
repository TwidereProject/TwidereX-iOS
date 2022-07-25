//
//  Twitter+Response+V2+DictContent.swift
//  
//
//  Created by Cirno MainasuK on 2020-10-19.
//

import Foundation
import OrderedCollections

extension Twitter.Response.V2 {
    
    public class DictContent {
        public let tweetDict: OrderedDictionary<Twitter.Entity.V2.Tweet.ID, Twitter.Entity.V2.Tweet>
        public let userDict: OrderedDictionary<Twitter.Entity.V2.User.ID, Twitter.Entity.V2.User>
        public let mediaDict: OrderedDictionary<Twitter.Entity.V2.Media.ID, Twitter.Entity.V2.Media>
        public let placeDict: OrderedDictionary<Twitter.Entity.V2.Place.ID, Twitter.Entity.V2.Place>
        public let pollDict: OrderedDictionary<Twitter.Entity.V2.Tweet.Poll.ID, Twitter.Entity.V2.Tweet.Poll>
        
        public init(
            tweetDict: OrderedDictionary<Twitter.Entity.V2.Tweet.ID, Twitter.Entity.V2.Tweet>,
            userDict: OrderedDictionary<Twitter.Entity.V2.User.ID, Twitter.Entity.V2.User>,
            mediaDict: OrderedDictionary<Twitter.Entity.V2.Media.ID, Twitter.Entity.V2.Media>,
            placeDict: OrderedDictionary<Twitter.Entity.V2.Place.ID, Twitter.Entity.V2.Place>,
            pollDict: OrderedDictionary<Twitter.Entity.V2.Tweet.Poll.ID, Twitter.Entity.V2.Tweet.Poll>
        ) {
            self.tweetDict = tweetDict
            self.userDict = userDict
            self.mediaDict = mediaDict
            self.placeDict = placeDict
            self.pollDict = pollDict
        }
        
        public convenience init(
            tweets: [Twitter.Entity.V2.Tweet],
            users: [Twitter.Entity.V2.User],
            media: [Twitter.Entity.V2.Media],
            places: [Twitter.Entity.V2.Place],
            polls: [Twitter.Entity.V2.Tweet.Poll]
        ) {
            self.init(
                tweetDict: Twitter.Response.V2.DictContent.collect(array: tweets),
                userDict: Twitter.Response.V2.DictContent.collect(array: users),
                mediaDict: Twitter.Response.V2.DictContent.collect(array: media),
                placeDict: Twitter.Response.V2.DictContent.collect(array: places),
                pollDict: Twitter.Response.V2.DictContent.collect(array: polls)
            )
        }
    }
    
}

extension Twitter.Response.V2.DictContent {
    
    private static func collect<T: Identifiable>(array: [T]) -> OrderedDictionary<T.ID, T> {
        var dict: OrderedDictionary<T.ID, T> = [:]
        for element in array {
            guard dict[element.id] == nil else {
                continue
            }
            dict[element.id] = element
        }
        return dict
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
    
    public func place(for tweet: Twitter.Entity.V2.Tweet) -> Twitter.Entity.V2.Place? {
        guard let placeID = tweet.geo?.placeID else { return nil }
        return placeDict[placeID]
    }
    
    public func poll(for tweet: Twitter.Entity.V2.Tweet) -> Twitter.Entity.V2.Tweet.Poll? {
        guard let pollID = tweet.attachments?.pollIDs?.first else { return nil }
        return pollDict[pollID]
    }
    
}
