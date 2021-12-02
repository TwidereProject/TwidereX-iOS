//
//  APIService+Status+Publish.swift
//
//
//  Created by Cirno MainasuK on 2020-10-23.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack
import TwitterSDK
import MastodonSDK

extension APIService {
    
    public func publishTwitterStatus(
        content: String,
        mediaIDs: [String]?,
        placeID: String?,
        replyTo: ManagedObjectRecord<TwitterStatus>?,
        excludeReplyUserIDs: [TwitterUser.ID]?,
        twitterAuthenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<Twitter.Entity.Tweet> {
        let authorization = twitterAuthenticationContext.authorization
        let managedObjectContext = backgroundManagedObjectContext

        let mediaIDs: String? = mediaIDs?.joined(separator: ",")
        let excludeReplyUserIDs: String? = excludeReplyUserIDs?.joined(separator: ",")
        
        let replyToID: Twitter.Entity.V2.Tweet.ID? = await managedObjectContext.perform {
            guard let replyTo = replyTo?.object(in: managedObjectContext) else { return nil }
            return replyTo.id
        }
        
        let query = Twitter.API.Statuses.UpdateQuery(
            status: content,
            inReplyToStatusID: replyToID,
            autoPopulateReplyMetadata: replyToID != nil,
            excludeReplyUserIDs: excludeReplyUserIDs,
            mediaIDs: mediaIDs,
            latitude: nil,
            longitude: nil,
            placeID: placeID
        )
        
        let response = try await Twitter.API.Statuses.update(
            session: session,
            query: query,
            authorization: authorization
        )
        
        return response
    }
    
}

extension APIService {
    public func publishMastodonStatus(
        query: Mastodon.API.Status.PublishStatusQuery,
        mastodonAuthenticationContext: MastodonAuthenticationContext
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Status> {
        let domain = mastodonAuthenticationContext.domain
        let authorization = mastodonAuthenticationContext.authorization
        
        let response = try await Mastodon.API.Status.publish(
            session: session,
            domain: domain,
            idempotencyKey: nil,    // TODO:
            query: query,
            authorization: authorization
        )
        
        return response
    }
}

extension APIService {
    
    @available(*, deprecated, message: "")
    func delete(
        tweetObjectID: NSManagedObjectID,
        twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox
    ) -> AnyPublisher<Twitter.Response.Content<Twitter.Entity.Tweet>, Error> {
        fatalError()
//        let authorization = twitterAuthenticationBox.twitterAuthorization
//        let managedObjectContext = backgroundManagedObjectContext
//        
//        let query = Future<Twitter.API.Statuses.DestroyQuery, Never> { promise in
//            let tweet = managedObjectContext.object(with: tweetObjectID) as! Tweet
//            let query = Twitter.API.Statuses.DestroyQuery(id: tweet.id)
//            promise(.success(query))
//        }
//        
//        let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
//        let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
//        
//        return query
//            .setFailureType(to: Error.self)
//            .flatMap { query -> AnyPublisher<Twitter.Response.Content<Twitter.Entity.Tweet>, Error> in
//                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: delete tweet %s …", ((#file as NSString).lastPathComponent), #line, #function, query.id)
//                impactFeedbackGenerator.prepare()
//                impactFeedbackGenerator.impactOccurred()
//                return Twitter.API.Statuses.destroy(session: self.session, authorization: authorization, query: query)
//            }
//            .map { response -> AnyPublisher<Twitter.Response.Content<Twitter.Entity.Tweet>, Error> in
//                let tweet = response.value
//                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: delete tweet %s success", ((#file as NSString).lastPathComponent), #line, #function, tweet.idStr)
//                return managedObjectContext.performChanges {
//                    let tweet = managedObjectContext.object(with: tweetObjectID) as! Tweet
//                    tweet.softDelete()
//                }
//                .setFailureType(to: Error.self)
//                .tryMap { result -> Twitter.Response.Content<Twitter.Entity.Tweet> in
//                    switch result {
//                    case .success:
//                        return response
//                    case .failure(let error):
//                        throw error
//                    }
//                }
//                .eraseToAnyPublisher()
//            }
//            .switchToLatest()
//            .handleEvents(receiveCompletion: { completion in
//                notificationFeedbackGenerator.prepare()
//                switch completion {
//                case .failure(let error):
//                    os_log("%{public}s[%{public}ld], %{public}s: delete tweet fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
////                    var config = SwiftMessages.defaultConfig
////                    config.duration = .seconds(seconds: 3)
////                    config.interactiveHide = true
////                    let bannerView = NotifyBannerView()
////                    bannerView.configure(for: .error)
////                    bannerView.titleLabel.text = L10n.Common.Alerts.FailedToDeleteTweet.title
////                    bannerView.messageLabel.text = L10n.Common.Alerts.FailedToDeleteTweet.message
////                    DispatchQueue.main.async {
////                        SwiftMessages.show(config: config, view: bannerView)
////                        notificationFeedbackGenerator.notificationOccurred(.error)
////                    }
//                case .finished:
//                    notificationFeedbackGenerator.notificationOccurred(.success)
//                }
//            })
//            .eraseToAnyPublisher()
    }
    
}
