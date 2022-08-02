//
//  DataSourceFacade+Profile.swift
//  DataSourceFacade+Profile
//
//  Created by Cirno MainasuK on 2021-9-8.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import TwidereCore
import CoreDataStack

extension DataSourceFacade {
    
    static func coordinateToProfileScene(
        provider: DataSourceProvider,
        target: StatusTarget,
        status: StatusRecord
    ) async {
        let _redirectRecord = await DataSourceFacade.author(
            managedObjectContext: provider.context.managedObjectContext,
            status: status,
            target: target
        )
        guard let redirectRecord = _redirectRecord else {
            assertionFailure()
            return
        }
        await coordinateToProfileScene(
            provider: provider,
            user: redirectRecord
        )
    }
    
    @MainActor
    static func coordinateToProfileScene(
        provider: DataSourceProvider,
        user: UserRecord
    ) async {
        let profileViewModel = LocalProfileViewModel(
            context: provider.context,
            userRecord: user
        )
        provider.coordinator.present(
            scene: .profile(viewModel: profileViewModel),
            from: provider,
            transition: .show
        )
        
        Task {
            await recordUserHistory(
                denpendency: provider,
                user: user
            )
        }   // end Task
    }
    
}


extension DataSourceFacade {
    
    static func coordinateToProfileScene(
        provider: DataSourceProvider,
        status: StatusRecord,
        mention: String,        // username,
        userInfo: [AnyHashable: Any]?
    ) async {
        let _profileContext: RemoteProfileViewModel.ProfileContext? = await provider.context.managedObjectContext.perform {
            guard let object = status.object(in: provider.context.managedObjectContext) else { return nil }
            switch object {
            case .twitter(let status):
                let status = status.repost ?? status
                let mentions = status.entities?.mentions ?? []
                let _userID: TwitterUser.ID? = mentions.first(where: { $0.username == mention })?.id

                if let userID = _userID {
                    let request = TwitterUser.sortedFetchRequest
                    request.predicate = TwitterUser.predicate(id: userID)
                    request.fetchLimit = 1
                    let _user = try? provider.context.managedObjectContext.fetch(request).first
                    
                    if let user = _user {
                        return .record(record: .twitter(record: .init(objectID: user.objectID)))
                    } else {
                        return .twitter(.userID(userID))
                    }
                } else {
                    return .twitter(.username(mention))
                }

            case .mastodon(let status):
                let status = status.repost ?? status
                guard let mention = status.mentions.first(where: { mention == $0.username }) else {
                    return nil
                }

                let userID = mention.id
                let request = MastodonUser.sortedFetchRequest
                request.predicate = MastodonUser.predicate(domain: status.domain, id: userID)
                let _user = try? provider.context.managedObjectContext.fetch(request).first
                
                if let user = _user {
                    return .record(record: .mastodon(record: .init(objectID: user.objectID)))
                } else {
                    return .mastodon(.userID(userID))
                }
            }   // end switch object
        }   // end let _profileContext: RemoteProfileViewModel = await provider.context.managedObjectContext.perform …
        
        guard let profileContext = _profileContext else {
            if case .mastodon = status {
                let href = userInfo?["href"] as? String
                guard let url = href.flatMap({ URL(string: $0) }) else { return }
                await provider.coordinator.present(
                    scene: .safari(url: url.absoluteString),
                    from: provider,
                    transition: .safariPresent(animated: true, completion: nil)
                )
            }
            return
        }

        await coordinateToProfileScene(
            provider: provider,
            profileContext: profileContext
        )
    }

    static func coordinateToProfileScene(
        provider: DataSourceProvider,
        user: UserRecord,
        mention: String,        // username,
        userInfo: [AnyHashable: Any]?
    ) async {
        let _profileContext: RemoteProfileViewModel.ProfileContext? = await provider.context.managedObjectContext.perform {
            guard let object = user.object(in: provider.context.managedObjectContext) else { return nil }
            switch object {
            case .twitter(let user):
                let mentions = user.bioEntities?.mentions ?? []
                let _userID = mentions.first(where: { $0.username == mention })?.id
        
                if let userID = _userID {
                    let request = TwitterUser.sortedFetchRequest
                    request.predicate = TwitterUser.predicate(id: userID)
                    request.fetchLimit = 1
                    let _user = try? provider.context.managedObjectContext.fetch(request).first

                    if let user = _user {
                        return .record(record: .twitter(record: .init(objectID: user.objectID)))
                    } else {
                        return .twitter(.userID(userID))
                    }
                } else {
                    return .twitter(.username(mention))
                }

            case .mastodon(let user):
                
                return nil
            }
        }
        
        guard let profileContext = _profileContext else { return }
        
        if case .mastodon = user {
            let href = userInfo?["href"] as? String
            guard let url = href.flatMap({ URL(string: $0) }) else { return }
            await provider.coordinator.present(scene: .safari(url: url.absoluteString), from: provider, transition: .safariPresent(animated: true, completion: nil))
            return
        }
    
        await coordinateToProfileScene(
            provider: provider,
            profileContext: profileContext
        )
    }
    
    @MainActor
    static func coordinateToProfileScene(
        provider: DataSourceProvider,
        profileContext: RemoteProfileViewModel.ProfileContext
    ) async {
        let profileViewModel = RemoteProfileViewModel(
            context: provider.context,
            profileContext: profileContext
        )
        provider.coordinator.present(
            scene: .profile(viewModel: profileViewModel),
            from: provider,
            transition: .show
        )
    }
    
}
