//
//  TwitterEntity.swift
//  TwitterEntity
//
//  Created by Cirno MainasuK on 2021-9-9.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import CoreDataStack
import TwitterSDK

extension TwitterEntity {
    public convenience init(entity: Twitter.Entity.User.Entities.URL?) {
        self.init(
            urls: entity?.urls.map { urls in urls.map { URLEntity(entity: $0) } },
            hashtags: nil,
            mentions: nil
        )
    }
    
    public convenience init(entity: Twitter.Entity.User.Entities.Description?) {
        self.init(
            urls: entity?.urls.map { urls in urls.map { URLEntity(entity: $0) } },
            hashtags: nil,
            mentions: nil
        )
    }
    
    public convenience init(
        entity: Twitter.Entity.Tweet.Entities?,
        extendedEntity: Twitter.Entity.ExtendedEntities?
    ) {
        let urls: [URLEntity]? = {
            var properties: [URLEntity] = []
            let entities = entity?.urls.map { urls in urls.compactMap { URLEntity(entity: $0) } } ?? []
            properties.append(contentsOf: entities)
            let extendedEntities = extendedEntity?.media?.compactMap { media in URLEntity(entity: media) } ?? []
            properties.append(contentsOf: extendedEntities)
            guard !properties.isEmpty else { return nil }
            return properties
        }()
            
        self.init(
            urls: urls,
            hashtags: entity?.hashtags.map { hashtags in hashtags.map { Hashtag(entity: $0) } },
            mentions: entity?.userMentions.flatMap { mentions in mentions.map { Mention(entity: $0) } }
        )
    }
    
    public convenience init(entity: Twitter.Entity.V2.Entities?) {
        self.init(
            urls: entity?.urls.map { urls in urls.map { URLEntity(entity: $0) } },
            hashtags: entity?.hashtags.map { hashtags in  hashtags.map { Hashtag(entity: $0) } },
            mentions: entity?.mentions.flatMap { mentions in mentions.map { Mention(entity: $0) } }
        )
    }
}

extension TwitterEntity.URLEntity {
    public init(entity: Twitter.Entity.User.Entities.URLNode) {
        self.init(
            start: entity.indices?.first ?? 0,
            end: entity.indices?.last ?? 0,
            url: entity.url ?? "",
            expandedURL: entity.expandedURL,
            displayURL: entity.displayURL,
            status: nil,
            title: nil,
            description: nil,
            unwoundURL: nil
        )
    }
    
    public init?(entity: Twitter.Entity.Tweet.Entities.URL) {
        guard let url = entity.url else { return nil }
        self.init(
            start: entity.indices?.first ?? 0,
            end: entity.indices?.last ?? 0,
            url: url,
            expandedURL: entity.expandedURL,
            displayURL: entity.displayURL,
            status: nil,
            title: nil,
            description: nil,
            unwoundURL: nil
        )
    }
    
    public init?(entity: Twitter.Entity.ExtendedEntities.Media) {
        guard let url = entity.url else { return nil }
        self.init(
            start: entity.indices?.first ?? 0,
            end: entity.indices?.last ?? 0,
            url: url,
            expandedURL: entity.expandedURL,
            displayURL: entity.displayURL,
            status: nil,
            title: nil,
            description: nil,
            unwoundURL: nil
        )
    }
    
    public init(entity: Twitter.Entity.V2.Entities.URLNode) {
        self.init(
            start: entity.start,
            end: entity.end,
            url: entity.url,
            expandedURL: entity.expandedURL,
            displayURL: entity.displayURL,
            status: entity.status,
            title: entity.title,
            description: entity.description,
            unwoundURL: entity.unwoundURL
        )
    }
}

extension TwitterEntity.Hashtag {
    public init(entity: Twitter.Entity.Tweet.Entities.Hashtag) {
        self.init(
            start: entity.indices?.first ?? 0,
            end: entity.indices?.last ?? 0,
            tag: entity.text ?? ""
        )
    }
    
    public init(entity: Twitter.Entity.V2.Entities.Hashtag) {
        self.init(
            start: entity.start,
            end: entity.end,
            tag: entity.tag
        )
    }
}

extension TwitterEntity.Mention {
    public init(entity: Twitter.Entity.Tweet.Entities.UserMention) {
        self.init(
            start: entity.indices?.first ?? 0,
            end: entity.indices?.last ?? 0,
            username: entity.screenName ?? "",
            id: entity.idStr
        )
    }
    
    public init(entity: Twitter.Entity.V2.Entities.Mention) {
        self.init(
            start: entity.start,
            end: entity.end,
            username: entity.username,
            id: entity.id   // not exist in early access
        )
    }
}
