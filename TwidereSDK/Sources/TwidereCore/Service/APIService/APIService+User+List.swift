//
//  APIService+User+List.swift
//  
//
//  Created by MainasuK on 2022-3-1.
//

import Foundation
import CoreDataStack
import TwitterSDK
import MastodonSDK

extension APIService {
    
    public func twitterUserOwnedLists(
        user: ManagedObjectRecord<TwitterUser>,
        query: Twitter.API.V2.User.List.OwnedListsQuery,
        authenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<Twitter.API.V2.User.List.OwnedListsContent> {
        let managedObjectContext = backgroundManagedObjectContext
        
        let _userID: TwitterUser.ID? = await managedObjectContext.perform {
            guard let user = user.object(in: managedObjectContext) else { return nil }
            return user.id
        }
        guard let userID = _userID else {
            throw AppError.implicit(.badRequest)
        }
        
        let response = try await Twitter.API.V2.User.List.onwedLists(
            session: session,
            userID: userID,
            query: query,
            authorization: authenticationContext.authorization
        )
        
        try await managedObjectContext.performChanges {
            for list in response.value.data ?? [] {
                guard let owner = response.value.includes?.users.first(where: { $0.id == list.ownerID }) else {
                    continue
                }
                
                _ = Persistence.TwitterList.createOrMerge(
                    in: managedObjectContext,
                    context: Persistence.TwitterList.PersistContext(
                        entity: Persistence.TwitterList.PersistContext.Entity(
                            list: list,
                            owner: owner
                        ),
                        networkDate: response.networkDate
                    )
                )
            }   // for … in …
        }   // end managedObjectContext.performChanges
        
        return response
    }

    public func twitterUserFollowedLists(
        user: ManagedObjectRecord<TwitterUser>,
        query: Twitter.API.V2.User.List.FollowedListsQuery,
        authenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<Twitter.API.V2.User.List.FollowedListsContent> {
        let managedObjectContext = backgroundManagedObjectContext
        
        let _userID: TwitterUser.ID? = await managedObjectContext.perform {
            guard let user = user.object(in: managedObjectContext) else { return nil }
            return user.id
        }
        guard let userID = _userID else {
            throw AppError.implicit(.badRequest)
        }
        
        let response = try await Twitter.API.V2.User.List.followedLists(
            session: session,
            userID: userID,
            query: query,
            authorization: authenticationContext.authorization
        )
        
        try await managedObjectContext.performChanges {
            for list in response.value.data ?? [] {
                guard let owner = response.value.includes?.users.first(where: { $0.id == list.ownerID }) else {
                    continue
                }
                
                _ = Persistence.TwitterList.createOrMerge(
                    in: managedObjectContext,
                    context: Persistence.TwitterList.PersistContext(
                        entity: Persistence.TwitterList.PersistContext.Entity(
                            list: list,
                            owner: owner
                        ),
                        networkDate: response.networkDate
                    )
                )
            }   // for … in …
        }   // end managedObjectContext.performChanges
        
        return response
    }
    
    public func twitterUserListMemberships(
        user: ManagedObjectRecord<TwitterUser>,
        query: Twitter.API.V2.User.List.ListMembershipsQuery,
        authenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<Twitter.API.V2.User.List.ListMembershipsContent> {
        let managedObjectContext = backgroundManagedObjectContext
        
        let _userID: TwitterUser.ID? = await managedObjectContext.perform {
            guard let user = user.object(in: managedObjectContext) else { return nil }
            return user.id
        }
        guard let userID = _userID else {
            throw AppError.implicit(.badRequest)
        }
        
        let response = try await Twitter.API.V2.User.List.listMemberships(
            session: session,
            userID: userID,
            query: query,
            authorization: authenticationContext.authorization
        )
        
        try await managedObjectContext.performChanges {
            for list in response.value.data ?? [] {
                guard let owner = response.value.includes?.users.first(where: { $0.id == list.ownerID }) else {
                    continue
                }
                
                _ = Persistence.TwitterList.createOrMerge(
                    in: managedObjectContext,
                    context: Persistence.TwitterList.PersistContext(
                        entity: Persistence.TwitterList.PersistContext.Entity(
                            list: list,
                            owner: owner
                        ),
                        networkDate: response.networkDate
                    )
                )
            }   // for … in …
        }   // end managedObjectContext.performChanges
        
        return response
    }
    
}

extension APIService {
    
    public func mastodonUserOwnedLists(
        authenticationContext: MastodonAuthenticationContext
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.List]> {
        let managedObjectContext = backgroundManagedObjectContext
        
        let response = try await Mastodon.API.List.ownedLists(
            session: session,
            domain: authenticationContext.domain,
            authorization: authenticationContext.authorization
        )
        
        try await managedObjectContext.performChanges {
            guard let me = authenticationContext.authenticationRecord.object(in: managedObjectContext)?.user else {
                assertionFailure()
                return
            }
            
            for list in response.value {
                _ = Persistence.MastodonList.createOrMerge(
                    in: managedObjectContext,
                    context: Persistence.MastodonList.PersistContext(
                        domain: authenticationContext.domain,
                        entity: Persistence.MastodonList.PersistContext.Entity(
                            list: list,
                            owner: me
                        ),
                        networkDate: response.networkDate
                    )
                )
            }   // for … in …
        }   // end managedObjectContext.performChanges
        
        return response
    }
    
}
