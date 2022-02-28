//
//  DrawerSidebarViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-9.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import AlamofireImage
import TwidereUI

final class DrawerSidebarViewController: UIViewController, NeedsDependency {
    
    static let settingTableViewHeight: CGFloat = 56
    
    let logger = Logger(subsystem: "DrawerSidebarViewController", category: "ViewController")
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }

    var disposeBag = Set<AnyCancellable>()
    var viewModel: DrawerSidebarViewModel!

    let headerView = DrawerSidebarHeaderView()    
    
    let sidebarCollectionView: UICollectionView = {
        var configuration = UICollectionLayoutListConfiguration(appearance: .sidebar)
        configuration.backgroundColor = .clear
        let layout = UICollectionViewCompositionalLayout.list(using: configuration)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        return collectionView
    }()
    
    let settingCollectionViewSeparatorLine = SeparatorLineView()
    
    let settingCollectionView: UICollectionView = {
        var configuration = UICollectionLayoutListConfiguration(appearance: .sidebar)
        configuration.backgroundColor = .clear
        let layout = UICollectionViewCompositionalLayout.list(using: configuration)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.isScrollEnabled = false
        return collectionView
    }()
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s:", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension DrawerSidebarViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor, constant: 4),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        
        sidebarCollectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sidebarCollectionView)
        NSLayoutConstraint.activate([
            sidebarCollectionView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            sidebarCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sidebarCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sidebarCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        sidebarCollectionView.contentInset.bottom = DrawerSidebarViewController.settingTableViewHeight
        
        settingCollectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(settingCollectionView)
        NSLayoutConstraint.activate([
            settingCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: settingCollectionView.trailingAnchor),
            view.layoutMarginsGuide.bottomAnchor.constraint(equalTo: settingCollectionView.bottomAnchor),
            settingCollectionView.heightAnchor.constraint(greaterThanOrEqualToConstant: DrawerSidebarViewController.settingTableViewHeight).priority(.required - 1),
        ])

        settingCollectionViewSeparatorLine.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(settingCollectionViewSeparatorLine)
        NSLayoutConstraint.activate([
            settingCollectionViewSeparatorLine.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: settingCollectionViewSeparatorLine.trailingAnchor),
            settingCollectionView.topAnchor.constraint(equalTo: settingCollectionViewSeparatorLine.bottomAnchor),
            settingCollectionViewSeparatorLine.heightAnchor.constraint(equalToConstant: UIView.separatorLineHeight(of: view)).priority(.defaultHigh),
        ])

        // sidebarTableView.delegate = self
        sidebarCollectionView.delegate = self
        settingCollectionView.delegate = self
        viewModel.setupDiffableDataSource(
            sidebarCollectionView: sidebarCollectionView,
            settingCollectionView: settingCollectionView
        )
        
        context.authenticationService.$activeAuthenticationContext
            .sink { [weak self] authenticationContext in
                guard let self = self else { return }
                let user = authenticationContext?.user(in: self.context.managedObjectContext)
                self.headerView.configure(user: user)
            }
            .store(in: &disposeBag)
        
        headerView.delegate = self
    }
    
}


// MARK: - DrawerSidebarHeaderViewDelegate
extension DrawerSidebarViewController: DrawerSidebarHeaderViewDelegate {

    func drawerSidebarHeaderView(_ headerView: DrawerSidebarHeaderView, avatarButtonDidPressed button: UIButton) {
        let profileViewModel = MeProfileViewModel(context: self.context)
        
        // present from `presentingViewController` here to reduce transition delay
        coordinator.present(scene: .profile(viewModel: profileViewModel), from: presentingViewController, transition: .show)
        dismiss(animated: true)
    }

    func drawerSidebarHeaderView(_ headerView: DrawerSidebarHeaderView, menuButtonDidPressed button: UIButton) {
        dismiss(animated: true) {
            let accountListViewModel = AccountListViewModel(context: self.context)
            self.coordinator.present(scene: .accountList(viewModel: accountListViewModel), from: nil, transition: .modal(animated: true, completion: nil))
        }
    }

    func drawerSidebarHeaderView(_ headerView: DrawerSidebarHeaderView, closeButtonDidPressed button: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    func drawerSidebarHeaderView(_ headerView: DrawerSidebarHeaderView, profileDashboardView: ProfileDashboardView, followingMeterViewDidPressed meterView: ProfileDashboardMeterView) {
        guard let friendshipListViewModel = FriendshipListViewModel(context: context, kind: .following) else {
            assertionFailure()
            return
        }
        coordinator.present(scene: .friendshipList(viewModel: friendshipListViewModel), from: presentingViewController, transition: .show)
        dismiss(animated: true, completion: nil)
    }
    
    func drawerSidebarHeaderView(_ headerView: DrawerSidebarHeaderView, profileDashboardView: ProfileDashboardView, followersMeterViewDidPressed meterView: ProfileDashboardMeterView) {
        guard let friendshipListViewModel = FriendshipListViewModel(context: context, kind: .follower) else {
            assertionFailure()
            return
        }
        coordinator.present(scene: .friendshipList(viewModel: friendshipListViewModel), from: presentingViewController, transition: .show)
        dismiss(animated: true, completion: nil)
    }
    
    func drawerSidebarHeaderView(_ headerView: DrawerSidebarHeaderView, profileDashboardView: ProfileDashboardView, listedMeterViewDidPressed meterView: ProfileDashboardMeterView) {
        // TODO:
    }

}

// MARK: - UICollectionViewDelegate
extension DrawerSidebarViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch collectionView {
        case sidebarCollectionView:
            guard let diffableDataSource = viewModel.sidebarDiffableDataSource else { return }
            guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
            switch item {
            case .local:
                let federatedTimelineViewModel = FederatedTimelineViewModel(context: context, local: true)
                coordinator.present(scene: .federatedTimeline(viewModel: federatedTimelineViewModel), from: self, transition: .show)
            case .federated:
                let federatedTimelineViewModel = FederatedTimelineViewModel(context: context, local: false)
                coordinator.present(scene: .federatedTimeline(viewModel: federatedTimelineViewModel), from: self, transition: .show)
            default:
                assertionFailure("TODO")
            }
            dismiss(animated: true, completion: nil)
        case settingCollectionView:
            guard let diffableDataSource = viewModel.settingDiffableDataSource else { return }
            guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
            guard case .settings = item else { return }
            dismiss(animated: true) {
                self.coordinator.present(scene: .setting, from: nil, transition: .modal(animated: true, completion: nil))
            }
        default:
            assertionFailure()
            break
        }
    }
}
