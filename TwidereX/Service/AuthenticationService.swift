//
//  AuthenticationService.swift
//  TwidereX
//
//  Created by jk234ert on 8/7/20.
//  Copyright © 2020 Dimension. All rights reserved.
//

import os.log
import Foundation
import Combine
import CoreData
import CoreDataStack
import TwitterAPI

class AuthenticationService: NSObject {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    weak var apiService: APIService?
    let managedObjectContext: NSManagedObjectContext
    let twitterAuthenticationFetchedResultsController: NSFetchedResultsController<TwitterAuthentication>
    let twitterUserFetchedResultsController: NSFetchedResultsController<TwitterUser>


    // output
    let twitterAuthentications = CurrentValueSubject<[TwitterAuthentication], Never>([])
    let currentActiveTwitterAutentication = CurrentValueSubject<TwitterAuthentication?, Never>(nil)
    
    let twitterUsers = CurrentValueSubject<[TwitterUser], Never>([])
    let currentTwitterUser = CurrentValueSubject<TwitterUser?, Never>(nil)

    init(managedObjectContext: NSManagedObjectContext, apiService: APIService) {
        self.managedObjectContext = managedObjectContext
        self.apiService = apiService
        self.twitterAuthenticationFetchedResultsController = {
            let fetchRequest = TwitterAuthentication.sortedFetchRequest
            fetchRequest.returnsObjectsAsFaults = false
            fetchRequest.fetchBatchSize = 20
            let controller = NSFetchedResultsController(
                fetchRequest: fetchRequest,
                managedObjectContext: managedObjectContext,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            
            return controller
        }()
        self.twitterUserFetchedResultsController = {
            let fetchRequest = TwitterUser.sortedFetchRequest
            fetchRequest.returnsObjectsAsFaults = false
            fetchRequest.fetchLimit = 1
            let controller = NSFetchedResultsController(
                fetchRequest: fetchRequest,
                managedObjectContext: managedObjectContext,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            
            return controller
        }()
        super.init()
        
        twitterAuthenticationFetchedResultsController.delegate = self
        twitterUserFetchedResultsController.delegate = self
        
        // verify credentials for active authentication (sorted first)
        twitterAuthentications
            .filter { !$0.isEmpty }
            .map { authentications -> AnyPublisher<Result<Twitter.Response.Content<Twitter.Entity.User>?, Error>, Never> in
                assert(self.apiService != nil)
                guard let apiService = self.apiService,
                      let authentication = authentications.first,
                      let authorization = try? authentication.authorization(appSecret: AppSecret.shared) else {
                    return Just(Result.success(nil)).eraseToAnyPublisher()
                }
                
                // prevent error terminate stream
                let result: AnyPublisher<Result<Twitter.Response.Content<Twitter.Entity.User>?, Error>, Never> = Just(authorization)
                    .flatMap { authorization in
                        // send request
                        apiService.verifyCredentials(authorization: authorization)
                        .map { response in Result.success(response) }
                        .catch { error in Just(Result.failure(error)) }
                        .eraseToAnyPublisher()
                    }
                    .eraseToAnyPublisher()
                
                return result
            }
            .switchToLatest()
            .eraseToAnyPublisher()
            .sink { result in
                switch result {
                case .success:
                    os_log("%{public}s[%{public}ld], %{public}s: verifyCredentials success", ((#file as NSString).lastPathComponent), #line, #function)
                case .failure(let error):
                    // Handle error
                    os_log("%{public}s[%{public}ld], %{public}s: verifyCredentials error: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                }
            }
            .store(in: &disposeBag)
        
        // setup publisher
        twitterAuthentications
            .sink(receiveValue: { [weak self] authentications in
                guard let self = self else { return }
                guard !authentications.isEmpty else { return }
                
                self.twitterUserFetchedResultsController.fetchRequest.predicate = TwitterUser.predicate(idStrs: authentications.map { $0.userID })
                do {
                    try self.twitterUserFetchedResultsController.performFetch()
                    self.updateTwitterUsers()
                } catch {
                    assertionFailure(error.localizedDescription)
                }
            })
            .store(in: &disposeBag)
        
        // bind input
        twitterAuthentications
            .map { $0.first }
            .assign(to: \.value, on: currentActiveTwitterAutentication)
            .store(in: &disposeBag)

        
        do {
            try twitterAuthenticationFetchedResultsController.performFetch()
            updateTwitterAuthentications()
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }
}

extension AuthenticationService {
    func updateTwitterAuthentications() {
        let authentications = (twitterAuthenticationFetchedResultsController.fetchedObjects ?? [])
            .filter { (try? $0.authorization(appSecret: AppSecret.shared)) != nil }
            .sorted { lh, rh -> Bool in
                guard let leftActiveAt = lh.activeAt else { return false }
                guard let rightActiveAt = rh.activeAt else { return true }
                return leftActiveAt > rightActiveAt
            }
        self.twitterAuthentications.value = authentications
    }
    
    func updateTwitterUsers() {
        guard twitterUserFetchedResultsController.fetchRequest.predicate != nil else {
            self.twitterUsers.value = []
            self.currentTwitterUser.value = nil
            return
        }
        let twitterUsers = twitterUserFetchedResultsController.fetchedObjects ?? []
        if self.twitterUsers.value != twitterUsers {
            self.twitterUsers.value = twitterUsers
        }
        let activeTwitterUserID = currentActiveTwitterAutentication.value?.userID
        let activeTwitterUser = activeTwitterUserID.flatMap { twitterUserID in
            twitterUsers.first(where: { $0.id == twitterUserID })
        }
        if self.currentTwitterUser.value != activeTwitterUser {
            self.currentTwitterUser.value = activeTwitterUser
        }
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension AuthenticationService: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if controller === twitterAuthenticationFetchedResultsController {
            os_log("%{public}s[%{public}ld], %{public}s: fetch %ld TwitterAuthentication", ((#file as NSString).lastPathComponent), #line, #function, controller.fetchedObjects?.count ?? 0)
            updateTwitterAuthentications()
        }
        if controller === twitterUserFetchedResultsController {
            // os_log("%{public}s[%{public}ld], %{public}s: fetch %ld TwitterUser", ((#file as NSString).lastPathComponent), #line, #function, controller.fetchedObjects?.count ?? 0)
            updateTwitterUsers()
        }
    }
    
}
