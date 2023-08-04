//
//  NewColumnViewController.swift
//  TwidereX
//
//  Created by MainasuK on 2023/5/22.
//  Copyright © 2023 Twidere. All rights reserved.
//

import UIKit
import SwiftUI
import TwidereLocalization

final class NewColumnViewController: UIViewController {
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    let authContext: AuthContext
    
    public private(set) lazy var viewModel = NewColumnViewModel(context: context, auth: authContext)
    private lazy var contentView = NewColumnView(viewModel: viewModel)
    
    init(
        context: AppContext,
        coordinator: SceneCoordinator,
        authContext: AuthContext
    ) {
        self.context = context
        self.coordinator = coordinator
        self.authContext = authContext
        super.init(nibName: nil, bundle: nil)
        // end init
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension NewColumnViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = L10n.Scene.Column.title

        let hostingViewController = UIHostingController(rootView: contentView)
        hostingViewController.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(hostingViewController)
        view.addSubview(hostingViewController.view)
        hostingViewController.didMove(toParent: self)
        NSLayoutConstraint.activate([
            hostingViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
}
