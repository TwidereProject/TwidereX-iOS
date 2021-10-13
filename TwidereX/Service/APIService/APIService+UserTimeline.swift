//
//  APIService+UserTimeline.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-28.
//

import Foundation
import Combine
import CoreData
import CoreDataStack
import CommonOSLog
import TwitterSDK
import func QuartzCore.CACurrentMediaTime

extension APIService {
    
    static let userTimelineRequestFetchLimit: Int = 100

    func twitterUserTimeline(
        query: Twitter.API.Timeline.TimelineQuery,
        authenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<[Twitter.Entity.Tweet]> {
        let response = try await Twitter.API.Timeline.user(
            session: session,
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
            let user = authenticationContext.authenticationRecord.object(in: managedObjectContext)?.twitterUser
            // persist TwitterStatus
            for entity in response.value {
                let persistContext = Persistence.TwitterStatus.PersistContext(
                    entity: entity,
                    user: user,
                    statusCache: nil,
                    userCache: nil,
                    networkDate: response.networkDate
                )
                let _ = Persistence.TwitterStatus.createOrMerge(
                    in: managedObjectContext,
                    context: persistContext
                )
            }
        }
        
        return response
    }
    
}
