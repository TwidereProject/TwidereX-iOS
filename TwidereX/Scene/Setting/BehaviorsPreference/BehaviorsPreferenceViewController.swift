//
//  BehaviorsPreferenceViewController.swift
//  TwidereX
//
//  Created by MainasuK on 2022-7-27.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import SwiftUI
import TwidereLocalization

final class BehaviorsPreferenceViewController: UIViewController, NeedsDependency {
    
    let logger = Logger(subsystem: "BehaviorsPreferenceViewController", category: "ViewController")
        
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }

    var disposeBag = Set<AnyCancellable>()
    var viewModel: BehaviorsPreferenceViewModel!
    private(set) lazy var behaviorsPreferenceView = BehaviorsPreferenceView(viewModel: viewModel)

    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }

}

extension BehaviorsPreferenceViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Behaviors"     // TODO: i18n
        
        let hostingViewController = UIHostingController(rootView: behaviorsPreferenceView)
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
