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
    let managedObjectContext: NSManagedObjectContext    // read-only
    let backgroundManagedObjectContext: NSManagedObjectContext
    let authenticationIndexFetchedResultsController: NSFetchedResultsController<AuthenticationIndex>

    // output
    let authenticationIndexes = CurrentValueSubject<[AuthenticationIndex], Never>([])
    let activeAuthenticationIndex = CurrentValueSubject<AuthenticationIndex?, Never>(nil)
    let activeTwitterAuthenticationBox = CurrentValueSubject<AuthenticationService.TwitterAuthenticationBox?, Never>(nil)

    init(
        managedObjectContext: NSManagedObjectContext,
        backgroundManagedObjectContext: NSManagedObjectContext,
        apiService: APIService
    ) {
        self.managedObjectContext = managedObjectContext
        self.backgroundManagedObjectContext = backgroundManagedObjectContext
        self.apiService = apiService
        self.authenticationIndexFetchedResultsController = {
            let fetchRequest = AuthenticationIndex.sortedFetchRequest
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

        authenticationIndexFetchedResultsController.delegate = self

        // verify credentials for active authentication
        activeAuthenticationIndex
            .map { [weak self] activeAuthenticationIndex -> AnyPublisher<Result<Twitter.Response.Content<Twitter.Entity.User>?, Error>, Never> in
                guard let self = self,
                      let activeAuthenticationIndex = activeAuthenticationIndex,
                      let apiService = self.apiService,
                      let twitterAuthentication = activeAuthenticationIndex.twitterAuthentication,
                      let authorization = try? twitterAuthentication.authorization(appSecret: AppSecret.default) else {
                    return Just(Result.success(nil)).eraseToAnyPublisher()
                }
                
                return Just(authorization)
                    .flatMap { authorization -> AnyPublisher<Result<Twitter.Response.Content<Twitter.Entity.User>?, Error>, Never> in
                        // send request
                        apiService.verifyCredentials(authorization: authorization)
                            .map { response in Result.success(response) }
                            .catch { error in Just(Result.failure(error)) }
                            .eraseToAnyPublisher()
                    }
                    .eraseToAnyPublisher()
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

        // bind data
        authenticationIndexes
            .map { $0.sorted(by: { $0.activedAt > $1.activedAt }).first }
            .assign(to: \.value, on: activeAuthenticationIndex)
            .store(in: &disposeBag)
        
        activeAuthenticationIndex
            .map { activeAuthenticationIndex -> AuthenticationService.TwitterAuthenticationBox? in
                guard let activeAuthenticationIndex = activeAuthenticationIndex else  { return nil }
                guard let twitterAuthentication = activeAuthenticationIndex.twitterAuthentication else { return nil }
                guard let authorization = try? twitterAuthentication.authorization(appSecret: .default) else { return nil }
                return AuthenticationService.TwitterAuthenticationBox(
                    authenticationIndexObjectID: activeAuthenticationIndex.objectID,
                    twitterUserID: twitterAuthentication.userID,
                    twitterAuthorization: authorization
                )
            }
            .assign(to: \.value, on: activeTwitterAuthenticationBox)
            .store(in: &disposeBag)

        do {
            try authenticationIndexFetchedResultsController.performFetch()
            authenticationIndexes.value = authenticationIndexFetchedResultsController.fetchedObjects ?? []
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }
    
}

extension AuthenticationService {
    
    struct TwitterAuthenticationBox {
        let authenticationIndexObjectID: NSManagedObjectID
        let twitterUserID: TwitterUser.ID
        let twitterAuthorization: Twitter.API.OAuth.Authorization
    }

}

extension AuthenticationService {
    
    func activeTwitterUser(id: TwitterUser.ID) -> AnyPublisher<Result<Bool, Error>, Never> {
        var isActived = false
        
        return backgroundManagedObjectContext.performChanges {
            let request = TwitterAuthentication.sortedFetchRequest
            let twitterAutentications = try? self.backgroundManagedObjectContext.fetch(request)
            guard let activeTwitterAutentication = (twitterAutentications ?? []).first(where: { $0.userID == id }) else { return }
            guard let authenticationIndex = activeTwitterAutentication.authenticationIndex else { return }
            authenticationIndex.update(activedAt: Date())
            isActived = true
        }
        .map { result in
            return result.map { isActived }
        }
        .eraseToAnyPublisher()
    }
    
    func signOutTwitterUser(id: TwitterUser.ID) -> AnyPublisher<Result<Bool, Error>, Never> {
        var isSignOut = false
        
        return backgroundManagedObjectContext.performChanges {
            let request = TwitterAuthentication.sortedFetchRequest
            let twitterAutentications = try? self.backgroundManagedObjectContext.fetch(request)
            guard let deleteTwitterAutentication = (twitterAutentications ?? []).first(where: { $0.userID == id }) else { return }
            guard let authenticationIndex = deleteTwitterAutentication.authenticationIndex else { return }
            self.backgroundManagedObjectContext.delete(authenticationIndex)
            self.backgroundManagedObjectContext.delete(deleteTwitterAutentication)
            isSignOut = true
        }
        .map { result in
            return result.map { isSignOut }
        }
        .eraseToAnyPublisher()
    }
    
}

// MARK: - NSFetchedResultsControllerDelegate
extension AuthenticationService: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
         os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if controller === authenticationIndexFetchedResultsController {
            authenticationIndexes.value = authenticationIndexFetchedResultsController.fetchedObjects ?? []
        }
    }
    
}
