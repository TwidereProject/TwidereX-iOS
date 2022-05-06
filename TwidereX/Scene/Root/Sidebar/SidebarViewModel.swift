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

protocol SidebarViewModelDelegate: AnyObject {
    func sidebarViewModel(_ viewModel: SidebarViewModel, active item: TabBarItem)
}

final class SidebarViewModel: ObservableObject {
    
    var disposeBag = Set<AnyCancellable>()
    var avatarURLSubscription: AnyCancellable?
    
    weak var delegate: SidebarViewModelDelegate?
    
    // input
    let context: AppContext
    @Published var activeTab: TabBarItem?
        
    // output
    @Published var mainTabBarItems: [TabBarItem] = []
    @Published var secondaryTabBarItems: [TabBarItem] = []
    @Published var avatarURL: URL?

    init(context: AppContext) {
        self.context = context
        
        context.authenticationService.$activeAuthenticationContext
            .sink { [weak self] authenticationContext in
                guard let self = self else { return }
                
                var items: [TabBarItem] = []
                switch authenticationContext {
                case .twitter:
                    items.append(contentsOf: [.likes, .lists])
                case .mastodon:
                    items.append(contentsOf: [.local, .federated, .likes, .lists])
                case .none:
                    break
                }
                self.secondaryTabBarItems = items
                
                let user = authenticationContext?.user(in: context.managedObjectContext)
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
            }
            .store(in: &disposeBag)
    }
    
}

extension SidebarViewModel {
    
    func setActiveTab(item: TabBarItem) {
        delegate?.sidebarViewModel(self, active: item)
    }
    
}
