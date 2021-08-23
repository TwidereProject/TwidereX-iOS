//
//  APIService+HomeTimeline.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-3.
//

import Foundation
import Combine
import CoreData
import CoreDataStack
import CommonOSLog
import DateToolsSwift
import TwitterSDK

extension APIService {
    
    static let homeTimelineRequestWindowInSec: TimeInterval = 15 * 60
    static let homeTimelineRequestFetchLimit: Int = 100
    
    func twitterHomeTimeline(
        maxID: Twitter.Entity.Tweet.ID? = nil,
        authenticationContext: AuthenticationService.TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<[Twitter.Entity.Tweet]> {
        let count = APIService.homeTimelineRequestFetchLimit
        let query = Twitter.API.Timeline.TimelineQuery(count: count, maxID: maxID)
        
        let response = try await Twitter.API.Timeline.homeTimeline(
            session: session,
            query: query,
            authorization: authenticationContext.authorization
        )
        
        let managedObjectContext = backgroundManagedObjectContext
        try await managedObjectContext.performChanges {
            // persist TwitterStatus
            var twitterStatusArray: [TwitterStatus] = []
            for entity in response.value {
                let persistContext = Persistence.TwitterStatus.PersistContext(
                    entity: entity,
                    statusCache: nil,   // TODO:
                    userCache: nil,
                    networkDate: response.networkDate
                )
                let (twitterStatus, _) = Persistence.TwitterStatus.createOrMerge(
                    in: managedObjectContext,
                    context: persistContext
                )
                twitterStatusArray.append(twitterStatus)
            }
        
            // persist Feed relationship
            let acct = Feed.Acct.twitter(userID: authenticationContext.userID).value
            for status in twitterStatusArray {
                let _feed = status.feeds.first { feed in
                    feed.kind == .home && feed.acct == acct
                }
                if let feed = _feed {
                    feed.update(updatedAt: response.networkDate)
                } else {
                    let feedProperty = Feed.Property(
                        acct: acct,
                        kindRaw: Feed.Kind.home.rawValue,
                        hasMore: false,
                        createdAt: status.createdAt,
                        updatedAt: response.networkDate
                    )
                    let feed = Feed.insert(into: managedObjectContext, property: feedProperty)
                    status.attach(feed: feed)
                }
            }
        }
        
        return response
    }
        
    
    
    // incoming tweet - retweet relationship could be:
    // A1. incoming tweet NOT in local timeline, retweet NOT  in local (never see tweet and retweet)
    // A2. incoming tweet NOT in local timeline, retweet      in local (never see tweet but saw retweet before)
    // A3. incoming tweet     in local timeline, retweet MUST in local (saw tweet before)
    @available(*, deprecated, message: "")
    func twitterHomeTimeline(
        count: Int = APIService.homeTimelineRequestFetchLimit,
        maxID: String? = nil,
        twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox
    ) -> AnyPublisher<Twitter.Response.Content<[Twitter.Entity.Tweet]>, Error> {
        let authorization = twitterAuthenticationBox.twitterAuthorization
        let requestTwitterUserID = twitterAuthenticationBox.twitterUserID
        
        // throttle latest request for API limit
        if maxID == nil {
            guard homeTimelineRequestThrottler.available(windowSizeInSec: APIService.homeTimelineRequestWindowInSec) else {
                return Fail(error: APIError.implicit(.requestThrottle))
                    .delay(for: .milliseconds(Int.random(in: 1000..<2000)), scheduler: DispatchQueue.main)
                    .eraseToAnyPublisher()
            }
        }
                
        os_log("%{public}s[%{public}ld], %{public}s: fetch home timeline…", ((#file as NSString).lastPathComponent), #line, #function)
        let query = Twitter.API.Timeline.TimelineQuery(count: count, maxID: maxID)
        return Twitter.API.Timeline.homeTimeline(session: session, authorization: authorization, query: query)
            .map { response -> AnyPublisher<Twitter.Response.Content<[Twitter.Entity.Tweet]>, Error> in
                let log = OSLog.api
                
                // update throttler
                if let responseTime = response.responseTime {
                    os_log(.info, log: log, "%{public}s[%{public}ld], %{public}s: response cost %{public}ldms", ((#file as NSString).lastPathComponent), #line, #function, responseTime)
                }
                if let date = response.date, let rateLimit = response.rateLimit {
                    let currentTimeInterval = CACurrentMediaTime()
                    let responseNetworkDate = date
                    let resetTimeInterval = rateLimit.reset.timeIntervalSince(responseNetworkDate)
                    let resetAtTimeInterval = currentTimeInterval + resetTimeInterval
                    
                    self.homeTimelineRequestThrottler.rateLimit = APIService.RequestThrottler.RateLimit(
                        limit: rateLimit.limit,
                        remaining: rateLimit.remaining,
                        resetAt: resetAtTimeInterval
                    )
                    
                    let resetTimeIntervalInMin = resetTimeInterval / 60.0
                    os_log(.info, log: log, "%{public}s[%{public}ld], %{public}s: [API RateLimit]  %{public}ld/%{public}ld, reset at %{public}s, left: %.2fm (%.2fs)", ((#file as NSString).lastPathComponent), #line, #function, rateLimit.remaining, rateLimit.limit, rateLimit.reset.debugDescription, resetTimeIntervalInMin, resetTimeInterval)
                }
                
                // update database
                return APIService.Persist.persistTweets(
                    managedObjectContext: self.backgroundManagedObjectContext,
                    query: query,
                    response: response,
                    persistType: .homeTimeline,
                    requestTwitterUserID: requestTwitterUserID,
                    log: log
                )
                .setFailureType(to: Error.self)
                .tryMap { result -> Twitter.Response.Content<[Twitter.Entity.Tweet]> in
                    switch result {
                    case .success:
                        return response
                    case .failure(let error):
                        throw error
                    }
                }
                .eraseToAnyPublisher()
            }
            .switchToLatest()
            .handleEvents(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                switch completion {
                case .failure(let error):
                    if let responseError = error as? Twitter.API.Error.ResponseError {
                        if case .accountIsTemporarilyLocked = responseError.twitterAPIError {
                            self.error.send(.explicit(.twitterResponseError(responseError)))
                        }
                    }
                    
                case .finished:
                    break
                }
            })
            .eraseToAnyPublisher()
    }
    
}
