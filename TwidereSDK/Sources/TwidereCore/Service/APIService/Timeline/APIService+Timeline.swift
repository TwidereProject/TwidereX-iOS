//
//  APIService+Timeline.swift
//  
//
//  Created by MainasuK on 2022-1-13.
//

import os.log
import Foundation
import CoreDataStack
import MastodonSDK
import func QuartzCore.CACurrentMediaTime

extension APIService {
    
    struct TimelinePersistContext {
        let kind: Feed.Kind
        let maxID: Mastodon.Entity.Status.ID?
        let authenticationContext: MastodonAuthenticationContext
    }
    
    func persistMastodonTimelineResponse(
        response: Mastodon.Response.Content<[Mastodon.Entity.Status]>,
        persistContext: TimelinePersistContext
    ) async throws {
        #if DEBUG
        // log time cost
        let start = CACurrentMediaTime()
        defer {
            // log rate limit
            // response.logRateLimit()
            
            let end = CACurrentMediaTime()
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: persist cost %.2fs", ((#file as NSString).lastPathComponent), #line, #function, end - start)
        }
        #endif
        
        let managedObjectContext = backgroundManagedObjectContext
        try await managedObjectContext.performChanges {
            let me = persistContext.authenticationContext.authenticationRecord.object(in: managedObjectContext)?.user
            
            // persist MastodonStatus
            var statusArray: [MastodonStatus] = []
            for entity in response.value {
                let persistContext = Persistence.MastodonStatus.PersistContext(
                    domain: persistContext.authenticationContext.domain,
                    entity: entity,
                    me: me,
                    statusCache: nil,   // TODO:
                    userCache: nil,
                    networkDate: response.networkDate
                )
                
                let result = Persistence.MastodonStatus.createOrMerge(
                    in: managedObjectContext,
                    context: persistContext
                )
                let status = result.status
                statusArray.append(status)
                
                #if DEBUG
                result.log()
                #endif
            }   // end for … in
            
            // locate anchor status
            let anchorStatus: MastodonStatus? = {
                guard let maxID = persistContext.maxID else { return nil }
                let request = MastodonStatus.sortedFetchRequest
                request.predicate = MastodonStatus.predicate(
                    domain: persistContext.authenticationContext.domain,
                    id: maxID
                )
                request.fetchLimit = 1
                return try? managedObjectContext.fetch(request).first
            }()
            // update hasMore flag for anchor status
            let acct = Feed.Acct.mastodon(
                domain: persistContext.authenticationContext.domain,
                userID: persistContext.authenticationContext.userID
            )
            if let anchorStatus = anchorStatus,
               let feed = anchorStatus.feed(kind: persistContext.kind, acct: acct) {
                feed.update(hasMore: false)
            }
            
            switch persistContext.kind {
            case .home:
                // persist relationship
                let sortedStatuses = statusArray.sorted(by: { $0.createdAt < $1.createdAt })
                let oldestStatus = sortedStatuses.first
                for status in sortedStatuses {
                    // set friendship
                    if let me = me {
                        status.author.update(isFollow: true, by: me)
                    }
                    
                    // attach to Feed
                    let _feed = status.feed(kind: persistContext.kind, acct: acct)
                    if let feed = _feed {
                        feed.update(updatedAt: response.networkDate)
                    } else {
                        let feedProperty = Feed.Property(
                            acct: acct,
                            kind: persistContext.kind,
                            hasMore: false,
                            createdAt: status.createdAt,
                            updatedAt: response.networkDate
                        )
                        let feed = Feed.insert(into: managedObjectContext, property: feedProperty)
                        status.attach(feed: feed)
                        
                        // set hasMore on oldest status if is new feed
                        if status === oldestStatus {
                            feed.update(hasMore: true)
                        }
                    }
                }   // end for … in

            default:
                break
            }

            
        }   // end managedObjectContext.performChanges
    }   // end func
}
