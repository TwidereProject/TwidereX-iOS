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
    let fetchedResultsController: NSFetchedResultsController<TwitterUser>
    let currentActiveTwitterAutentication = CurrentValueSubject<TwitterAuthentication?, Never>(nil)
    
    // output
    let currentTwitterUser = CurrentValueSubject<TwitterUser?, Never>(nil)
    
    init(context: AppContext) {
        self.context = context
        self.fetchedResultsController = {
            let fetchRequest = TwitterUser.sortedFetchRequest
            fetchRequest.returnsObjectsAsFaults = false
            fetchRequest.fetchLimit = 1
            let controller = NSFetchedResultsController(
                fetchRequest: fetchRequest,
                managedObjectContext: context.managedObjectContext,
                sectionNameKeyPath: nil,
                cacheName: nil
            )

            return controller
        }()
        super.init()
        
        fetchedResultsController.delegate = self
        
        // setup publisher
        currentActiveTwitterAutentication
            .sink(receiveValue: { [weak self] authentication in
                guard let self = self else { return }
                guard let authentication = authentication else { return }
                
                self.fetchedResultsController.fetchRequest.predicate = TwitterUser.predicate(idStr: authentication.userID)
                do {
                    try self.fetchedResultsController.performFetch()
                    // set nil if not match any
                    let twitterUser = self.fetchedResultsController.fetchedObjects?.first
                    self.currentTwitterUser.value = twitterUser
                } catch {
                    assertionFailure(error.localizedDescription)
                }
            })
            .store(in: &disposeBag)
        
        currentTwitterUser
            .sink { twitterUser in
                os_log("%{public}s[%{public}ld], %{public}s: current active twitter user: %s", ((#file as NSString).lastPathComponent), #line, #function, twitterUser?.screenName ?? "<nil>")
            }
            .store(in: &disposeBag)
            
        
        // bind input
        context.authenticationService.twitterAuthentications
            .map { $0.first }
            .assign(to: \.value, on: currentActiveTwitterAutentication)
            .store(in: &disposeBag)
    }
    
}

// MARK: - NSFetchedResultsControllerDelegate
extension MeProfileViewModel: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // set nil if not match any
        let twitterUser = controller.fetchedObjects?.first as? TwitterUser
        currentTwitterUser.value = twitterUser
    }
}
