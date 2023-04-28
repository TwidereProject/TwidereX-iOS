//
//  SidebarViewModel.swift
//  TwidereX
//
//  Created by MainasuK on 2022-4-28.
//  Copyright © 2022 Twidere. All rights reserved.
//

import UIKit
import Combine
import CoreData
import CoreDataStack
import TwidereCore
import TwidereAsset

protocol SidebarViewModelDelegate: AnyObject {
    func sidebarViewModel(_ viewModel: SidebarViewModel, didTapItem item: TabBarItem)
    func sidebarViewModel(_ viewModel: SidebarViewModel, didDoubleTapItem item: TabBarItem)
}

final class SidebarViewModel: ObservableObject {
    
    var disposeBag = Set<AnyCancellable>()
    var avatarURLSubscription: AnyCancellable?
    
    weak var delegate: SidebarViewModelDelegate?
    
    // input
    let context: AppContext
    let authContext: AuthContext
    @Published var activeTab: TabBarItem?
        
    // output
    @Published var mainTabBarItems: [TabBarItem] = []
    @Published var secondaryTabBarItems: [TabBarItem] = []
    @Published var avatarURL: URL?
    
    @Published var hasUnreadPushNotification = false

    init(
        context: AppContext,
        authContext: AuthContext
    ) {
        self.context = context
        self.authContext = authContext
        // end init
        
        UserDefaults.shared.publisher(for: \.preferredEnableHistory)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] preferredEnableHistory in
                guard let self = self else { return }

                var items: [TabBarItem] = []
                switch self.authContext.authenticationContext {
                case .twitter:
                    // items.append(contentsOf: [.likes])
                    if preferredEnableHistory {
                        items.append(contentsOf: [.history])
                    }
                    items.append(contentsOf: [.lists])
                case .mastodon:
                    items.append(contentsOf: [.local, .federated, .likes])
                    if preferredEnableHistory {
                        items.append(contentsOf: [.history])
                    }
                    items.append(contentsOf: [.lists])
                }
                self.secondaryTabBarItems = items
            }
            .store(in: &disposeBag)
        
        let user = authContext.authenticationContext.user(in: context.managedObjectContext)
        switch user {
        case .twitter(let object):
            self.avatarURLSubscription = object.publisher(for: \.profileImageURL)
                .sink { [weak self] _ in
                    guard let self = self else { return }
                    self.avatarURL = object.avatarImageURL()
                }
        case .mastodon(let object):
            self.avatarURLSubscription = object.publisher(for: \.avatar)
                .sink { [weak self] _ in
                    guard let self = self else { return }
                    self.avatarURL = object.avatar.flatMap { URL(string: $0) }
                }
        case .none:
            self.avatarURL = nil
        }
        
        Task {
            await setupNotificationTabIconUpdater()
        }   // end Task
    }
    
}

extension SidebarViewModel {
    
    func tap(item: TabBarItem) {
        delegate?.sidebarViewModel(self, didTapItem: item)
    }
    
    func doubleTap(item: TabBarItem) {
        delegate?.sidebarViewModel(self, didDoubleTapItem: item)
    }
    
}

extension SidebarViewModel {
    
    @MainActor
    private func setupNotificationTabIconUpdater() async {
        // notification tab bar icon updater
        await Publishers.CombineLatest(
            context.notificationService.unreadNotificationCountDidUpdate,   // <-- actor property
            $activeTab
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _, activeTab in
            guard let self = self else { return }
            let authenticationContext = self.authContext.authenticationContext
            let hasUnreadPushNotification: Bool = {
                switch authenticationContext {
                case .twitter:
                    return false
                case .mastodon(let authenticationContext):
                    let accessToken = authenticationContext.authorization.accessToken
                    let count = UserDefaults.shared.getNotificationCountWithAccessToken(accessToken: accessToken)
                    return count > 0
                }
            }()
            self.hasUnreadPushNotification = hasUnreadPushNotification
        }
        .store(in: &disposeBag)
    }
    
}
