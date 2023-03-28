//
//  APIService+Status+Conversation.swift
//  
//
//  Created by MainasuK on 2023/3/28.
//

import Foundation
import CoreDataStack
import TwitterSDK

extension APIService {
    public func twitterStatusConversation(
        conversationRootStatusID: Twitter.Entity.V2.Tweet.ID,
        query: Twitter.API.V2.Status.Timeline.TimelineQuery,
        guestAuthentication: Twitter.API.Guest.GuestAuthorization,
        authenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<Twitter.API.V2.Status.Timeline.ConversationContent> {
        let response = try await Twitter.API.V2.Status.Timeline.conversation(
            session: URLSession(configuration: .ephemeral),
            statusID: conversationRootStatusID,
            query: query,
            authorization: guestAuthentication
        )
        
        let statusIDs = response.value.globalObjects.tweets.map { $0.idStr }
        
        _ = try await twitterStatus(
            statusIDs: statusIDs,
            authenticationContext: authenticationContext
        )
        
        return response
    }
}
