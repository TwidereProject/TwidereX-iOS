//
//  APIService+List.swift
//  
//
//  Created by MainasuK on 2022-3-10.
//

import Foundation
import TwitterSDK
import MastodonSDK
import CoreDataStack

extension APIService {
    public func twitterListShow(
        query: Twitter.API.List.ShowQuery,
        authenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<Twitter.Entity.List> {
        let response = try await Twitter.API.List.show(
            session: session,
            query: query,
            authorization: authenticationContext.authorization
        )
        
        return response
    }
}

extension APIService {
    
    public struct ListRelationship {
        public let isFollowing: Bool
    }
    
    public func followRelationship(
        list: ListRecord,
        authenticationContext: AuthenticationContext
    ) async throws -> ListRelationship {
        let managedObjectContext = backgroundManagedObjectContext
        
        switch (list, authenticationContext) {
        case (.twitter(let record), .twitter(let authenticationContext)):
            let _id: Twitter.Entity.List.ID? = await managedObjectContext.perform {
                let list = record.object(in: managedObjectContext)
                return list?.id
            }
            guard let id = _id else {
                throw AppError.implicit(.badRequest)
            }
            let response = try await twitterListShow(
                query: Twitter.API.List.ShowQuery(id: id),
                authenticationContext: authenticationContext
            )
            return ListRelationship(
                isFollowing: response.value.following
            )
            
        case (.mastodon(let record), .mastodon(let authenticationContext)):
            assertionFailure("TODO")
            throw AppError.implicit(.badRequest)
        default:
            throw AppError.implicit(.badRequest)
        }
    }
    
}

extension APIService {
    
    public func follow(
        list: ListRecord,
        relationship: ListRelationship,
        authenticationContext: AuthenticationContext
    ) async throws {
        switch (list, authenticationContext) {
        case (.twitter(let record), .twitter(let authenticationContext)):
            _ = try await follow(list: record, relationship: relationship, authenticationContext: authenticationContext)
        case (.mastodon(let record), .mastodon(let authenticationContext)):
            _ = try await follow(list: record, relationship: relationship, authenticationContext: authenticationContext)
        default:
            throw AppError.implicit(.badRequest)
        }
    }
    
    public func follow(
        list: ManagedObjectRecord<TwitterList>,
        relationship: ListRelationship,
        authenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<Twitter.API.V2.User.List.FollowContent> {
        let managedObjectContext = backgroundManagedObjectContext
        let _id: Twitter.Entity.V2.List.ID? = await managedObjectContext.perform {
            let list = list.object(in: managedObjectContext)
            return list?.id
        }
        guard let id = _id else {
            throw AppError.implicit(.badRequest)
        }

        let response: Twitter.Response.Content<Twitter.API.V2.User.List.FollowContent> = try await {
            if relationship.isFollowing {
                return try await Twitter.API.V2.User.List.unfollow(
                    session: session,
                    userID: authenticationContext.userID,
                    listID: id,
                    authorization: authenticationContext.authorization
                )
            } else {
                return try await Twitter.API.V2.User.List.follow(
                    session: session,
                    userID: authenticationContext.userID,
                    query: Twitter.API.V2.User.List.FollowQuery(id: id),
                    authorization: authenticationContext.authorization
                )
            }
        }()
        
        return response
    }
    
    public func follow(
        list: ManagedObjectRecord<MastodonList>,
        relationship: ListRelationship,
        authenticationContext: MastodonAuthenticationContext
    ) async throws -> Twitter.API.V2.User.List.FollowContent {
        throw AppError.implicit(.badRequest)
    }
    
}
