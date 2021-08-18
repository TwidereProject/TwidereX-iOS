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
class ProfileViewModel: NSObject {
    
    var disposeBag = Set<AnyCancellable>()
    var observations = Set<NSKeyValueObservation>()
    private var twitterUserObserver: AnyCancellable?
    private var currentTwitterUserObserver: AnyCancellable?
    
    // input
    let context: AppContext
    let twitterUser: CurrentValueSubject<TwitterUser?, Never>
    let currentTwitterUser = CurrentValueSubject<TwitterUser?, Never>(nil)
    let viewDidAppear = PassthroughSubject<Void, Never>()
        
    // output
    let userID: CurrentValueSubject<String?, Never>
    let bannerImageURL: CurrentValueSubject<URL?, Never>
    let avatarImageURL: CurrentValueSubject<URL?, Never>
    let protected: CurrentValueSubject<Bool?, Never>
    let verified: CurrentValueSubject<Bool, Never>
    let name: CurrentValueSubject<String?, Never>
    let username: CurrentValueSubject<String?, Never>
    let bioDescription: CurrentValueSubject<String?, Never>
    let url: CurrentValueSubject<String?, Never>
    let location: CurrentValueSubject<String?, Never>
    let friendsCount: CurrentValueSubject<Int?, Never>
    let followersCount: CurrentValueSubject<Int?, Never>
    let listedCount: CurrentValueSubject<Int?, Never>

    let friendship: CurrentValueSubject<Friendship?, Never>
    let followedBy: CurrentValueSubject<Bool?, Never>
    let muted: CurrentValueSubject<Bool, Never>
    let blocked: CurrentValueSubject<Bool, Never>
    
    let suspended = CurrentValueSubject<Bool, Never>(false)
    
    let avatarStyle = CurrentValueSubject<UserDefaults.AvatarStyle, Never>(UserDefaults.shared.avatarStyle)
    
    // FIXME: multi-platform support
    init(context: AppContext, optionalTwitterUser twitterUser: TwitterUser?) {
        self.context = context
        self.twitterUser = CurrentValueSubject(twitterUser)
        self.userID = CurrentValueSubject(twitterUser?.id)
        self.bannerImageURL = CurrentValueSubject(twitterUser?.profileBannerURL(sizeKind: .large))
        self.avatarImageURL = CurrentValueSubject(twitterUser?.avatarImageURL(size: .original))
        self.protected = CurrentValueSubject(twitterUser?.protected)
        self.verified = CurrentValueSubject(twitterUser?.verified ?? false)
        self.name = CurrentValueSubject(twitterUser?.name)
        self.username = CurrentValueSubject(twitterUser?.username)
        self.bioDescription = CurrentValueSubject(twitterUser?.displayBioDescription)
        self.url = CurrentValueSubject(twitterUser?.displayURL)
        self.location = CurrentValueSubject(twitterUser?.location)
        self.friendsCount = CurrentValueSubject(twitterUser?.metrics?.followingCount.flatMap { Int(truncating: $0) })
        self.followersCount = CurrentValueSubject(twitterUser?.metrics?.followersCount.flatMap { Int(truncating: $0) })
        self.listedCount = CurrentValueSubject(twitterUser?.metrics?.listedCount.flatMap{ Int(truncating: $0) })
        self.friendship = CurrentValueSubject(nil)
        self.followedBy = CurrentValueSubject(nil)
        self.muted = CurrentValueSubject(false)
        self.blocked = CurrentValueSubject(false)
        super.init()

        // bind active authentication
        context.authenticationService.activeAuthenticationIndex
            .sink { [weak self] activeAuthenticationIndex in
                guard let self = self else { return }
                guard let activeAuthenticationIndex = activeAuthenticationIndex else {
                    self.currentTwitterUser.value = nil
                    return
                }
                let platform = activeAuthenticationIndex.platform
                switch platform {
                case .twitter:
                    self.currentTwitterUser.value = activeAuthenticationIndex.twitterAuthentication?.twitterUser
                case .mastodon:
                    self.currentTwitterUser.value = nil
                case .none:
                    self.currentTwitterUser.value = nil
                }
            }
            .store(in: &disposeBag)
        
        // bind avatar style
        UserDefaults.shared
            .observe(\.avatarStyle) { [weak self] defaults, _ in
                guard let self = self else { return }
                self.avatarStyle.value = defaults.avatarStyle
            }
            .store(in: &observations)
        
        setup()
        
        // query latest friendship
        Publishers.CombineLatest(
            self.twitterUser.eraseToAnyPublisher(),
            context.authenticationService.activeTwitterAuthenticationBox.eraseToAnyPublisher()
        )
        .compactMap { twitterUser, activeTwitterAuthenticationBox -> (TwitterUser, AuthenticationService.TwitterAuthenticationBox)? in
            guard let twitterUser = twitterUser, let activeTwitterAuthenticationBox = activeTwitterAuthenticationBox else { return nil }
            return (twitterUser, activeTwitterAuthenticationBox)
        }
        .setFailureType(to: Error.self)
        .map { twitterUser, activeTwitterAuthenticationBox -> AnyPublisher<Twitter.Response.Content<Twitter.Entity.Relationship>, Error> in
            // Fix crash issue on the iOS 14.1
            // seealso: CombineTests.swift
            if #available(iOS 14.2, *) {
                return self.context.apiService.friendship(twitterUserObjectID: twitterUser.objectID, twitterAuthenticationBox: activeTwitterAuthenticationBox)
                    .retry(3)
                    .eraseToAnyPublisher()
            } else {
                return self.context.apiService.friendship(twitterUserObjectID: twitterUser.objectID, twitterAuthenticationBox: activeTwitterAuthenticationBox)
                    .eraseToAnyPublisher()
            }
        }
        .switchToLatest()
        .sink { completion in
            switch completion {
            case .failure(let error):
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: fetch friendship fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
            case .finished:
                break
            }
        } receiveValue: { [weak self] response in
            guard let self = self else { return }
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: fetch friendship success", ((#file as NSString).lastPathComponent), #line, #function)
            // friendship state will update via ManagedObjectObserver
        }
        .store(in: &disposeBag)
    }
    
    convenience init(context: AppContext, twitterUser: TwitterUser) {
        self.init(context: context, optionalTwitterUser: twitterUser)
        
        guard let activeTwitterAuthenticationBox = context.authenticationService.activeTwitterAuthenticationBox.value else {
            return
        }
        let userID = twitterUser.id
        let username = twitterUser.username
        context.apiService.users(userIDs: [userID], twitterAuthenticationBox: activeTwitterAuthenticationBox)
            .retry(3)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: user lookup %s fail: %s", ((#file as NSString).lastPathComponent), #line, #function, userID, error.localizedDescription)
                case .finished:
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: user lookup %s success", ((#file as NSString).lastPathComponent), #line, #function, userID)
                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }
                self.updateAccountSuspendedState(content: response.value, username: username)
            }
            .store(in: &disposeBag)
    }
    
    convenience init(context: AppContext, userID: TwitterUser.ID, username: String) {
        self.init(context: context, optionalTwitterUser: nil)
        
        guard let activeTwitterAuthenticationBox = context.authenticationService.activeTwitterAuthenticationBox.value else {
            return
        }
        context.apiService.users(userIDs: [userID], twitterAuthenticationBox: activeTwitterAuthenticationBox)
            .retry(3)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: user lookup %s fail: %s", ((#file as NSString).lastPathComponent), #line, #function, userID, error.localizedDescription)
                case .finished:
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: user lookup %s success", ((#file as NSString).lastPathComponent), #line, #function, userID)
                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }
                self.updateAccountSuspendedState(content: response.value, username: username)
                
                let managedObjectContext = context.managedObjectContext
                let request = TwitterUser.sortedFetchRequest
                request.fetchLimit = 1
                request.predicate = TwitterUser.predicate(idStr: userID)
                do {
                    guard let twitterUser = try managedObjectContext.fetch(request).first else {
                        return
                    }
                    self.twitterUser.value = twitterUser
                } catch {
                    assertionFailure(error.localizedDescription)
                }
            }
            .store(in: &disposeBag)
    }
    
    convenience init(context: AppContext, username: String) {
        self.init(context: context, optionalTwitterUser: nil)
        
        guard let activeTwitterAuthenticationBox = context.authenticationService.activeTwitterAuthenticationBox.value else {
            return
        }
        context.apiService.users(usernames: [username], twitterAuthenticationBox: activeTwitterAuthenticationBox)
            .retry(3)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: user lookup %s fail: %s", ((#file as NSString).lastPathComponent), #line, #function, username, error.localizedDescription)
                case .finished:
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: user lookup %s success", ((#file as NSString).lastPathComponent), #line, #function, username)
                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }
                self.updateAccountSuspendedState(content: response.value, username: username)
                
                let dictContent = Twitter.Response.V2.DictContent(
                    tweets: [],
                    users: response.value.data ?? [],
                    media: [],
                    places: []
                )
                let persistedUser = dictContent.userDict.values.first(where: { user in
                    user.username.lowercased() == username.lowercased()
                })
                guard let user = persistedUser else {
                    assertionFailure()
                    return
                }
                
                let managedObjectContext = context.managedObjectContext
                let request = TwitterUser.sortedFetchRequest
                request.fetchLimit = 1
                request.predicate = TwitterUser.predicate(username: user.username)
                do {
                    guard let twitterUser = try managedObjectContext.fetch(request).first else {
                        return
                    }
                    self.twitterUser.value = twitterUser
                } catch {
                    assertionFailure(error.localizedDescription)
                }
            }
            .store(in: &disposeBag)
    }
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
}

extension ProfileViewModel {
    
    enum Friendship: CustomDebugStringConvertible {
        case following
        case pending
        case none
        
        var debugDescription: String {
            switch self {
            case .following:        return "following"
            case .pending:          return "pending"
            case .none:             return "none"
            }
        }
    }
    
}

extension ProfileViewModel {
    private func setup() {
        Publishers.CombineLatest(
            twitterUser.eraseToAnyPublisher(),
            currentTwitterUser.eraseToAnyPublisher()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] twitterUser, currentTwitterUser in
            guard let self = self else { return }
            self.update(twitterUser: twitterUser)
            self.update(twitterUser: twitterUser, currentTwitterUser: currentTwitterUser)
            
            if let twitterUser = twitterUser {
                // setup observer
                self.twitterUserObserver = ManagedObjectObserver.observe(object: twitterUser)
                    .sink { completion in
                        switch completion {
                        case .failure(let error):
                            assertionFailure(error.localizedDescription)
                        case .finished:
                            assertionFailure()
                        }
                    } receiveValue: { [weak self] change in
                        guard let self = self else { return }
                        guard let changeType = change.changeType else { return }
                        switch changeType {
                        case .update:
                            self.update(twitterUser: twitterUser)
                            self.update(twitterUser: twitterUser, currentTwitterUser: currentTwitterUser)
                        case .delete:
                            // TODO:
                            break
                        }
                    }
                
            } else {
                self.twitterUserObserver = nil
            }
            
            if let currentTwitterUser = currentTwitterUser {
                // setup observer
                self.currentTwitterUserObserver = ManagedObjectObserver.observe(object: currentTwitterUser)
                    .sink { completion in
                        switch completion {
                        case .failure(let error):
                            assertionFailure(error.localizedDescription)
                        case .finished:
                            assertionFailure()
                        }
                    } receiveValue: { [weak self] change in
                        guard let self = self else { return }
                        guard let changeType = change.changeType else { return }
                        switch changeType {
                        case .update:
                            self.update(twitterUser: twitterUser, currentTwitterUser: currentTwitterUser)
                        case .delete:
                            // TODO:
                            break
                        }
                    }
            } else {
                self.currentTwitterUserObserver = nil
            }
        }
        .store(in: &disposeBag)
    }
    
    private func update(twitterUser: TwitterUser?) {
        self.userID.value = twitterUser?.id
        self.bannerImageURL.value = twitterUser?.profileBannerURL(sizeKind: .large)
        self.avatarImageURL.value = twitterUser?.avatarImageURL(size: .original)
        self.protected.value = twitterUser?.protected
        self.verified.value = twitterUser?.verified ?? false
        self.name.value = twitterUser?.name
        self.username.value = twitterUser?.username
        self.bioDescription.value = twitterUser?.displayBioDescription
        self.url.value = twitterUser?.displayURL
        self.location.value = twitterUser?.location
        self.friendsCount.value = twitterUser?.metrics?.followingCount.flatMap { Int(truncating: $0) }
        self.followersCount.value = twitterUser?.metrics?.followersCount.flatMap { Int(truncating: $0) }
        self.listedCount.value = twitterUser?.metrics?.listedCount.flatMap{ Int(truncating: $0) }
    }
    
    private func update(twitterUser: TwitterUser?, currentTwitterUser: TwitterUser?) {
        guard let twitterUser = twitterUser,
              let currentTwitterUser = currentTwitterUser else {
            self.friendship.value = nil
            self.followedBy.value = nil
            return
        }
        
        if twitterUser == currentTwitterUser {
            self.friendship.value = nil
            self.followedBy.value = nil
        } else {
            let isFollowing = twitterUser.followingBy.flatMap { $0.contains(currentTwitterUser) } ?? false
            let isPending = twitterUser.followRequestSentFrom.flatMap { $0.contains(currentTwitterUser) } ?? false
            let friendship = isPending ? .pending : (isFollowing) ? .following : ProfileViewModel.Friendship.none
            self.friendship.value = friendship
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: friendship update: %s", ((#file as NSString).lastPathComponent), #line, #function, friendship.debugDescription)
            
            let followedBy = currentTwitterUser.followingBy.flatMap { $0.contains(twitterUser) } ?? false
            self.followedBy.value = followedBy
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: followedBy update: %s", ((#file as NSString).lastPathComponent), #line, #function, followedBy ? "true" : "false")
            
            let muted = twitterUser.mutingBy.flatMap { $0.contains(currentTwitterUser) } ?? false
            self.muted.value = muted
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: muted update: %s", ((#file as NSString).lastPathComponent), #line, #function, muted ? "true" : "false")
            
            let blocked = twitterUser.blockingBy.flatMap { $0.contains(currentTwitterUser) } ?? false
            self.blocked.value = blocked
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: blocked update: %s", ((#file as NSString).lastPathComponent), #line, #function, blocked ? "true" : "false")
        }
    }
    
    private func updateAccountSuspendedState(content: Twitter.API.V2.UserLookup.Content, username: String) {
        guard let twitterAPIError = content.errors?.first.flatMap({ Twitter.API.Error.TwitterAPIError(responseContentError: $0) }) else {
            return
        }
        
        switch twitterAPIError {
        case .userHasBeenSuspended:
            self.suspended.value = true
            self.username.value = username
        default:
            break
        }
    }
    
}
