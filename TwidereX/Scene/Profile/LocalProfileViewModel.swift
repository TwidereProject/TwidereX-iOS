//
//  LocalProfileViewModel.swift
//  LocalProfileViewModel
//
//  Created by Cirno MainasuK on 2021-9-8.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation

final class LocalProfileViewModel: ProfileViewModel {
    
    convenience init(
        context: AppContext,
        authContext: AuthContext,
        userRecord: UserRecord
    ) {
        self.init(
            context: context,
            authContext: authContext,
            displayLikeTimeline: Self.displayLikeTimeline(
                context: context,
                authContext: authContext,
                userRecord: userRecord
            )
        )
        
        setup(user: userRecord)
    }
    
    // note:
    // use sync method to force data prepared before using
    // otherwise, the UI may delay update when profile display
    func setup(user record: UserRecord) {
        let managedObjectContext = context.managedObjectContext
        managedObjectContext.performAndWait {
            switch record {
            case .twitter(let record):
                guard let object = record.object(in: managedObjectContext) else { return }
                self.user = .twitter(object: object)
            case .mastodon(let record):
                guard let object = record.object(in: managedObjectContext) else { return }
                self.user = .mastodon(object: object)
            }
        }
    }   // end func setup(user:)
    
}

extension LocalProfileViewModel {
    static func displayLikeTimeline(
        context: AppContext,
        authContext: AuthContext,
        userRecord: UserRecord
    ) -> Bool {
        let managedObjectContext = context.managedObjectContext
        let result: Bool = managedObjectContext.performAndWait {
            guard let object = userRecord.object(in: managedObjectContext) else { return false }
            switch object {
            case .twitter:
                return true
            case .mastodon(let user):
                guard case let .mastodon(authenticationContext) = authContext.authenticationContext else { return false }
                return user.id == authenticationContext.userID
            }
        }
        return result
    }
}
