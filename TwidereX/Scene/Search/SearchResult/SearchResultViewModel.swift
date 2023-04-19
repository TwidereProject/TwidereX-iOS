//
//  SearchResultViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-22.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import Combine
import Pageboy

final class SearchResultViewModel {
    
    var disposeBag = Set<AnyCancellable>()

    // input
    let context: AppContext
    let authContext: AuthContext
    let _coordinator: SceneCoordinator  // only use for `setup`
    var preferredScope: Scope?
    @Published var searchText: String = ""
    @Published var selectedScope: Scope? = nil
    
    // output
    @Published var scopes: [Scope] = []
    @Published var viewControllers: [UIViewController] = []
    @Published var currentPageIndex = 0
    @Published var userIdentifier: UserIdentifier?
    
    init(
        context: AppContext,
        authContext: AuthContext,
        coordinator: SceneCoordinator
    ) {
        self.context = context
        self.authContext = authContext
        self._coordinator = coordinator
        
        self.setup(for: authContext.authenticationContext)
    }
    
}

extension SearchResultViewModel {
    enum Scope: Hashable {
        case status(title: String)
        case media(title: String)
        case user(title: String)
        case hashtag(title: String)
        
        var title: String {
            switch self {
            case .status(let title): return title
            case .media(let title): return title
            case .user(let title): return title
            case .hashtag(let title): return title
            }
        }
    }
}

extension SearchResultViewModel {
    func setup(for authenticationContext: AuthenticationContext?) {
        guard let authenticationContext = authenticationContext else {
            return
        }
        
        let scopes: [Scope]
        let userIdentifier: UserIdentifier
        switch authenticationContext {
        case .twitter(let authenticationContext):
            scopes = [
                .status(title: L10n.Scene.Search.Tabs.tweets),
                .media(title: L10n.Scene.Search.Tabs.media),
                .user(title: L10n.Scene.Search.Tabs.users),
            ]
            userIdentifier = UserIdentifier.twitter(.init(id: authenticationContext.userID))
        case .mastodon(let authenticationContext):
            scopes = [
                .hashtag(title: (L10n.Scene.Search.Tabs.hashtag)),
                .user(title: (L10n.Scene.Search.Tabs.people)),
                .status(title: L10n.Scene.Search.Tabs.toots),
            ]
            userIdentifier = UserIdentifier.mastodon(.init(
                domain: authenticationContext.domain,
                id: authenticationContext.userID
            ))
        }
        let viewControllers = scopes.map { scope in
            createViewController(for: scope)
        }
        
        // trigger data source update first
        self.viewControllers = viewControllers
        self.scopes = scopes
        self.userIdentifier = userIdentifier
    }
    
    private func createViewController(for scope: Scope) -> UIViewController {
        let viewController: UIViewController
        switch scope {
        case .status:
            let _viewController = SearchTimelineViewController()
            let _viewModel = SearchTimelineViewModel(context: context, authContext: authContext)
            _viewController.viewModel = _viewModel
            $searchText.assign(to: &_viewModel.$searchText)
            viewController = _viewController
        
        case .media:
            let _viewController = SearchMediaTimelineViewController()
            let _viewModel = SearchMediaTimelineViewModel(context: context, authContext: authContext)
            _viewController.viewModel = _viewModel
            $searchText.assign(to: &_viewModel.$searchText)
            viewController = _viewController
            
        case .user:
            let _viewController = SearchUserViewController()
            _viewController.viewModel = SearchUserViewModel(context: context, authContext: authContext, kind: .search)
            $searchText.assign(to: &_viewController.viewModel.$searchText)
            $userIdentifier.assign(to: &_viewController.viewModel.$userIdentifier)
            viewController = _viewController
            
        case .hashtag:
            let _viewController = SearchHashtagViewController()
            _viewController.viewModel = SearchHashtagViewModel(context: context, authContext: authContext)
            $searchText.assign(to: &_viewController.viewModel.$searchText)
            viewController = _viewController
        }   // end switch
        
        if let viewController = viewController as? NeedsDependency {
            viewController.context = context
            viewController.coordinator = _coordinator
        }
        
        return viewController
    }
}

// MARK: - PageboyViewControllerDataSource
extension SearchResultViewModel: PageboyViewControllerDataSource {
    
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
