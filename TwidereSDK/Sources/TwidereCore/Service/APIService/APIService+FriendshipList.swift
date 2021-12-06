//
//  APIService+FriendshipList.swift
//  
//
//  Created by MainasuK on 2021-12-3.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack
import TwitterSDK
import MastodonSDK

extension APIService {
    
    public func twitterUserFollowingList(
        query: Twitter.API.V2.User.Follow.FriendshipListQuery,
        authenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<Twitter.API.V2.User.Follow.FriendshipListContent> {
        let authorization = authenticationContext.authorization
        
        let response = try await Twitter.API.V2.User.Follow.followingList(
            session: session,
            query: query,
            authorization: authorization
        )
        
        let managedObjectContext = backgroundManagedObjectContext
        try await managedObjectContext.performChanges {
            guard let authentication = authenticationContext.authenticationRecord.object(in: managedObjectContext) else { return }
            let me = authentication.user
            
            var users: [TwitterUser] = []
            
            for user in response.value.data ?? [] {
                let result = Persistence.TwitterUser.createOrMerge(
                    in: managedObjectContext,
                    context: Persistence.TwitterUser.PersistContextV2(
                        entity: user,
                        me: me,
                        cache: nil,
                        networkDate: response.networkDate
                    )
                )
                users.append(result.user)
            }   // end for … in …
            
            // update relationship if the list for myself
            if query.userID == authenticationContext.userID {
                for user in users {
                    user.update(isFollow: true, by: me)
                }
            }
        }   // end try await …
        
        return response
    } // end func
    
    public func twitterUserFollowerList(
        query: Twitter.API.V2.User.Follow.FriendshipListQuery,
        authenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<Twitter.API.V2.User.Follow.FriendshipListContent> {
        let authorization = authenticationContext.authorization
        
        let response = try await Twitter.API.V2.User.Follow.followers(
            session: session,
            query: query,
            authorization: authorization
        )
        
        let managedObjectContext = backgroundManagedObjectContext
        try await managedObjectContext.performChanges {
            guard let authentication = authenticationContext.authenticationRecord.object(in: managedObjectContext) else { return }
            let me = authentication.user
            
            var users: [TwitterUser] = []

            for user in response.value.data ?? [] {
                let result = Persistence.TwitterUser.createOrMerge(
                    in: managedObjectContext,
                    context: Persistence.TwitterUser.PersistContextV2(
                        entity: user,
                        me: me,
                        cache: nil,
                        networkDate: response.networkDate
                    )
                )
                users.append(result.user)
            }   // end for … in …
            
            // update relationship if the list for myself
            if query.userID == authenticationContext.userID {
                for user in users {
                    me.update(isFollow: true, by: user)
                }
            }
        }   // end try await …
        
        return response
    } // end func
    
}

extension APIService {

    public func mastodonUserFollowingList(
        userID: Mastodon.Entity.Account.ID,
        query: Mastodon.API.Account.FollowingQuery,
        authenticationContext: MastodonAuthenticationContext
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Account]> {
        let domain = authenticationContext.domain
        let authorization = authenticationContext.authorization
        
        let response = try await Mastodon.API.Account.following(
            session: session,
            domain: domain,
            userID: userID,
            query: query,
            authorization: authorization
        )
        
        let managedObjectContext = backgroundManagedObjectContext
        try await managedObjectContext.performChanges {
            guard let authentication = authenticationContext.authenticationRecord.object(in: managedObjectContext) else { return }
            let me = authentication.user
            
            var users: [MastodonUser] = []
            
            for user in response.value {
                let result = Persistence.MastodonUser.createOrMerge(
                    in: managedObjectContext,
                    context: Persistence.MastodonUser.PersistContext(
                        domain: domain,
                        entity: user,
                        cache: nil,
                        networkDate: response.networkDate
                    )
                )
                users.append(result.user)
            }   // end for … in …
            
            // update relationship if the list for myself
            if userID == authenticationContext.userID {
                for user in users {
                    user.update(isFollow: true, by: me)
                }
            }
        }   // end try await …
        
        return response
    } // end func
    
    public func mastodonUserFollowerList(
        userID: Mastodon.Entity.Account.ID,
        query: Mastodon.API.Account.FollowerQuery,
        authenticationContext: MastodonAuthenticationContext
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Account]> {
        let domain = authenticationContext.domain
        let authorization = authenticationContext.authorization
        
        let response = try await Mastodon.API.Account.followers(
            session: session,
            domain: domain,
            userID: userID,
            query: query,
            authorization: authorization
        )
        
        let managedObjectContext = backgroundManagedObjectContext
        try await managedObjectContext.performChanges {
            guard let authentication = authenticationContext.authenticationRecord.object(in: managedObjectContext) else { return }
            let me = authentication.user
            
            var users: [MastodonUser] = []
            
            for user in response.value {
                let result = Persistence.MastodonUser.createOrMerge(
                    in: managedObjectContext,
                    context: Persistence.MastodonUser.PersistContext(
                        domain: domain,
                        entity: user,
                        cache: nil,
                        networkDate: response.networkDate
                    )
                )
                users.append(result.user)
            }   // end for … in …
            
            // update relationship if the list for myself
            if userID == authenticationContext.userID {
                for user in users {
                    me.update(isFollow: true, by: user)
                }
            }
        }   // end try await …
        
        return response
    } // end func
    
}
