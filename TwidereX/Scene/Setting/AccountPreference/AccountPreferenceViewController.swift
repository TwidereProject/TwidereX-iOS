//
//  AccountPreferenceViewController.swift
//  TwidereX
//
//  Created by MainasuK on 2022-7-12.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import UIKit
import SwiftUI
import Combine
import TwidereCore

final class AccountPreferenceViewController: UIViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    
    var viewModel: AccountPreferenceViewModel!
    private(set) lazy var accountPreferenceView = AccountPreferenceView(viewModel: viewModel)
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension AccountPreferenceViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let hostingController = UIHostingController(rootView: accountPreferenceView)
        addChild(hostingController)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingController.view)
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        hostingController.didMove(toParent: self)
        
        viewModel.listEntryPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] entry in
                guard let self = self else { return }
                switch entry {
                case .muted:
                    break
                case .blocked:
                    break
                case .accountSettings:
                    break
                case .signout:
                    Task {
                        try await DataSourceFacade.responseToUserSignOut(
                            dependency: self,
                            user: self.viewModel.user.asRecord
                        )
                    }   // end Task
                }
            }
            .store(in: &disposeBag)
    }
    
}
