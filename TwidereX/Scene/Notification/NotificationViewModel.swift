//
//  NotificationViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-11-10.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import Combine
import Pageboy

final class NotificationViewModel {
    
    var disposeBag = Set<AnyCancellable>()

    // input
    let context: AppContext
    let _coordinator: SceneCoordinator  // only use for `setup`
    @Published var selectedScope: Scope? = nil
    let viewDidAppear = CurrentValueSubject<Void, Never>(Void())
    
    // output
    @Published var scopes: [Scope] = []
    @Published var viewControllers: [UIViewController] = []
    @Published var currentPageIndex = 0
    @Published var userIdentifier: UserIdentifier?
    
    init(context: AppContext, coordinator: SceneCoordinator) {
        self.context = context
        self._coordinator = coordinator
        // end init
        
        context.authenticationService.activeAuthenticationContext
            .receive(on: DispatchQueue.main)
            .sink { [weak self] authenticationContext in
                guard let self = self else { return }
                self.setup(for: authenticationContext)
            }
            .store(in: &disposeBag)
    }
    
}

extension NotificationViewModel {
    enum Scope: Hashable {
        case all(title: String)
        case mentions(title: String)
        
        var title: String {
            switch self {
            case .all(let title): return title
            case .mentions(let title): return title
            }
        }
    }
}

extension NotificationViewModel {
    func setup(for authenticationContext: AuthenticationContext?) {
        guard let authenticationContext = authenticationContext else {
            return
        }
        
        let scopes: [Scope]
        let userIdentifier: UserIdentifier
        switch authenticationContext {
        case .twitter(let authenticationContext):
            scopes = [
                .mentions(title: "Mentions"),
            ]
            userIdentifier = UserIdentifier.twitter(.init(
                id: authenticationContext.userID
            ))
        case .mastodon(let authenticationContext):
            scopes = [
                .all(title: L10n.Scene.Notification.Tabs.all),
                .mentions(title: "Mentions"),   // FIXME:
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
        case .all:
            let _viewController = NotificationTimelineViewController()
            _viewController.context = context
            _viewController.coordinator = _coordinator
            _viewController.viewModel = NotificationTimelineViewModel(
                context: context,
                scope: .all
            )
            viewController = _viewController
        case .mentions:
            let _viewController = NotificationTimelineViewController()
            _viewController.context = context
            _viewController.coordinator = _coordinator
            _viewController.viewModel = NotificationTimelineViewModel(
                context: context,
                scope: .mentions
            )
            viewController = _viewController
        }
        return viewController
    }
}


// MARK: - PageboyViewControllerDataSource
extension NotificationViewModel: PageboyViewControllerDataSource {
    
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
