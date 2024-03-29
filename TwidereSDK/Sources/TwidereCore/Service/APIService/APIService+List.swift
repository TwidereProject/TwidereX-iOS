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
    
    // Twitter V1 API to fetch relationship
    public func show(
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
    
    // Twitter V2 API to fetch list model
    public func lookup(
        listID: Twitter.Entity.V2.List.ID,
        authenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<Twitter.API.V2.List.LookupContent> {
        let response = try await Twitter.API.V2.List.lookup(
            session: session,
            listID: listID,
            authorization: authenticationContext.authorization
        )
        
        let managedObjectContext = backgroundManagedObjectContext
        try await managedObjectContext.performChanges {
            let list = response.value.data
            guard let owner = response.value.includes?.users.first(where: { $0.id == list.ownerID }) else {
                return
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
        }
        
        return response
    }

}

extension APIService {
    
    public func twitterListFollower(
        list: ManagedObjectRecord<TwitterList>,
        query: Twitter.API.V2.List.FollowerQuery,
        authenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<Twitter.API.V2.List.FollowerContent> {
        let managedObjectContext = backgroundManagedObjectContext
        let _listID: TwitterList.ID? = await managedObjectContext.perform {
            let list = list.object(in: managedObjectContext)
            return list?.id
        }
        guard let listID = _listID else {
            throw AppError.implicit(.badRequest)
        }

        let response = try await Twitter.API.V2.List.follower(
            session: session,
            listID: listID,
            query: query,
            authorization: authenticationContext.authorization
        )
        
        try await managedObjectContext.performChanges {
            let me = authenticationContext.authenticationRecord.object(in: managedObjectContext)?.user
            for entity in response.value.data ?? [] {
                _ = Persistence.TwitterUser.createOrMerge(
                    in: managedObjectContext,
                    context: Persistence.TwitterUser.PersistContextV2(
                        entity: entity,
                        me: me,
                        cache: nil,
                        networkDate: response.networkDate
                    )
                )
            }   // end for … in …
        }
        
        return response
    }
    
}

extension APIService {
    
    public func twitterListMember(
        list: ManagedObjectRecord<TwitterList>,
        query: Twitter.API.V2.List.MemberQuery,
        authenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<Twitter.API.V2.List.MemberContent> {
        let managedObjectContext = backgroundManagedObjectContext
        let _listID: TwitterList.ID? = await managedObjectContext.perform {
            let list = list.object(in: managedObjectContext)
            return list?.id
        }
        guard let listID = _listID else {
            throw AppError.implicit(.badRequest)
        }

        let response = try await Twitter.API.V2.List.member(
            session: session,
            listID: listID,
            query: query,
            authorization: authenticationContext.authorization
        )
        
        try await managedObjectContext.performChanges {
            let me = authenticationContext.authenticationRecord.object(in: managedObjectContext)?.user
            for entity in response.value.data ?? [] {
                _ = Persistence.TwitterUser.createOrMerge(
                    in: managedObjectContext,
                    context: Persistence.TwitterUser.PersistContextV2(
                        entity: entity,
                        me: me,
                        cache: nil,
                        networkDate: response.networkDate
                    )
                )
            }   // end for … in …
        }
        
        return response
    }
    
    public func mastodonListMember(
        list: ManagedObjectRecord<MastodonList>,
        query: Mastodon.API.List.AccountsQuery,
        authenticationContext: MastodonAuthenticationContext
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Account]> {
        let managedObjectContext = backgroundManagedObjectContext
        let _listID: MastodonList.ID? = await managedObjectContext.perform {
            let list = list.object(in: managedObjectContext)
            return list?.id
        }
        guard let listID = _listID else {
            throw AppError.implicit(.badRequest)
        }

        let response = try await Mastodon.API.List.accounts(
            session: session,
            domain: authenticationContext.domain,
            listID: listID,
            query: query,
            authorization: authenticationContext.authorization
        )
        
        try await managedObjectContext.performChanges {
            for entity in response.value {
                _ = Persistence.MastodonUser.createOrMerge(
                    in: managedObjectContext,
                    context: Persistence.MastodonUser.PersistContext(
                        domain: authenticationContext.domain,
                        entity: entity,
                        cache: nil,
                        networkDate: response.networkDate
                    )
                )
            }   // end for … in …
        }
        
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
            let response = try await show(
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

extension APIService {
    
    public enum CreateListQuery {
        case twitter(query: Twitter.API.V2.List.CreateQuery)
        case mastodon(query: Mastodon.API.List.CreateQuery)
    }
    
    public enum CreateListResponse {
        case twitter(response: Twitter.Response.Content<Twitter.API.V2.List.CreateContent>)
        case mastodon(response: Mastodon.Response.Content<Mastodon.Entity.List>)
    }
    
    public func create(
        query: CreateListQuery,
        authenticationContext: AuthenticationContext
    ) async throws -> CreateListResponse {
        switch (query, authenticationContext) {
        case (.twitter(let query), .twitter(let authenticationContext)):
            let response = try await create(
                query: query,
                authenticationContext: authenticationContext
            )
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): create Twitter list: \(response.value.data.id)")
            return .twitter(response: response)
        case (.mastodon(let query), .mastodon(let authenticationContext)):
            let response = try await create(
                query: query,
                authenticationContext: authenticationContext
            )
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): create Mastodon list: \(response.value.id)")
            return .mastodon(response: response)
        default:
            throw AppError.implicit(.badRequest)
        }
    }
    
    public func create(
        query: Twitter.API.V2.List.CreateQuery,
        authenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<Twitter.API.V2.List.CreateContent> {
        let response = try await Twitter.API.V2.List.create(
            session: session,
            query: query,
            authorization: authenticationContext.authorization
        )
        
        // persist created list into database
        _ = try await lookup(
            listID: response.value.data.id,
            authenticationContext: authenticationContext
        )
        
        return response
    }
    
    public func create(
        query: Mastodon.API.List.CreateQuery,
        authenticationContext: MastodonAuthenticationContext
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.List> {
        let response = try await Mastodon.API.List.create(
            session: session,
            domain: authenticationContext.domain,
            query: query,
            authorization: authenticationContext.authorization
        )
        
        // persist created list into database
        
        let managedObjectContext = backgroundManagedObjectContext
        try await managedObjectContext.performChanges {
            let list = response.value
            guard let me = authenticationContext.authenticationRecord.object(in: managedObjectContext)?.user else {
                return
            }
            
            _ = Persistence.MastodonList.createOrMerge(
                in: managedObjectContext,
                context: Persistence.MastodonList.PersistContext(
                    domain: authenticationContext.domain,
                    entity: .init(
                        list: list,
                        owner: me
                    ),
                    networkDate: response.networkDate
                )
            )
        }
        
        return response
    }
    
}

extension APIService {
    
    public enum UpdateListQuery {
        case twitter(query: Twitter.API.V2.List.UpdateQuery)
        case mastodon(query: Mastodon.API.List.UpdateQuery)
    }
    
    public enum UpdateListResponse {
        case twitter(response: Twitter.Response.Content<Twitter.API.V2.List.UpdateContent>)
        case mastodon(response: Mastodon.Response.Content<Mastodon.Entity.List>)
    }
    
    public func update(
        list: ListRecord,
        query: UpdateListQuery,
        authenticationContext: AuthenticationContext
    ) async throws -> UpdateListResponse {
        switch (list, query, authenticationContext) {
        case (.twitter(let list), .twitter(let query), .twitter(let authenticationContext)):
            let response = try await update(
                list: list,
                query: query,
                authenticationContext: authenticationContext
            )
            return .twitter(response: response)
        case (.mastodon(let list), .mastodon(let query), .mastodon(let authenticationContext)):
            let response = try await update(
                list: list,
                query: query,
                authenticationContext: authenticationContext
            )
            return .mastodon(response: response)
        default:
            throw AppError.implicit(.badRequest)
        }
    }
    
    public func update(
        list: ManagedObjectRecord<TwitterList>,
        query: Twitter.API.V2.List.UpdateQuery,
        authenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<Twitter.API.V2.List.UpdateContent> {
        let managedObjectContext = backgroundManagedObjectContext
        
        let _listID: TwitterList.ID? = await managedObjectContext.perform {
            guard let object = list.object(in: managedObjectContext) else { return nil }
            return object.id
        }
        guard let listID = _listID else {
            throw AppError.implicit(.badRequest)
        }
        
        let response = try await Twitter.API.V2.List.update(
            session: session,
            listID: listID,
            query: query,
            authorization: authenticationContext.authorization
        )

        // persist update list into database
        _ = try await lookup(
            listID: listID,
            authenticationContext: authenticationContext
        )

        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): update Twitter list: \(listID)")
        return response
    }
    
    public func update(
        list: ManagedObjectRecord<MastodonList>,
        query: Mastodon.API.List.UpdateQuery,
        authenticationContext: MastodonAuthenticationContext
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.List> {
        let managedObjectContext = backgroundManagedObjectContext
        
        let _listID: MastodonList.ID? = await managedObjectContext.perform {
            guard let object = list.object(in: managedObjectContext) else { return nil }
            return object.id
        }
        guard let listID = _listID else {
            throw AppError.implicit(.badRequest)
        }
        
        let response = try await Mastodon.API.List.update(
            session: session,
            domain: authenticationContext.domain,
            listID: listID,
            query: query,
            authorization: authenticationContext.authorization
        )
        
        // persist updated list into database
        try await managedObjectContext.performChanges {
            let list = response.value
            guard let me = authenticationContext.authenticationRecord.object(in: managedObjectContext)?.user else {
                return
            }
            
            _ = Persistence.MastodonList.createOrMerge(
                in: managedObjectContext,
                context: Persistence.MastodonList.PersistContext(
                    domain: authenticationContext.domain,
                    entity: .init(
                        list: list,
                        owner: me
                    ),
                    networkDate: response.networkDate
                )
            )
        }
        
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): update Mastodon list: \(listID)")
        return response
    }
    
}

extension APIService {
    
    public func deleteList(
        list: ListRecord,
        authenticationContext: AuthenticationContext
    ) async throws {
        let managedObjectContext = backgroundManagedObjectContext
        
        switch (list, authenticationContext) {
        case (.twitter(let list), .twitter(let authenticationContext)):
            let _listID: TwitterList.ID? = await managedObjectContext.perform {
                guard let object = list.object(in: managedObjectContext) else { return nil }
                return object.id
            }
            guard let listID = _listID else {
                throw AppError.implicit(.badRequest)
            }
            
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): delete Twitter list: \(listID)")
            do {
                _ = try await Twitter.API.V2.List.delete(
                    session: session,
                    listID: listID,
                    authorization: authenticationContext.authorization
                )
                try await managedObjectContext.performChanges {
                    guard let object = list.object(in: managedObjectContext) else { return }
                    managedObjectContext.delete(object)
                }
            } catch {
                throw error
            }
            // return .twitter(response: response)
        case (.mastodon(let list), .mastodon(let authenticationContext)):
            let _listID: MastodonList.ID? = await managedObjectContext.perform {
                guard let object = list.object(in: managedObjectContext) else { return nil }
                return object.id
            }
            guard let listID = _listID else {
                throw AppError.implicit(.badRequest)
            }

            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): delete Mastodon list: \(listID)")
            do {
                _ = try await Mastodon.API.List.delete(
                    session: session,
                    domain: authenticationContext.domain,
                    listID: listID,
                    authorization: authenticationContext.authorization
                )
                
                try await managedObjectContext.performChanges {
                    guard let object = list.object(in: managedObjectContext) else { return }
                    managedObjectContext.delete(object)
                }
            } catch let error as Mastodon.API.Error {
                throw AppError.implicit(.mastodonResponseError(error))
            } catch {
                throw error
            }
        default:
            throw AppError.implicit(.badRequest)
        }
    }
    
}
