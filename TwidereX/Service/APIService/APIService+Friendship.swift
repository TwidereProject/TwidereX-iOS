//
//  APIService+Friendship.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-2.
//  Copyright © 2020 Twidere. All rights reserved.
//


import os.log
import Foundation
import Combine
import TwitterAPI
import CoreData
import CoreDataStack
import CommonOSLog

extension APIService {
    
    func friendship(
        twitterUserObjectID: NSManagedObjectID,
        twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox
    ) -> AnyPublisher<(Twitter.API.Friendships.QueryType, TwitterUser.ID), Error> {
        let requestTwitterUserID = twitterAuthenticationBox.twitterUserID
        
        var _targetTwitterUserID: TwitterUser.ID?
        var _queryType: Twitter.API.Friendships.QueryType?
        let managedObjectContext = backgroundManagedObjectContext
        
        return managedObjectContext.performChanges {
            let _requestTwitterUser: TwitterUser? = {
                let request = TwitterUser.sortedFetchRequest
                request.predicate = TwitterUser.predicate(idStr: requestTwitterUserID)
                request.fetchLimit = 1
                request.returnsObjectsAsFaults = false
                do {
                    return try managedObjectContext.fetch(request).first
                } catch {
                    assertionFailure(error.localizedDescription)
                    return nil
                }
            }()
            
            guard let requestTwitterUser = _requestTwitterUser else {
                assertionFailure()
                return
            }
            
            let twitterUser = managedObjectContext.object(with: twitterUserObjectID) as! TwitterUser
            _targetTwitterUserID = twitterUser.id
            
            let isPending = (twitterUser.followRequestSentFrom ?? Set()).contains(where: { $0.id == requestTwitterUserID })
            let isFollowing = (twitterUser.followingFrom ?? Set()).contains(where: { $0.id == requestTwitterUserID })
            
            if isFollowing || isPending {
                _queryType = .destroy
                twitterUser.update(following: false, twitterUser: requestTwitterUser)
                twitterUser.update(followRequestSent: false, twitterUser: requestTwitterUser)
            } else {
                _queryType = .create
                if twitterUser.protected {
                    twitterUser.update(following: false, twitterUser: requestTwitterUser)
                    twitterUser.update(followRequestSent: true, twitterUser: requestTwitterUser)
                } else {
                    twitterUser.update(following: true, twitterUser: requestTwitterUser)
                    twitterUser.update(followRequestSent: false, twitterUser: requestTwitterUser)
                }
            }
        }
        .tryMap { result in
            switch result {
            case .success:
                guard let targetTwitterUserID = _targetTwitterUserID,
                      let queryType = _queryType else {
                    throw APIError.implicit(.badRequest)
                }
                return (queryType, targetTwitterUserID)
                
            case .failure(let error):
                assertionFailure(error.localizedDescription)
                throw error
            }
        }
        .eraseToAnyPublisher()
    }
    
    func friendship(
        friendshipQueryType: Twitter.API.Friendships.QueryType,
        twitterUserID: TwitterUser.ID,
        twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox
    ) -> AnyPublisher<Twitter.Response.Content<Twitter.Entity.User>, Error> {
        let authorization = twitterAuthenticationBox.twitterAuthorization
        let query = Twitter.API.Friendships.Query(
            userID: twitterUserID
        )
        // API not return latest friendship status. not merge result
        return Twitter.API.Friendships.friendships(session: session, authorization: authorization, queryKind: friendshipQueryType, query: query)
            .eraseToAnyPublisher()
    }
    
}
