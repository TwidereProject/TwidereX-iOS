//
//  APIService+Status+Thread.swift
//  APIService+Status+Thread
//
//  Created by Cirno MainasuK on 2021-9-6.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import Foundation
import Combine
import CoreData
import CoreDataStack
import MastodonSDK

extension APIService {
    
    public func mastodonStatusContext(
        statusID: Mastodon.Entity.Status.ID,
        authenticationContext: MastodonAuthenticationContext
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Context> {
        let response = try await Mastodon.API.Status.context(
            session: session,
            domain: authenticationContext.domain,
            statusID: statusID,
            authorization: authenticationContext.authorization
        )
        
        let managedObjectContext = backgroundManagedObjectContext
        try await managedObjectContext.performChanges {
            let user = authenticationContext.authenticationRecord.object(in: managedObjectContext)?.user
            let statuses = response.value.ancestors + response.value.descendants
            for entity in statuses {
                let persistContext = Persistence.MastodonStatus.PersistContext(
                    domain: authenticationContext.domain,
                    entity: entity,
                    me: user,
                    statusCache: nil,   // TODO:
                    userCache: nil,
                    networkDate: response.networkDate
                )
                
                let _ = Persistence.MastodonStatus.createOrMerge(
                    in: managedObjectContext,
                    context: persistContext
                )
            }
        }
        
        return response
    }
    
}
