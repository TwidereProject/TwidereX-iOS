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

    // output
    let twitterAuthentications = CurrentValueSubject<[TwitterAuthentication], Never>([])
    let currentTwitterUser = CurrentValueSubject<Twitter.Entity.User?, Never>(nil)
    
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
        super.init()
        
        twitterAuthentications
            .filter { !$0.isEmpty }
            .map { authentications -> AnyPublisher<Result<Twitter.Response<Twitter.Entity.User>?, Error>, Never> in
                assert(self.apiService != nil)
                guard let apiService = self.apiService,
                      let authentication = authentications.first,
                      let authorization = try? authentication.authorization(appSecret: AppSecret.shared) else {
                    return Just(Result.success(nil)).eraseToAnyPublisher()
                }
                
                // prevent terminate stream
                let result: AnyPublisher<Result<Twitter.Response<Twitter.Entity.User>?, Error>, Never> = Just(authorization)
                    .flatMap { authorization in
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
            
        twitterAuthenticationFetchedResultsController.delegate = self
        do {
            try twitterAuthenticationFetchedResultsController.performFetch()
            let authentications = (twitterAuthenticationFetchedResultsController.fetchedObjects ?? [])
                .filter { (try? $0.authorization(appSecret: AppSecret.shared)) != nil }
                .sorted { lh, rh -> Bool in
                    guard let leftActiveAt = lh.activeAt else { return false }
                    guard let rightActiveAt = rh.activeAt else { return true }
                    return leftActiveAt > rightActiveAt
                }
            self.twitterAuthentications.value = authentications
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension AuthenticationService: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        let authentications = (controller.fetchedObjects ?? [])
            .compactMap { $0 as? TwitterAuthentication }
            .filter { (try? $0.authorization(appSecret: AppSecret.shared)) != nil }
            .sorted { lh, rh -> Bool in
                guard let leftActiveAt = lh.activeAt else { return false }
                guard let rightActiveAt = rh.activeAt else { return true }
                return leftActiveAt > rightActiveAt
            }
        self.twitterAuthentications.value = authentications
    }
    
}
