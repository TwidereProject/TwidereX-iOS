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
import TwidereCore

final class NotificationViewModel {
    
    var disposeBag = Set<AnyCancellable>()

    // input
    let context: AppContext
    let authContext: AuthContext
    let _coordinator: SceneCoordinator  // only use for `setup`
    @Published var selectedScope: NotificationTimelineViewModel.Scope? = nil
    
    let viewDidAppear = CurrentValueSubject<Void, Never>(Void())
    
    // output
    @Published var scopes: [NotificationTimelineViewModel.Scope] = []
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
        // end init
        
        context.authenticationService.$activeAuthenticationContext
            .receive(on: DispatchQueue.main)
            .sink { [weak self] authenticationContext in
                guard let self = self else { return }
                self.setup(for: authenticationContext)
            }
            .store(in: &disposeBag)
    }
    
}

extension NotificationViewModel {
    func setup(for authenticationContext: AuthenticationContext?) {
        guard let authenticationContext = authenticationContext else {
            return
        }
        
        let scopes: [NotificationTimelineViewModel.Scope]
        let userIdentifier: UserIdentifier
        switch authenticationContext {
        case .twitter(let authenticationContext):
            scopes = [.twitter]
            userIdentifier = UserIdentifier.twitter(.init(
                id: authenticationContext.userID
            ))
        case .mastodon(let authenticationContext):
            scopes = [
                .mastodon(.all),
                .mastodon(.mentions),
            ]
            userIdentifier = UserIdentifier.mastodon(.init(
                domain: authenticationContext.domain,
                id: authenticationContext.userID
            ))
        }
        let viewControllers = scopes.map { scope in
            createViewController(
                scope: scope
            )
        }
        
        // trigger data source update first
        self.viewControllers = viewControllers
        self.scopes = scopes
        self.userIdentifier = userIdentifier
    }
    
    private func createViewController(
        scope: NotificationTimelineViewModel.Scope
    ) -> UIViewController {
        let viewController = NotificationTimelineViewController()
        viewController.context = context
        viewController.coordinator = _coordinator
        viewController.viewModel = NotificationTimelineViewModel(
            context: context,
            authContext: authContext,
            scope: scope
        )
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
