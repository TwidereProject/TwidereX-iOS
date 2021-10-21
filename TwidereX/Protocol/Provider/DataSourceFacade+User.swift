//
//  DataSourceProvider+User.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-21.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import CoreDataStack

extension DataSourceFacade {
    static func createMenuForUser(
        provider: DataSourceProvider,
        user: UserRecord,
        authenticationContext: AuthenticationContext
    ) async throws -> UIMenu {
        var children: [UIMenuElement] = []
        
        let relationshipOptionSet = try await DataSourceFacade.relationshipOptionSet(
            provider: provider,
            record: user,
            authenticationContext: authenticationContext
        )
        
        let isMyself = relationshipOptionSet.contains(.isMyself)
        
        // block
        if isMyself {
            
        } else {
            let isBlocking = relationshipOptionSet.contains(.blocking)
            let blockAction = await createMenuBlockActionForUser(
                provider: provider,
                record: user,
                authenticationContext: authenticationContext,
                isBlocking: isBlocking
            )
            children.append(blockAction)
        }
        
        return await UIMenu(title: "", options: [], children: children)
    }
}
 
extension DataSourceFacade {
    static func relationshipOptionSet(
        provider: DataSourceProvider,
        record: UserRecord,
        authenticationContext: AuthenticationContext
    ) async throws -> RelationshipOptionSet {
        let managedObjectContext = provider.context.managedObjectContext
        let relationshipOptionSet: RelationshipOptionSet = try await managedObjectContext.perform {
            guard let user = record.user(in: managedObjectContext),
                  let me = authenticationContext.user(in: managedObjectContext)
            else { throw AppError.implicit(.badRequest) }
            return RelationshipViewModel.optionSet(user: user, me: me)
        }
        return relationshipOptionSet
    }
}

extension DataSourceFacade {
    
    // block / unblock
    private static func createMenuBlockActionForUser(
        provider: DataSourceProvider,
        record: UserRecord,
        authenticationContext: AuthenticationContext,
        isBlocking: Bool
    ) async -> UIAction {
        let title = isBlocking ? L10n.Common.Controls.Friendship.Actions.unblock : L10n.Common.Controls.Friendship.Actions.block
        let image = isBlocking ? UIImage(systemName: "circle") : UIImage(systemName: "nosign")
        let blockAction = await UIAction(title: title, image: image, attributes: [], state: .off) { [weak provider] _ in
            guard let provider = provider else { return }
            Task {
                await DataSourceFacade.presentUserBlockAlert(
                    provider: provider,
                    user: record,
                    authenticationContext: authenticationContext
                )
            }
        }
        return blockAction
    }

}
