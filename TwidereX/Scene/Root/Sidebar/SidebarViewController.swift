//
//  SidebarViewController.swift
//  TwidereX
//
//  Created by MainasuK on 2022-4-28.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import UIKit
import SwiftUI
import Combine
import TwidereUI


final class SidebarViewController: UIViewController, NeedsDependency {
    
    let logger = Logger(subsystem: "SidebarViewController", category: "ViewController")
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    //    weak var delegate: SidebarViewControllerDelegate?
    
    var disposeBag = Set<AnyCancellable>()
    var observations = Set<NSKeyValueObservation>()

    var viewModel: SidebarViewModel!
    private(set) lazy var sidebarView = SidebarView(viewModel: viewModel)
    
    let avatarButton = AvatarButton()
    
}

extension SidebarViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        view.backgroundColor = .systemBackground
        
        avatarButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(avatarButton)
        NSLayoutConstraint.activate([
            avatarButton.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor, constant: 16),
            avatarButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            avatarButton.widthAnchor.constraint(equalToConstant: 40).priority(.required - 1),
            avatarButton.heightAnchor.constraint(equalToConstant: 40).priority(.required - 1),
        ])

        let hostingViewController = UIHostingController(rootView: sidebarView)
        hostingViewController.view.preservesSuperviewLayoutMargins = true
        addChild(hostingViewController)
        hostingViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingViewController.view)
        NSLayoutConstraint.activate([
            hostingViewController.view.topAnchor.constraint(equalTo: avatarButton.bottomAnchor, constant: 16),
            hostingViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        viewModel.$avatarURL
            .receive(on: DispatchQueue.main)
            .sink { [weak self] avatarURL in
                guard let self = self else { return }
                self.avatarButton.avatarImageView.configure(configuration: .init(url: avatarURL))
            }
            .store(in: &disposeBag)
        
        avatarButton.addTarget(self, action: #selector(SidebarViewController.avatarButtonDidPressed(_:)), for: .touchUpInside)
    }
    
}

extension SidebarViewController {
    @objc private func avatarButtonDidPressed(_ button: UIButton) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        
        let accountListViewModel = AccountListViewModel(context: context)
        coordinator.present(
            scene: .accountList(viewModel: accountListViewModel),
            from: nil,
            transition: .modal(animated: true, completion: nil)
        )
    }
}
