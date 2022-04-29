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
    func sidebarViewModel(_ viewModel: SidebarViewModel, active item: SidebarViewModel.Item)
}

final class SidebarViewModel: ObservableObject {
    
    var disposeBag = Set<AnyCancellable>()
    
    weak var delegate: SidebarViewModelDelegate?
    
    // input
    let context: AppContext
    @Published var activeTab: MainTabBarController.Tab = .home
        
    // output
    let tabs: [Item] = MainTabBarController.Tab.allCases.map { Item.tab($0) }
    @Published var entries: [Item] = []

    init(context: AppContext) {
        self.context = context
        
        context.authenticationService.$activeAuthenticationContext
            .sink { [weak self] authenticationContext in
                guard let self = self else { return }
                var items: [SidebarItem] = []
                switch authenticationContext {
                case .twitter:
                    items.append(contentsOf: [.likes, .lists])
                case .mastodon:
                    items.append(contentsOf: [.local, .federated, .likes, .lists])
                case .none:
                    break
                }
                self.entries = items.map { Item.entry($0) }
            }
            .store(in: &disposeBag)
    }
    
}

extension SidebarViewModel {
    enum Item: Hashable {
        case tab(MainTabBarController.Tab)
        case entry(SidebarItem)
        
        var title: String {
            switch self {
            case .tab(let tab):     return tab.title
            case .entry(let entry): return entry.title
            }
        }
        
        var image: UIImage {
            switch self {
            case .tab(let tab):     return tab.image
            case .entry(let entry): return entry.image
            }
        }
    }
}

extension SidebarViewModel {
    
    func setActive(item: Item) {
        delegate?.sidebarViewModel(self, active: item)
    }
    
}
