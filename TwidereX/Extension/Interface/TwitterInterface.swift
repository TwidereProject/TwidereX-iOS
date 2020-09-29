//
//  TwitterInterface.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-29.
//

import Foundation
import CoreDataStack
import TwitterAPI

public protocol TweetInterface {
    
    typealias ID = String
    
    // Fundamental
    var createdAt: Date { get }
    var idStr: ID { get }
    var text: String { get }
    
    var userObject: TwitterUserInterface { get }
    var entities: Twitter.Entity.Entities { get }
    var extendedEntities: Twitter.Entity.ExtendedEntities? { get }
    var coordinates: Twitter.Entity.Coordinates? { get }
    var place: Twitter.Entity.Place? { get }
    var isFavorited: Bool { get }
    var favoriteCountInt: Int? { get }
    var isRetweeted: Bool { get }
    var retweetCountInt: Int? { get }
    var retweetObject: TweetInterface? { get }
    var quotedStatusIDStr: String? { get }
    var quoteObject: TweetInterface? { get }
    var source: String? { get }
    
}

extension Twitter.Entity.Tweet: TweetInterface {

    public var userObject: TwitterUserInterface {
        return user
    }

    public var isFavorited: Bool {
        return favorited ?? false
    }

    public var favoriteCountInt: Int? {
        return favoriteCount
    }

    public var isRetweeted: Bool {
        return retweeted ?? false
    }

    public var retweetCountInt: Int? {
        return retweetCount
    }
    
    public var retweetObject: TweetInterface? {
        return retweetedStatus
    }

    public var quoteObject: TweetInterface? {
        return quotedStatus
    }
}

extension Tweet: TweetInterface {
    
    public var userObject: TwitterUserInterface {
        return user
    }
    
    public var isFavorited: Bool {
        return favorited
    }

    public var favoriteCountInt: Int? {
        return favoriteCount.flatMap { Int(truncating: $0) }
    }

    public var isRetweeted: Bool {
        return retweeted
    }

    public var retweetCountInt: Int? {
        return retweetCount.flatMap { Int(truncating: $0) }
    }
    
    public var retweetObject: TweetInterface? {
        return retweet
    }
    
    public var quoteObject: TweetInterface? {
        return quote
    }

}
