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
//    private var twitterUserObserver: AnyCancellable?
//    private var currentTwitterUserObserver: AnyCancellable?
    
    // input
    let context: AppContext
    @Published var me: UserObject?
    @Published var user: UserObject?
//    let twitterUser: CurrentValueSubject<TwitterUser?, Never>
//    let currentTwitterUser = CurrentValueSubject<TwitterUser?, Never>(nil)
//    let viewDidAppear = PassthroughSubject<Void, Never>()
        
    // output
    @Published var userRecord: UserRecord?
    let userIdentifier = CurrentValueSubject<UserIdentifier?, Never>(nil)
    let relationshipViewModel = RelationshipViewModel()

//    let suspended = CurrentValueSubject<Bool, Never>(false)
//
//    let avatarStyle = CurrentValueSubject<UserDefaults.AvatarStyle, Never>(UserDefaults.shared.avatarStyle)
    
    init(context: AppContext) {
        self.context = context
        $me.assign(to: &relationshipViewModel.$me)
        $user.assign(to: &relationshipViewModel.$user)
        //        super.init()
        // end init
        
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
                            return authentication.flatMap { .twitter(object: $0.twitterUser) }
                        case .mastodon(let authenticationContext):
                            let authentication = authenticationContext.authenticationRecord.object(in: managedObjectContext)
                            return authentication.flatMap { .mastodon(object: $0.mastodonUser) }
                        case nil:
                            return nil
                        }
                    }
                }
            }
            .store(in: &disposeBag)

//        // bind avatar style
//        UserDefaults.shared
//            .observe(\.avatarStyle) { [weak self] defaults, _ in
//                guard let self = self else { return }
//                self.avatarStyle.value = defaults.avatarStyle
//            }
//            .store(in: &observations)
//
//        setup()
//
//        // query latest friendship
        Publishers.CombineLatest(
            $userRecord,
            context.authenticationService.activeAuthenticationContext
        )
        .sink { [weak self] userRecord, authenticationContext in
            guard let self = self else { return }
            guard let userRecord = userRecord,
                  let authenticationContext = authenticationContext
            else { return }
            Task {
                do {
                    try await self.updateRelationship(user: userRecord, authenticationContext: authenticationContext)
                } catch {
                    self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Relationship] update user relationship failure: \(error.localizedDescription)")
                }
            }
        }
        .store(in: &disposeBag)
//        .compactMap { twitterUser, activeTwitterAuthenticationBox -> (TwitterUser, AuthenticationService.TwitterAuthenticationBox)? in
//            guard let twitterUser = twitterUser, let activeTwitterAuthenticationBox = activeTwitterAuthenticationBox else { return nil }
//            return (twitterUser, activeTwitterAuthenticationBox)
//        }
//        .setFailureType(to: Error.self)
//        .map { twitterUser, activeTwitterAuthenticationBox -> AnyPublisher<Twitter.Response.Content<Twitter.Entity.Relationship>, Error> in
//            // Fix crash issue on the iOS 14.1
//            // seealso: CombineTests.swift
//            if #available(iOS 14.2, *) {
//                return self.context.apiService.friendship(twitterUserObjectID: twitterUser.objectID, twitterAuthenticationBox: activeTwitterAuthenticationBox)
//                    .retry(3)
//                    .eraseToAnyPublisher()
//            } else {
//                return self.context.apiService.friendship(twitterUserObjectID: twitterUser.objectID, twitterAuthenticationBox: activeTwitterAuthenticationBox)
//                    .eraseToAnyPublisher()
//            }
//        }
//        .switchToLatest()
//        .sink { completion in
//            switch completion {
//            case .failure(let error):
//                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: fetch friendship fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
//            case .finished:
//                break
//            }
//        } receiveValue: { [weak self] response in
//            guard let self = self else { return }
//            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: fetch friendship success", ((#file as NSString).lastPathComponent), #line, #function)
//            // friendship state will update via ManagedObjectObserver
//        }
//        .store(in: &disposeBag)
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
            
            return
        default:
            return
        }
        
//        Publishers.CombineLatest(
//            twitterUser.eraseToAnyPublisher(),
//            currentTwitterUser.eraseToAnyPublisher()
//        )
//        .receive(on: DispatchQueue.main)
//        .sink { [weak self] twitterUser, currentTwitterUser in
//            guard let self = self else { return }
//            self.update(twitterUser: twitterUser)
//            self.update(twitterUser: twitterUser, currentTwitterUser: currentTwitterUser)
//            
//            if let twitterUser = twitterUser {
//                // setup observer
//                self.twitterUserObserver = ManagedObjectObserver.observe(object: twitterUser)
//                    .sink { completion in
//                        switch completion {
//                        case .failure(let error):
//                            assertionFailure(error.localizedDescription)
//                        case .finished:
//                            assertionFailure()
//                        }
//                    } receiveValue: { [weak self] change in
//                        guard let self = self else { return }
//                        guard let changeType = change.changeType else { return }
//                        switch changeType {
//                        case .update:
//                            self.update(twitterUser: twitterUser)
//                            self.update(twitterUser: twitterUser, currentTwitterUser: currentTwitterUser)
//                        case .delete:
//                            // TODO:
//                            break
//                        }
//                    }
//                
//            } else {
//                self.twitterUserObserver = nil
//            }
//            
//            if let currentTwitterUser = currentTwitterUser {
//                // setup observer
//                self.currentTwitterUserObserver = ManagedObjectObserver.observe(object: currentTwitterUser)
//                    .sink { completion in
//                        switch completion {
//                        case .failure(let error):
//                            assertionFailure(error.localizedDescription)
//                        case .finished:
//                            assertionFailure()
//                        }
//                    } receiveValue: { [weak self] change in
//                        guard let self = self else { return }
//                        guard let changeType = change.changeType else { return }
//                        switch changeType {
//                        case .update:
//                            self.update(twitterUser: twitterUser, currentTwitterUser: currentTwitterUser)
//                        case .delete:
//                            // TODO:
//                            break
//                        }
//                    }
//            } else {
//                self.currentTwitterUserObserver = nil
//            }
//        }
//        .store(in: &disposeBag)
    }
//    
//    private func update(twitterUser: TwitterUser?) {
//        self.userID.value = twitterUser?.id
//        self.bannerImageURL.value = twitterUser?.profileBannerURL(sizeKind: .large)
//        self.avatarImageURL.value = twitterUser?.avatarImageURL(size: .original)
//        self.protected.value = twitterUser?.protected
//        self.verified.value = twitterUser?.verified ?? false
//        self.name.value = twitterUser?.name
//        self.username.value = twitterUser?.username
//        self.bioDescription.value = twitterUser?.displayBioDescription
//        self.url.value = twitterUser?.displayURL
//        self.location.value = twitterUser?.location
////        self.friendsCount.value = twitterUser?.metrics?.followingCount.flatMap { Int(truncating: $0) }
////        self.followersCount.value = twitterUser?.metrics?.followersCount.flatMap { Int(truncating: $0) }
////        self.listedCount.value = twitterUser?.metrics?.listedCount.flatMap{ Int(truncating: $0) }
//    }
//    
//    private func update(twitterUser: TwitterUser?, currentTwitterUser: TwitterUser?) {
//        guard let twitterUser = twitterUser,
//              let currentTwitterUser = currentTwitterUser else {
//            self.friendship.value = nil
//            self.followedBy.value = nil
//            return
//        }
//        
//        if twitterUser == currentTwitterUser {
//            self.friendship.value = nil
//            self.followedBy.value = nil
//        } else {
//            let isFollowing = twitterUser.followingBy.contains(currentTwitterUser)
//            let isPending = twitterUser.followRequestSentFrom.contains(currentTwitterUser)
//            let friendship = isPending ? .pending : (isFollowing) ? .following : ProfileViewModel.Friendship.none
//            self.friendship.value = friendship
//            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: friendship update: %s", ((#file as NSString).lastPathComponent), #line, #function, friendship.debugDescription)
//            
//            let followedBy = currentTwitterUser.followingBy.contains(twitterUser)
//            self.followedBy.value = followedBy
//            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: followedBy update: %s", ((#file as NSString).lastPathComponent), #line, #function, followedBy ? "true" : "false")
//            
//            let muted = twitterUser.mutingBy.contains(currentTwitterUser)
//            self.muted.value = muted
//            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: muted update: %s", ((#file as NSString).lastPathComponent), #line, #function, muted ? "true" : "false")
//            
//            let blocked = twitterUser.blockingBy.contains(currentTwitterUser)
//            self.blocked.value = blocked
//            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: blocked update: %s", ((#file as NSString).lastPathComponent), #line, #function, blocked ? "true" : "false")
//        }
//    }
//    
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
