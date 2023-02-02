//
//  ProfileViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-27.
//

import os.log
import Foundation
import Combine
import CoreDataStack
import TwitterSDK

// please override this base class
class ProfileViewModel: ObservableObject {
    
    let logger = Logger(subsystem: "ProfileViewModel", category: "ViewModel")
    
    var disposeBag = Set<AnyCancellable>()
    var observations = Set<NSKeyValueObservation>()
    
    // input
    let context: AppContext
    let authContext: AuthContext
    @Published var me: UserObject?
    @Published var user: UserObject?
    let viewDidAppear = CurrentValueSubject<Void, Never>(Void())
        
    // output
    @Published var userRecord: UserRecord?
    @Published var userIdentifier: UserIdentifier? = nil
    let relationshipViewModel = RelationshipViewModel()

//    let suspended = CurrentValueSubject<Bool, Never>(false)
    
    init(
        context: AppContext,
        authContext: AuthContext
    ) {
        self.context = context
        self.authContext = authContext
        // end init
        
        // bind data after publisher setup
        // otherwise, the flow may omit event without response
        defer {
            $me.assign(to: &relationshipViewModel.$me)
            $user.assign(to: &relationshipViewModel.$user)
        }

        $user
            .map { user in user.flatMap { UserRecord(object: $0) } }
            .assign(to: &$userRecord)
            
        $user
            .map { object -> UserIdentifier? in
                switch object {
                case .twitter(let object):
                    return UserIdentifier.twitter(.init(id: object.id))
                case .mastodon(let object):
                    return UserIdentifier.mastodon(.init(domain: object.domain, id: object.id))
                default:
                    return nil
                }
            }
            .assign(to: &$userIdentifier)
            
        // bind active authentication
        Task {
            let managedObjectContext = self.context.managedObjectContext
            self.me = await managedObjectContext.perform {
                switch authContext.authenticationContext {
                case .twitter(let authenticationContext):
                    let authentication = authenticationContext.authenticationRecord.object(in: managedObjectContext)
                    return authentication.flatMap { .twitter(object: $0.user) }
                case .mastodon(let authenticationContext):
                    let authentication = authenticationContext.authenticationRecord.object(in: managedObjectContext)
                    return authentication.flatMap { .mastodon(object: $0.user) }
                }
            }
        }   // end Task

        // observe friendship
        $userRecord
            .sink { [weak self] userRecord in
                guard let self = self else { return }
                guard let userRecord = userRecord else { return }
                self.dispatchUpdateRelationshipTask(user: userRecord, authenticationContext: self.authContext.authenticationContext)
            }
            .store(in: &disposeBag)
    }

    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
}

extension ProfileViewModel {
    
    private func dispatchUpdateRelationshipTask(
        user record: UserRecord,
        authenticationContext: AuthenticationContext
    ) {
        Task {
            do {
                try await self.updateRelationship(user: record, authenticationContext: authenticationContext)
            } catch {
                self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Relationship] update user relationship failure: \(error.localizedDescription)")
            }
        }
    }
    
    private func updateRelationship(
        user: UserRecord,
        authenticationContext: AuthenticationContext
    ) async throws {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Relationship] update user relationship...")
        switch (user, authenticationContext) {
        case (.twitter(let record), .twitter(let authenticationContext)):
             _ = try await context.apiService.friendship(
                record: record,
                authenticationContext: authenticationContext
            )
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Relationship] did update TwitterUser relationship")
            
        case (.mastodon(let record), .mastodon(let authenticationContext)):
            _ = try await context.apiService.friendship(
                records: [record],
                authenticationContext: authenticationContext
            )
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Relationship] did update MastodonUser relationship")

        default:
            return
        }
    }

//    private func updateAccountSuspendedState(content: Twitter.API.V2.UserLookup.Content, username: String) {
//        guard let twitterAPIError = content.errors?.first.flatMap({ Twitter.API.Error.TwitterAPIError(responseContentError: $0) }) else {
//            return
//        }
//        
//        switch twitterAPIError {
//        case .userHasBeenSuspended:
//            self.suspended.value = true
//            self.username.value = username
//        default:
//            break
//        }
//    }
//    
}
