//
//  APIService+Tweet.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-23.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import TwitterSDK
import CoreData
import CoreDataStack
//import SwiftMessages

extension APIService {
    
    func tweet(
        content: String,
        mediaIDs: [String]?,
        placeID: String?,
        replyToTweetObjectID: NSManagedObjectID?,
        excludeReplyUserIDs: [TwitterUser.ID]?,
        twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox
    ) -> AnyPublisher<Twitter.Response.Content<Twitter.Entity.Tweet>, Error> {
        let authorization = twitterAuthenticationBox.twitterAuthorization
        let managedObjectContext = backgroundManagedObjectContext
        
        let mediaIDs: String? = mediaIDs?.joined(separator: ",")
        let excludeReplyUserIDs: String? = excludeReplyUserIDs?.joined(separator: ",")
        let query = Future<Twitter.API.Statuses.UpdateQuery, Never> { promise in
            if let replyToTweetObjectID = replyToTweetObjectID {
                managedObjectContext.perform {
                    let replyTo = managedObjectContext.object(with: replyToTweetObjectID) as! Tweet
                    let query = Twitter.API.Statuses.UpdateQuery(
                        status: content,
                        inReplyToStatusID: replyTo.id,
                        autoPopulateReplyMetadata: true,
                        excludeReplyUserIDs: excludeReplyUserIDs,
                        mediaIDs: mediaIDs,
                        latitude: nil,
                        longitude: nil,
                        placeID: placeID
                    )
                    DispatchQueue.main.async {
                        promise(.success(query))
                    }
                }
            } else {
                let query = Twitter.API.Statuses.UpdateQuery(
                    status: content,
                    inReplyToStatusID: nil,
                    autoPopulateReplyMetadata: false,
                    excludeReplyUserIDs: excludeReplyUserIDs,
                    mediaIDs: mediaIDs,
                    latitude: nil,
                    longitude: nil,
                    placeID: placeID
                )
                promise(.success(query))
            }
        }

        return query
            .setFailureType(to: Error.self)
            .map { query in return Twitter.API.Statuses.update(session: self.session, authorization: authorization, query: query) }
            .switchToLatest()
            .eraseToAnyPublisher()
    }
    
    func delete(
        tweetObjectID: NSManagedObjectID,
        twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox
    ) -> AnyPublisher<Twitter.Response.Content<Twitter.Entity.Tweet>, Error> {
        let authorization = twitterAuthenticationBox.twitterAuthorization
        let managedObjectContext = backgroundManagedObjectContext
        
        let query = Future<Twitter.API.Statuses.DestroyQuery, Never> { promise in
            let tweet = managedObjectContext.object(with: tweetObjectID) as! Tweet
            let query = Twitter.API.Statuses.DestroyQuery(id: tweet.id)
            promise(.success(query))
        }
        
        let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
        
        return query
            .setFailureType(to: Error.self)
            .flatMap { query -> AnyPublisher<Twitter.Response.Content<Twitter.Entity.Tweet>, Error> in
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: delete tweet %s …", ((#file as NSString).lastPathComponent), #line, #function, query.id)
                impactFeedbackGenerator.prepare()
                impactFeedbackGenerator.impactOccurred()
                return Twitter.API.Statuses.destroy(session: self.session, authorization: authorization, query: query)
            }
            .map { response -> AnyPublisher<Twitter.Response.Content<Twitter.Entity.Tweet>, Error> in
                let tweet = response.value
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: delete tweet %s success", ((#file as NSString).lastPathComponent), #line, #function, tweet.idStr)
                return managedObjectContext.performChanges {
                    let tweet = managedObjectContext.object(with: tweetObjectID) as! Tweet
                    tweet.softDelete()
                }
                .setFailureType(to: Error.self)
                .tryMap { result -> Twitter.Response.Content<Twitter.Entity.Tweet> in
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
            .handleEvents(receiveCompletion: { completion in
                notificationFeedbackGenerator.prepare()
                switch completion {
                case .failure(let error):
                    os_log("%{public}s[%{public}ld], %{public}s: delete tweet fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
//                    var config = SwiftMessages.defaultConfig
//                    config.duration = .seconds(seconds: 3)
//                    config.interactiveHide = true
//                    let bannerView = NotifyBannerView()
//                    bannerView.configure(for: .error)
//                    bannerView.titleLabel.text = L10n.Common.Alerts.FailedToDeleteTweet.title
//                    bannerView.messageLabel.text = L10n.Common.Alerts.FailedToDeleteTweet.message
//                    DispatchQueue.main.async {
//                        SwiftMessages.show(config: config, view: bannerView)
//                        notificationFeedbackGenerator.notificationOccurred(.error)
//                    }
                case .finished:
                    notificationFeedbackGenerator.notificationOccurred(.success)
                }
            })
            .eraseToAnyPublisher()
    }
    
}
