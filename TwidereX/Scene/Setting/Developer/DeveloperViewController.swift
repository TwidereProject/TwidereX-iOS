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
        
        if let authenticationBox = context.authenticationService.activeTwitterAuthenticationBox.value {
            viewModel.fetching = true
            context.apiService.rateLimitStatus(authorization: authenticationBox.twitterAuthorization)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] completion in
                    guard let self = self else { return }
                    self.viewModel.fetching = false
                    
                    switch completion {
                    case .failure(let error):
                        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: fetch rate limit status fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                    case .finished:
                        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: fetch rate limit status success", ((#file as NSString).lastPathComponent), #line, #function)
                        break
                    }
                } receiveValue: { [weak self] response in
                    guard let self = self else { return }
                    self.viewModel.rateLimitStatusResources.value = response.value.resources
                }
                .store(in: &disposeBag)
        }
        
    }
    
}

#endif
