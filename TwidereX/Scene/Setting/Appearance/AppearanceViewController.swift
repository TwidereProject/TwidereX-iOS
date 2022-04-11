//
//  AppearanceViewController.swift
//  TwidereX
//
//  Created by MainasuK on 2022-4-1.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import SwiftUI
import TwidereLocalization

final class AppearanceViewController: UIViewController, NeedsDependency {
    
    let logger = Logger(subsystem: "AppearanceViewController", category: "ViewController")
        
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }

    var disposeBag = Set<AnyCancellable>()
    private(set) lazy var viewModel = AppearanceViewModel(context: context)
    
    // weak var delegate: EditListViewControllerDelegate?
    
    private(set) lazy var appearanceView = AppearanceView(viewModel: viewModel)

    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension AppearanceViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = L10n.Scene.Settings.Appearance.title
        
        let hostingViewController = UIHostingController(rootView: appearanceView)
        addChild(hostingViewController)
        hostingViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingViewController.view)
        NSLayoutConstraint.activate([
            hostingViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
    
}
