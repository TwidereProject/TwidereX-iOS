//
//  SettingListViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-10.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import SwiftUI
import Combine

final class SettingListViewController: UIViewController, NeedsDependency {
        
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }

    var disposeBag = Set<AnyCancellable>()
    let settingListView = SettingListView()
    
}

extension SettingListViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = L10n.Scene.Settings.title
        navigationItem.leftBarButtonItem = .closeBarButtonItem(target: self, action: #selector(SettingListViewController.closeBarButtonItemPressed(_:)))
        navigationItem.leftBarButtonItem?.tintColor = .label
        
        let hostingViewController = UIHostingController(rootView: settingListView.environmentObject(context))
        addChild(hostingViewController)
        hostingViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingViewController.view)
        NSLayoutConstraint.activate([
            hostingViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        context.viewStateStore.settingView.presentSettingListEntryPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] entry in
                guard let self = self else { return }                
                switch entry.type {
                case .appearance:
                    break
                case .display:
                    self.coordinator.present(scene: .displayPreference, from: self, transition: .show)
                case .layout:
                    break
                case .webBrowser:
                    break
                case .about:
                    self.coordinator.present(scene: .about, from: self, transition: .show)
                #if DEBUG
                case .developer:
                    self.coordinator.present(scene: .developer, from: self, transition: .show)
                #endif
                }
            }
            .store(in: &disposeBag)
    }
    
}

extension SettingListViewController {

    @objc private func closeBarButtonItemPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
}
