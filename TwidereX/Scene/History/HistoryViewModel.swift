//
//  HistoryViewModel.swift
//  TwidereX
//
//  Created by MainasuK on 2022-7-29.
//  Copyright © 2022 Twidere. All rights reserved.
//

import UIKit
import Combine
import Pageboy
import TwidereCore
import CoreDataStack

final class HistoryViewModel {

    var disposeBag = Set<AnyCancellable>()

    // input
    let context: AppContext
    let _coordinator: SceneCoordinator  // only use for `setup`
    let authContext: AuthContext
    
    // output
    let platform: Platform
    let scopes = Scope.allCases
    let viewControllers: [UIViewController]
    @Published var currentPageIndex = 0
    
    init(
        context: AppContext,
        coordinator: SceneCoordinator,
        authContext: AuthContext
    ) {
        self.context = context
        self._coordinator = coordinator
        self.authContext = authContext
        self.platform = {
            switch authContext.authenticationContext {
            case .twitter:      return .twitter
            case .mastodon:     return .mastodon
            }
        }()
        self.viewControllers = {
            // status
            let statusHistoryViewController = StatusHistoryViewController()
            statusHistoryViewController.context = context
            statusHistoryViewController.coordinator = coordinator
            statusHistoryViewController.viewModel = StatusHistoryViewModel(context: context, authContext: authContext)
            // user
            let userHistoryViewController = UserHistoryViewController()
            userHistoryViewController.context = context
            userHistoryViewController.coordinator = coordinator
            userHistoryViewController.viewModel = UserHistoryViewModel(context: context, authContext: authContext)
            return [statusHistoryViewController, userHistoryViewController]
        }()
        // end init
    }
    
}

extension HistoryViewModel {
    enum Scope: Hashable, CaseIterable {
        case status
        case user
        
        func title(platform: Platform) -> String {
            switch self {
            case .status:
                switch platform {
                case .twitter:      return "Tweet"
                case .mastodon:     return "Toot"
                case .none:
                    assertionFailure()
                    return "Post"
                }
            case .user:
                return "User"       // TODO: i18n
            }
        }
    }
}

// MARK: - PageboyViewControllerDataSource
extension HistoryViewModel: PageboyViewControllerDataSource {

    func numberOfViewControllers(in pageboyViewController: PageboyViewController) -> Int {
        return viewControllers.count
    }
    
    func viewController(for pageboyViewController: PageboyViewController, at index: PageboyViewController.PageIndex) -> UIViewController? {
        return viewControllers[index]
    }
    
    func defaultPage(for pageboyViewController: PageboyViewController) -> PageboyViewController.Page? {
        return .first
    }

}
