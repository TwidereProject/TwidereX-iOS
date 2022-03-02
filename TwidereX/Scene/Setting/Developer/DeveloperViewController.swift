//
//  DeveloperViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-7.
//  Copyright © 2020 Twidere. All rights reserved.
//

#if DEBUG

import os
import UIKit
import SwiftUI
import Combine

final class DeveloperViewController: UIViewController, NeedsDependency {
    
    var disposeBag = Set<AnyCancellable>()
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    let viewModel = DeveloperViewModel()
    private(set) lazy var developerView = DeveloperView(viewModel: viewModel)
    
}

extension DeveloperViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Developer"
        
        let hostingViewController = UIHostingController(rootView: developerView.environmentObject(context))
        addChild(hostingViewController)
        hostingViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingViewController.view)
        NSLayoutConstraint.activate([
            hostingViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        if case let .twitter(authenticationContext) = context.authenticationService.activeAuthenticationContext {
            Task { @MainActor in
                viewModel.fetching = true
                defer { viewModel.fetching = false }
                let response = try await self.context.apiService.rateLimitStatus(authorization: authenticationContext.authorization)
                viewModel.rateLimitStatusResources.value = response.value.resources
            }   // end Task
        }
    }
    
}

#endif
