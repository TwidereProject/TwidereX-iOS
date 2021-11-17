//
//  APIService+HashtagTimeline.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-11-9.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import Combine
import CoreData
import CoreDataStack
import CommonOSLog
import MastodonSDK

extension APIService {
    
    func mastodonHashtagTimeline(
        hashtag: String,
        query: Mastodon.API.Timeline.TimelineQuery,
        authenticationContext: MastodonAuthenticationContext
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Status]> {
        let response = try await Mastodon.API.Timeline.hashtag(
            session: session,
            domain: authenticationContext.domain,
            hashtag: hashtag,
            query: query,
            authorization: authenticationContext.authorization
        )

        let managedObjectContext = backgroundManagedObjectContext
        try await managedObjectContext.performChanges {
            let _me = authenticationContext.authenticationRecord.object(in: managedObjectContext)?.user
            // persist statuses
            for status in response.value {
                let result = Persistence.MastodonStatus.createOrMerge(
                    in: managedObjectContext,
                    context: Persistence.MastodonStatus.PersistContext(
                        domain: authenticationContext.domain,
                        entity: status,
                        me: _me,
                        statusCache: nil,
                        userCache: nil,
                        networkDate: response.networkDate
                    )
                )
                #if DEBUG
                result.log()
                #endif
            }
        }   // try await managedObjectContext.performChanges
        
        return response
    }
    
}
