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
import TwidereCore

final class SettingListViewController: UIViewController, NeedsDependency {
        
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }

    var disposeBag = Set<AnyCancellable>()
    var viewModel: SettingListViewModel!
    
}

extension SettingListViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = L10n.Scene.Settings.title
        navigationItem.leftBarButtonItem = .closeBarButtonItem(target: self, action: #selector(SettingListViewController.closeBarButtonItemPressed(_:)))
        navigationItem.leftBarButtonItem?.tintColor = .label
        
        let hostingViewController = UIHostingController(
            rootView: SettingListView(viewModel: viewModel).environmentObject(context)
        )
        addChild(hostingViewController)
        hostingViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingViewController.view)
        NSLayoutConstraint.activate([
            hostingViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        viewModel.settingListEntryPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] entry in
                guard let self = self else { return }                
                switch entry.type {
                case .account:
                    guard let user = self.viewModel.user else { return }

                    let accountPreferenceViewModel = AccountPreferenceViewModel(
                        context: self.context,
                        authContext: self.viewModel.authContext,
                        user: user
                    )
                    self.coordinator.present(
                        scene: .accountPreference(viewModel: accountPreferenceViewModel),
                        from: self,
                        transition: .show
                    )
                case .behaviors:
                    let behaviorsPreferenceViewModel = BehaviorsPreferenceViewModel(context: self.context)
                    self.coordinator.present(
                        scene: .behaviorsPreference(viewModel: behaviorsPreferenceViewModel),
                        from: self,
                        transition: .show
                    )
                case .display:
                    let displayPreferenceViewModel = DisplayPreferenceViewModel(authContext: self.viewModel.authContext)
                    self.coordinator.present(scene: .displayPreference(viewModel: displayPreferenceViewModel), from: self, transition: .show)
                case .layout:
                    break
                case .webBrowser:
                    break
                case .appIcon:
                    break
                case .about:
                    let aboutViewModel = AboutViewModel(authContext: self.viewModel.authContext)
                    self.coordinator.present(scene: .about(viewModel: aboutViewModel), from: self, transition: .show)
                #if DEBUG
                case .developer:
                    let developerViewModel = DeveloperViewModel(authContext: self.viewModel.authContext)
                    self.coordinator.present(scene: .developer(viewModel: developerViewModel), from: self, transition: .show)
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

// MARK: - UIAdaptivePresentationControllerDelegate
extension SettingListViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        switch traitCollection.userInterfaceIdiom {
        case .pad:
            return .formSheet
        default:
            return .formSheet
        }
    }
}
