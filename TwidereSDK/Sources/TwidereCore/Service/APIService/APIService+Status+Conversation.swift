//
//  APIService+Status+Conversation.swift
//  
//
//  Created by MainasuK on 2023/3/28.
//

import os.log
import Foundation
import CoreDataStack
import TwitterSDK
import func QuartzCore.CACurrentMediaTime

extension APIService {
    public func twitterStatusConversation(
        conversationRootStatusID: Twitter.Entity.V2.Tweet.ID,
        query: Twitter.API.V2.Status.Timeline.ConvsersationQuery,
        authenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<Twitter.API.V2.Status.Timeline.ConversationContent> {
        let response = try await Twitter.API.V2.Status.Timeline.conversation(
            session: URLSession(configuration: .ephemeral),
            statusID: conversationRootStatusID,
            query: query,
            authorization: authenticationContext.authorization
        )
        
        #if DEBUG
        // log time cost
        let start = CACurrentMediaTime()
        defer {
            // log rate limit
            response.logRateLimit()
            
            let end = CACurrentMediaTime()
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: persist cost %.2fs", ((#file as NSString).lastPathComponent), #line, #function, end - start)
        }
        #endif

        let managedObjectContext = backgroundManagedObjectContext
        try await managedObjectContext.performChanges {
            let content = response.value
            let dictionary = Twitter.Response.V2.DictContent(
                tweets: content.includes?.tweets ?? [],
                users: content.includes?.users ?? [],
                media: content.includes?.media ?? [],
                places: content.includes?.places ?? [],
                polls: content.includes?.polls ?? []
            )
            let me = authenticationContext.authenticationRecord.object(in: managedObjectContext)?.user
            
            _ = Persistence.Twitter.persist(
                in: managedObjectContext,
                context: Persistence.Twitter.PersistContextV2(
                    dictionary: dictionary,
                    me: me,
                    networkDate: response.networkDate
                )
            )
        }   // end .performChanges { … }
        
        return response
    }
}
