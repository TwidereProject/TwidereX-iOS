//
//  APIService+List+Member.swift
//  
//
//  Created by MainasuK on 2022-3-23.
//

import Foundation
import TwitterSDK
import MastodonSDK
import CoreDataStack

extension APIService {
    
    public enum AddListMemberResponse {
        case twitter(response: Twitter.Response.Content<Twitter.API.V2.List.Member.AddMemberContent>)
        case mastodon(response: Mastodon.Response.Content<Void>)
    }
    
    public func addListMember(
        list: ListRecord,
        user: UserRecord,
        authenticationContext: AuthenticationContext
    ) async throws -> AddListMemberResponse {
        let managedObjectContext = backgroundManagedObjectContext

        switch (list, user, authenticationContext) {
        case (.twitter(let list), .twitter(let user), .twitter(let authenticationContext)):
            let query: Twitter.API.V2.List.Member.AddMemberQuery = try await managedObjectContext.perform {
                guard let user = user.object(in: managedObjectContext) else {
                    throw AppError.explicit(.badRequest)
                }
                return .init(userID: user.id)
            }
            let response = try await addListMember(
                list: list,
                query: query,
                authenticationContext: authenticationContext
            )
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): add Twitter members: \(query.userID)")
            return .twitter(response: response)
        case (.mastodon(let list), .mastodon(let user), .mastodon(let authenticationContext)):
            let query: Mastodon.API.List.AddAccountsQuery = try await managedObjectContext.perform {
                guard let user = user.object(in: managedObjectContext) else {
                    throw AppError.explicit(.badRequest)
                }
                return .init(accountIDs: [user.id])
            }
            let response = try await addListMember(
                list: list,
                query: query,
                authenticationContext: authenticationContext
            )
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): add Mastodon members: \(query.accountIDs)")
            return .mastodon(response: response)
        default:
            throw AppError.implicit(.badRequest)
        }
    }
    
    public func addListMember(
        list: ManagedObjectRecord<TwitterList>,
        query: Twitter.API.V2.List.Member.AddMemberQuery,
        authenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<Twitter.API.V2.List.Member.AddMemberContent> {
        let managedObjectContext = backgroundManagedObjectContext
        
        let _listID: TwitterList.ID? = await managedObjectContext.perform {
            guard let object = list.object(in: managedObjectContext) else { return nil }
            return object.id
        }
        guard let listID = _listID else {
            throw AppError.implicit(.badRequest)
        }

        let response = try await Twitter.API.V2.List.Member.add(
            session: session,
            listID: listID,
            query: query,
            authorization: authenticationContext.authorization
        )
        
        return response
    }

    public func addListMember(
        list: ManagedObjectRecord<MastodonList>,
        query: Mastodon.API.List.AddAccountsQuery,
        authenticationContext: MastodonAuthenticationContext
    ) async throws -> Mastodon.Response.Content<Void> {
        let managedObjectContext = backgroundManagedObjectContext
        
        let _listID: MastodonList.ID? = await managedObjectContext.perform {
            guard let object = list.object(in: managedObjectContext) else { return nil }
            return object.id
        }
        guard let listID = _listID else {
            throw AppError.implicit(.badRequest)
        }

        let response = try await Mastodon.API.List.addAccounts(
            session: session,
            domain: authenticationContext.domain,
            listID: listID,
            query: query,
            authorization: authenticationContext.authorization
        )
        
        return response
    }
    
}

extension APIService {
    
    public enum RemoveListMemberResponse {
        case twitter(response: Twitter.Response.Content<Twitter.API.V2.List.Member.RemoveMemberContent>)
        case mastodon(response: Mastodon.Response.Content<Void>)
    }
    
    public func removeListMember(
        list: ListRecord,
        user: UserRecord,
        authenticationContext: AuthenticationContext
    ) async throws -> AddListMemberResponse {
        let managedObjectContext = backgroundManagedObjectContext

        switch (list, user, authenticationContext) {
        case (.twitter(let list), .twitter(let user), .twitter(let authenticationContext)):
            let response = try await removeListMember(
                list: list,
                user: user,
                authenticationContext: authenticationContext
            )
            return .twitter(response: response)
        case (.mastodon(let list), .mastodon(let user), .mastodon(let authenticationContext)):
            let query: Mastodon.API.List.DeleteAccountsQuery = try await managedObjectContext.perform {
                guard let user = user.object(in: managedObjectContext) else {
                    throw AppError.explicit(.badRequest)
                }
                return .init(accountIDs: [user.id])
            }
            let response = try await removeListMember(
                list: list,
                query: query,
                authenticationContext: authenticationContext
            )
            return .mastodon(response: response)
        default:
            throw AppError.implicit(.badRequest)
        }
    }
    
    public func removeListMember(
        list: ManagedObjectRecord<TwitterList>,
        user: ManagedObjectRecord<TwitterUser>,
        authenticationContext: TwitterAuthenticationContext
    ) async throws -> Twitter.Response.Content<Twitter.API.V2.List.Member.RemoveMemberContent> {
        let managedObjectContext = backgroundManagedObjectContext
        
        let _listID: TwitterList.ID? = await managedObjectContext.perform {
            guard let object = list.object(in: managedObjectContext) else { return nil }
            return object.id
        }
        guard let listID = _listID else {
            throw AppError.implicit(.badRequest)
        }
        
        let _userID: TwitterUser.ID? = await managedObjectContext.perform {
            guard let object = user.object(in: managedObjectContext) else { return nil }
            return object.id
        }
        guard let userID = _userID else {
            throw AppError.implicit(.badRequest)
        }

        let response = try await Twitter.API.V2.List.Member.remove(
            session: session,
            listID: listID,
            userID: userID,
            authorization: authenticationContext.authorization
        )
        
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): remove Twitter members: \(userID)")
        return response
    }

    public func removeListMember(
        list: ManagedObjectRecord<MastodonList>,
        query: Mastodon.API.List.DeleteAccountsQuery,
        authenticationContext: MastodonAuthenticationContext
    ) async throws -> Mastodon.Response.Content<Void> {
        let managedObjectContext = backgroundManagedObjectContext
        
        let _listID: MastodonList.ID? = await managedObjectContext.perform {
            guard let object = list.object(in: managedObjectContext) else { return nil }
            return object.id
        }
        guard let listID = _listID else {
            throw AppError.implicit(.badRequest)
        }

        let response = try await Mastodon.API.List.deleteAccounts(
            session: session,
            domain: authenticationContext.domain,
            listID: listID,
            query: query,
            authorization: authenticationContext.authorization
        )
        
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): remove Mastodon members: \(query.accountIDs)")
        return response
    }
    
}
