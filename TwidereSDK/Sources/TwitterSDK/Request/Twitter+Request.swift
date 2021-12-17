//
//  Twitter+Request.swift
//  TwitterAPI
//
//  Created by Cirno MainasuK on 2020-9-15.
//

import Foundation

extension Twitter.Request {
    
}

// TODO: unit tests
extension Twitter.Request {
    static let expansions: [Twitter.Request.Expansions] = [
        .attachmentsPollIDs,
        .attachmentsMediaKeys,
        .authorID,
        .entitiesMentionsUsername,
        .geoPlaceID,
        .inReplyToUserID,
        .referencedTweetsID,
        .referencedTweetsIDAuthorID
    ]
    static let tweetsFields: [Twitter.Request.TwitterFields] = [
        .attachments,
        .authorID,
        .contextAnnotations,
        .conversationID,
        .created_at,
        .entities,
        .geo,
        .id,
        .inReplyToUserID,
        .lang,
        .publicMetrics,
        .possiblySensitive,
        .referencedTweets,
        .source,
        .text,
        .withheld,
    ]
    static let userFields: [Twitter.Request.UserFields] = [
        .createdAt,
        .description,
        .entities,
        .id,
        .location,
        .name,
        .pinnedTweetID,
        .profileImageURL,
        .protected,
        .publicMetrics,
        .url,
        .username,
        .verified,
        .withheld
    ]
    static let mediaFields: [Twitter.Request.MediaFields] = [
        .durationMS,
        .height,
        .mediaKey,
        .previewImageURL,
        .type,
        .url,
        .width,
        .publicMetrics,
    ]
    static let placeFields: [Twitter.Request.PlaceFields] = [
        .containedWithin,
        .country,
        .countryCode,
        .fullName,
        .geo,
        .id,
        .name,
        .placeType,
    ]
}
