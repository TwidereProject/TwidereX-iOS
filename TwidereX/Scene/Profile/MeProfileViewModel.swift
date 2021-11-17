//
//  MeProfileViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-28.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack
import TwitterSDK

final class MeProfileViewModel: ProfileViewModel {
    
    override init(context: AppContext) {
        super.init(context: context)
        
        context.authenticationService.activeAuthenticationContext
            .sink { [weak self] authenticationContext in
                guard let self = self else { return }
                Task {
                    await self.setup(authenticationContext: authenticationContext)
                }
            }
            .store(in: &disposeBag)
    }
    
    @MainActor
    func setup(authenticationContext: AuthenticationContext?) async {
        let managedObjectContext = context.managedObjectContext
        self.user = await managedObjectContext.perform {
            switch authenticationContext {
            case .twitter(let authenticationContext):
                let authentication = authenticationContext.authenticationRecord.object(in: managedObjectContext)
                return authentication.flatMap { .twitter(object: $0.user) }
            case .mastodon(let authenticationContext):
                let authentication = authenticationContext.authenticationRecord.object(in: managedObjectContext)
                return authentication.flatMap { .mastodon(object: $0.user) }
            case nil:
                return nil
            }
        }
    }
    
}
