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
