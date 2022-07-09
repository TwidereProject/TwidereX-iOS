//
//  APIService+User+FollowRequest.swift
//  
//
//  Created by MainasuK on 2022-7-1.
//

import Foundation
import CoreData
import CoreDataStack
import MastodonSDK

extension APIService {
    
    public func followRequest(
        user: ManagedObjectRecord<MastodonUser>,
        query: Mastodon.API.Account.FollowReqeustQuery,
        authenticationContext: MastodonAuthenticationContext
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Relationship> {
        let managedObjectContext = backgroundManagedObjectContext
        
        let _userID: MastodonUser.ID? = await managedObjectContext.perform {
            guard let user = user.object(in: managedObjectContext) else { return nil }
            return user.id
        }
        guard let userID = _userID else {
            throw AppError.implicit(.badRequest)
        }
        
        let response = try await Mastodon.API.Account.followRequest(
            session: session,
            domain: authenticationContext.domain,
            userID: userID,
            query: query,
            authorization: authenticationContext.authorization
        )
        
        try await managedObjectContext.performChanges {
            guard let user = user.object(in: managedObjectContext) else { return }
            guard let me = authenticationContext.authenticationRecord.object(in: managedObjectContext)?.user else { return }
            
            Persistence.MastodonUser.update(
                mastodonUser: user,
                context: Persistence.MastodonUser.RelationshipContext(
                    entity: response.value,
                    me: me,
                    networkDate: response.networkDate
                )
            )
        }
        
        return response
    }

}
