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
                      let authorization = try? twitterAuthentication.authorization(appSecret: AppSecret.shared) else {
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
                guard let authorization = try? twitterAuthentication.authorization(appSecret: .shared) else { return nil }
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
            //updateTwitterAuthentications()
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
    
//    func signOutTwitterUser(id: TwitterUser.ID) -> AnyPublisher<Result<Void, Error>, Never> {
//        let removingObjectIDs = twitterAuthentications.value
//            .filter { $0.userID == id }
//            .map { $0.objectID }
//
//        let backgroundManagedObjectContext = self.backgroundManagedObjectContext
//        return backgroundManagedObjectContext.performChanges {
//            for objectID in removingObjectIDs {
//                let removingTwitterAuthentication = backgroundManagedObjectContext.object(with: objectID) as! TwitterAuthentication
//                backgroundManagedObjectContext.delete(removingTwitterAuthentication)
//            }
//        }
//        .eraseToAnyPublisher()
//    }
    
}

extension AuthenticationService {
//    private func updateTwitterAuthentications() {
//        let authentications = (twitterAuthenticationFetchedResultsController.fetchedObjects ?? [])
//            .filter { (try? $0.authorization(appSecret: AppSecret.shared)) != nil }
//            .sorted { lh, rh -> Bool in
//                guard let leftActiveAt = lh.activeAt else { return false }
//                guard let rightActiveAt = rh.activeAt else { return true }
//                return leftActiveAt > rightActiveAt
//            }
//        self.twitterAuthentications.value = authentications
//    }
//
//    private func updateTwitterUsers() {
//        guard !twitterAuthentications.value.isEmpty else {
//            twitterUsers.value = []
//            currentTwitterUser.value = nil
//            return
//        }
//        guard twitterUserFetchedResultsController.fetchRequest.predicate != nil else {
//            twitterUsers.value = []
//            currentTwitterUser.value = nil
//            return
//        }
//        let twitterUsers = twitterUserFetchedResultsController.fetchedObjects ?? []
//        if self.twitterUsers.value != twitterUsers {
//            self.twitterUsers.value = twitterUsers
//        }
//        let activeTwitterUserID = twitterAuthentications.value.first?.userID
//        let activeTwitterUser = activeTwitterUserID.flatMap { twitterUserID in
//            twitterUsers.first(where: { $0.id == twitterUserID })
//        }
//        if self.currentTwitterUser.value != activeTwitterUser {
//            self.currentTwitterUser.value = activeTwitterUser
//        }
//    }
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
