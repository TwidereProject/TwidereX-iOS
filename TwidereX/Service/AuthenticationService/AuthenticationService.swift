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
import AppShared
import TwitterSDK

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
    
    let activeAuthenticationContext = CurrentValueSubject<AuthenticationContext?, Never>(nil)
    
    @available(*, deprecated, message: "")
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
        // FIXME:
//        activeAuthenticationIndex
//            .map { [weak self] activeAuthenticationIndex -> AnyPublisher<Result<Twitter.Response.Content<Twitter.Entity.User>?, Error>, Never> in
//                guard let self = self,
//                      let activeAuthenticationIndex = activeAuthenticationIndex,
//                      let apiService = self.apiService,
//                      let twitterAuthentication = activeAuthenticationIndex.twitterAuthentication,
//                      let authorization = try? twitterAuthentication.authorization(appSecret: AppSecret.default) else {
//                    return Just(Result.success(nil)).eraseToAnyPublisher()
//                }
//
//                return Just(authorization)
//                    .flatMap { authorization -> AnyPublisher<Result<Twitter.Response.Content<Twitter.Entity.User>?, Error>, Never> in
//                        // send request
//                        apiService.verifyTwitterCredentials(authorization: authorization)
//                            .map { response in Result.success(response) }
//                            .catch { error in Just(Result.failure(error)) }
//                            .eraseToAnyPublisher()
//                    }
//                    .eraseToAnyPublisher()
//            }
//            .switchToLatest()
//            .eraseToAnyPublisher()
//            .sink { result in
//                switch result {
//                case .success:
//                    os_log("%{public}s[%{public}ld], %{public}s: verifyTwitterCredentials success", ((#file as NSString).lastPathComponent), #line, #function)
//                case .failure(let error):
//                    // Handle error
//                    os_log("%{public}s[%{public}ld], %{public}s: verifyTwitterCredentials error: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
//                }
//            }
//            .store(in: &disposeBag)

        // bind activeAuthenticationIndex
        authenticationIndexes
            .map { $0.sorted(by: { $0.activeAt > $1.activeAt }).first }
            .assign(to: \.value, on: activeAuthenticationIndex)
            .store(in: &disposeBag)
        
        // bind activeAuthenticationContext
        activeAuthenticationIndex
            .map { authenticationIndex -> AuthenticationContext? in
                guard let authenticationIndex = authenticationIndex else { return nil }
                guard let authenticationContext = AuthenticationContext(authenticationIndex: authenticationIndex) else { return nil }
                return authenticationContext
            }
            .assign(to: \.value, on: activeAuthenticationContext)
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
    
    @available(*, deprecated, message: "use TwitterAuthenticationContext")
    struct TwitterAuthenticationBox {
        let authenticationIndexObjectID: NSManagedObjectID
        let twitterUserID: TwitterUser.ID
        let twitterAuthorization: Twitter.API.OAuth.Authorization
    }
    
}

extension AuthenticationService {
    
    func activeTwitterUser(userID: TwitterUser.ID) async throws -> Bool {
        let managedObjectContext = backgroundManagedObjectContext
        let isActive = try await managedObjectContext.performChanges { () -> Bool in
            let request = TwitterAuthentication.sortedFetchRequest
            request.predicate = TwitterAuthentication.predicate(userID: userID)
            request.fetchLimit = 1
            guard let authentication = try? managedObjectContext.fetch(request).first else {
                return false
            }
            // set active
            authentication.authenticationIndex.update(activeAt: Date())
            return true
        }
        
        return isActive
    }
    
    func signOutTwitterUser(id: TwitterUser.ID) -> AnyPublisher<Result<Bool, Error>, Never> {
        var isSignOut = false
        
        return backgroundManagedObjectContext.performChanges {
            let request = TwitterAuthentication.sortedFetchRequest
            let twitterAuthentications = try? self.backgroundManagedObjectContext.fetch(request)
            guard let deleteTwitterAuthentication = (twitterAuthentications ?? []).first(where: { $0.userID == id }) else { return }
            let authenticationIndex = deleteTwitterAuthentication.authenticationIndex
            self.backgroundManagedObjectContext.delete(authenticationIndex)
            self.backgroundManagedObjectContext.delete(deleteTwitterAuthentication)
            isSignOut = true
        }
        .map { result in
            return result.map { isSignOut }
        }
        .eraseToAnyPublisher()
    }
    
}

extension AuthenticationService {
    func activeMastodonUser(domain: String, userID: MastodonUser.ID) async throws -> Bool {
        let managedObjectContext = backgroundManagedObjectContext
        let isActive = try await managedObjectContext.performChanges { () -> Bool in
            let request = MastodonAuthentication.sortedFetchRequest
            request.predicate = MastodonAuthentication.predicate(domain: domain, userID: userID)
            request.fetchLimit = 1
            guard let authentication = try? managedObjectContext.fetch(request).first else {
                return false
            }
            // set active
            authentication.authenticationIndex.update(activeAt: Date())
            return true
        }
        
        return isActive
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension AuthenticationService: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
         os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        switch controller {
        case authenticationIndexFetchedResultsController:
            authenticationIndexes.value = authenticationIndexFetchedResultsController.fetchedObjects ?? []
        default:
            assertionFailure()
        }
    }
    
}
