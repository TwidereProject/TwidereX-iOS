//
//  LocalProfileViewModel.swift
//  LocalProfileViewModel
//
//  Created by Cirno MainasuK on 2021-9-8.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation

final class LocalProfileViewModel: ProfileViewModel {
    
    init(context: AppContext, userRecord: UserRecord) {
        super.init(context: context)
        
        Task {
            await setup(user: userRecord)
        }
    }
    
    @MainActor
    func setup(user record: UserRecord) async {
        let managedObjectContext = context.managedObjectContext
        self.user = await managedObjectContext.perform {
            switch record {
            case .twitter(let record):
                return record.object(in: managedObjectContext)
                    .flatMap { UserObject.twitter(object: $0) }
            case .mastodon(let record):
                return record.object(in: managedObjectContext)
                    .flatMap { UserObject.mastodon(object: $0) }
            }
        }
    }
}
