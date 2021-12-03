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
    @Published var me: UserObject?
    @Published var user: UserObject?
//    let twitterUser: CurrentValueSubject<TwitterUser?, Never>
//    let currentTwitterUser = CurrentValueSubject<TwitterUser?, Never>(nil)
    let viewDidAppear = CurrentValueSubject<Void, Never>(Void())
        
    // output
    @Published var userRecord: UserRecord?
    let userIdentifier = CurrentValueSubject<UserIdentifier?, Never>(nil)
    let relationshipViewModel = RelationshipViewModel()

//    let suspended = CurrentValueSubject<Bool, Never>(false)
//
//    let avatarStyle = CurrentValueSubject<UserDefaults.AvatarStyle, Never>(UserDefaults.shared.avatarStyle)
    
    init(context: AppContext) {
        self.context = context
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
            .assign(to: \.value, on: userIdentifier)
            .store(in: &disposeBag)

        // bind active authentication
        context.authenticationService.activeAuthenticationContext
            .sink { [weak self] authenticationContext in
                guard let self = self else { return }
                Task {
                    let managedObjectContext = self.context.managedObjectContext
                    self.me = await managedObjectContext.perform {
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
            .store(in: &disposeBag)

        // bind avatar style
//        UserDefaults.shared
//            .observe(\.avatarStyle) { [weak self] defaults, _ in
//                guard let self = self else { return }
//                self.avatarStyle.value = defaults.avatarStyle
//            }
//            .store(in: &observations)

        // observe friendship
        Publishers.CombineLatest(
            $userRecord,
            context.authenticationService.activeAuthenticationContext
        )
        .sink { [weak self] userRecord, authenticationContext in
            guard let self = self else { return }
            guard let userRecord = userRecord,
                  let authenticationContext = authenticationContext
            else { return }
            self.dispatchUpdateRelationshipTask(user: userRecord, authenticationContext: authenticationContext)
        }
        .store(in: &disposeBag)
    }
    
//    convenience init(context: AppContext, twitterUser: TwitterUser) {
//        self.init(context: context, optionalTwitterUser: twitterUser)
//
//        guard let activeTwitterAuthenticationBox = context.authenticationService.activeTwitterAuthenticationBox.value else {
//            return
//        }
//        let userID = twitterUser.id
//        let username = twitterUser.username
//        context.apiService.users(userIDs: [userID], twitterAuthenticationBox: activeTwitterAuthenticationBox)
//            .retry(3)
//            .receive(on: DispatchQueue.main)
//            .sink { completion in
//                switch completion {
//                case .failure(let error):
//                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: user lookup %s fail: %s", ((#file as NSString).lastPathComponent), #line, #function, userID, error.localizedDescription)
//                case .finished:
//                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: user lookup %s success", ((#file as NSString).lastPathComponent), #line, #function, userID)
//                }
//            } receiveValue: { [weak self] response in
//                guard let self = self else { return }
//                self.updateAccountSuspendedState(content: response.value, username: username)
//            }
//            .store(in: &disposeBag)
//    }
//
//    convenience init(context: AppContext, userID: TwitterUser.ID, username: String) {
//        self.init(context: context, optionalTwitterUser: nil)
//
//        guard let activeTwitterAuthenticationBox = context.authenticationService.activeTwitterAuthenticationBox.value else {
//            return
//        }
//        context.apiService.users(userIDs: [userID], twitterAuthenticationBox: activeTwitterAuthenticationBox)
//            .retry(3)
//            .receive(on: DispatchQueue.main)
//            .sink { completion in
//                switch completion {
//                case .failure(let error):
//                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: user lookup %s fail: %s", ((#file as NSString).lastPathComponent), #line, #function, userID, error.localizedDescription)
//                case .finished:
//                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: user lookup %s success", ((#file as NSString).lastPathComponent), #line, #function, userID)
//                }
//            } receiveValue: { [weak self] response in
//                guard let self = self else { return }
//                self.updateAccountSuspendedState(content: response.value, username: username)
//
//                let managedObjectContext = context.managedObjectContext
//                let request = TwitterUser.sortedFetchRequest
//                request.fetchLimit = 1
//                request.predicate = TwitterUser.predicate(idStr: userID)
//                do {
//                    guard let twitterUser = try managedObjectContext.fetch(request).first else {
//                        return
//                    }
//                    self.twitterUser.value = twitterUser
//                } catch {
//                    assertionFailure(error.localizedDescription)
//                }
//            }
//            .store(in: &disposeBag)
//    }
//
//    convenience init(context: AppContext, username: String) {
//        self.init(context: context, optionalTwitterUser: nil)
//
//        guard let activeTwitterAuthenticationBox = context.authenticationService.activeTwitterAuthenticationBox.value else {
//            return
//        }
//        context.apiService.users(usernames: [username], twitterAuthenticationBox: activeTwitterAuthenticationBox)
//            .retry(3)
//            .receive(on: DispatchQueue.main)
//            .sink { completion in
//                switch completion {
//                case .failure(let error):
//                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: user lookup %s fail: %s", ((#file as NSString).lastPathComponent), #line, #function, username, error.localizedDescription)
//                case .finished:
//                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: user lookup %s success", ((#file as NSString).lastPathComponent), #line, #function, username)
//                }
//            } receiveValue: { [weak self] response in
//                guard let self = self else { return }
//                self.updateAccountSuspendedState(content: response.value, username: username)
//
//                let dictContent = Twitter.Response.V2.DictContent(
//                    tweets: [],
//                    users: response.value.data ?? [],
//                    media: [],
//                    places: []
//                )
//                let persistedUser = dictContent.userDict.values.first(where: { user in
//                    user.username.lowercased() == username.lowercased()
//                })
//                guard let user = persistedUser else {
//                    assertionFailure()
//                    return
//                }
//
//                let managedObjectContext = context.managedObjectContext
//                let request = TwitterUser.sortedFetchRequest
//                request.fetchLimit = 1
//                request.predicate = TwitterUser.predicate(username: user.username)
//                do {
//                    guard let twitterUser = try managedObjectContext.fetch(request).first else {
//                        return
//                    }
//                    self.twitterUser.value = twitterUser
//                } catch {
//                    assertionFailure(error.localizedDescription)
//                }
//            }
//            .store(in: &disposeBag)
//    }
    
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
