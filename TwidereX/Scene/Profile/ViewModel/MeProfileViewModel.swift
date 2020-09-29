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
import TwitterAPI

final class MeProfileViewModel: ProfileViewModel {
            
    // input
    let context: AppContext
    
    // output
    let currentTwitterUser = CurrentValueSubject<TwitterUser?, Never>(nil)
    
    init(context: AppContext) {
        self.context = context
        super.init()
        
        currentTwitterUser
            .sink { [weak self] twitterUser in
                os_log("%{public}s[%{public}ld], %{public}s: current active twitter user: %s", ((#file as NSString).lastPathComponent), #line, #function, twitterUser?.screenName ?? "<nil>")
                
                guard let self = self else { return }
                self.update(twitterUser: twitterUser)
            }
            .store(in: &disposeBag)
            
        
        context.authenticationService.currentTwitterUser
            .assign(to: \.value, on: currentTwitterUser)
            .store(in: &disposeBag)
    }
    
}

// MARK: - NSFetchedResultsControllerDelegate
extension MeProfileViewModel: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        os_log("%{public}s[%{public}ld], %{public}s: fetch %ld TwitterUser object", ((#file as NSString).lastPathComponent), #line, #function, controller.fetchedObjects?.count ?? 0)

        // set nil if not match any
        let twitterUser = controller.fetchedObjects?.first as? TwitterUser
        currentTwitterUser.value = twitterUser
    }
}
