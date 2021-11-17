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

final class DrawerSidebarViewController: UIViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }

    var disposeBag = Set<AnyCancellable>()
    
    var tableViewDiffableDataSource: UITableViewDiffableDataSource<SidebarSection, SidebarItem>!
    var pinnedTableViewDiffableDataSource: UITableViewDiffableDataSource<SidebarSection, SidebarItem>!

    let headerView = DrawerSidebarHeaderView()    
    
    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(DrawerSidebarEntryTableViewCell.self, forCellReuseIdentifier: String(describing: DrawerSidebarEntryTableViewCell.self))
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        return tableView
    }()
    
    let pinnedTableViewSeparatorLine = UIView.separatorLine
    let pinnedTableView: UITableView = {
        let tableView = UITableView()
        tableView.register(DrawerSidebarEntryTableViewCell.self, forCellReuseIdentifier: String(describing: DrawerSidebarEntryTableViewCell.self))
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        tableView.alwaysBounceVertical = false
        return tableView
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
        
        pinnedTableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pinnedTableView)
        NSLayoutConstraint.activate([
            pinnedTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: pinnedTableView.trailingAnchor),
            view.layoutMarginsGuide.bottomAnchor.constraint(equalTo: pinnedTableView.bottomAnchor),
            pinnedTableView.heightAnchor.constraint(equalToConstant: 56).priority(.defaultHigh),
        ])
        
        pinnedTableViewSeparatorLine.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pinnedTableViewSeparatorLine)
        NSLayoutConstraint.activate([
            pinnedTableViewSeparatorLine.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            view.layoutMarginsGuide.trailingAnchor.constraint(equalTo: pinnedTableViewSeparatorLine.trailingAnchor),
            pinnedTableView.topAnchor.constraint(equalTo: pinnedTableViewSeparatorLine.bottomAnchor),
            pinnedTableViewSeparatorLine.heightAnchor.constraint(equalToConstant: UIView.separatorLineHeight(of: view)).priority(.defaultHigh),
        ])
        
        headerView.delegate = self
        
        tableView.delegate = self
        pinnedTableView.delegate = self
        tableViewDiffableDataSource = setupTableViewDiffableDataSource(tableView: tableView)
        pinnedTableViewDiffableDataSource = setupTableViewDiffableDataSource(tableView: pinnedTableView)
        
        var pinnedTableViewDiffableDataSourceSnapshot = NSDiffableDataSourceSnapshot<SidebarSection, SidebarItem>()
        pinnedTableViewDiffableDataSourceSnapshot.appendSections([.main])
        pinnedTableViewDiffableDataSourceSnapshot.appendItems([.settings], toSection: .main)
        pinnedTableViewDiffableDataSource.apply(pinnedTableViewDiffableDataSourceSnapshot)
        
        context.authenticationService.activeAuthenticationIndex
            .receive(on: DispatchQueue.main)
            .sink { [weak self] activeAuthenticationIndex in
                guard let self = self else { return }
                let twitterUser = activeAuthenticationIndex?.twitterAuthentication?.twitterUser
                // bind avatar
                self.headerView.configure(withConfigurationInput: AvatarConfigurableViewConfiguration.Input(avatarImageURL: twitterUser?.avatarImageURL()))
                self.headerView.lockImageView.isHidden = twitterUser.flatMap { !$0.protected } ?? true
                
                // bind name
                self.headerView.nameButton.setTitle(twitterUser?.name ?? "-", for: .normal)
                self.headerView.usernameButton.setTitle(twitterUser.flatMap { "@" + $0.username } ?? "-", for: .normal) 
                
                // bind status
//                self.headerView.profileBannerStatusView.followingStatusItemView.countLabel.text = twitterUser?.metrics?.followingCount.flatMap { "\($0.intValue)" } ?? "-"
//                self.headerView.profileBannerStatusView.followersStatusItemView.countLabel.text = twitterUser?.metrics?.followersCount.flatMap { "\($0.intValue)" } ?? "-"
//                self.headerView.profileBannerStatusView.listedStatusItemView.countLabel.text = twitterUser?.metrics?.listedCount.flatMap { "\($0.intValue)" } ?? "-"
            }
            .store(in: &disposeBag)
    }
    
}

extension DrawerSidebarViewController {
    
    func setupTableViewDiffableDataSource(tableView: UITableView) -> UITableViewDiffableDataSource<SidebarSection, SidebarItem> {
        return UITableViewDiffableDataSource<SidebarSection, SidebarItem>(tableView: tableView) { tableView, indexPath, item -> UITableViewCell? in
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: DrawerSidebarEntryTableViewCell.self), for: indexPath) as! DrawerSidebarEntryTableViewCell
            cell.entryView.iconImageView.image = item.image
            cell.entryView.iconImageView.tintColor = UIColor.label.withAlphaComponent(0.8)
            cell.entryView.titleLabel.text = item.title
            cell.entryView.titleLabel.textColor = UIColor.label.withAlphaComponent(0.8)
            return cell
        }
    }
}

// MARK: - DrawerSidebarHeaderViewDelegate
extension DrawerSidebarViewController: DrawerSidebarHeaderViewDelegate {
    
    private func presentMeProfile() {
        let profileViewModel = MeProfileViewModel(context: self.context)
        coordinator.present(scene: .profile(viewModel: profileViewModel), from: presentingViewController, transition: .show)
        dismiss(animated: true)
    }
    
    func drawerSidebarHeaderView(_ headerView: DrawerSidebarHeaderView, avatarButtonDidPressed button: UIButton) {
        presentMeProfile()
    }
    
    func drawerSidebarHeaderView(_ headerView: DrawerSidebarHeaderView, nameButtonDidPressed button: UIButton) {
        presentMeProfile()
    }
    
    func drawerSidebarHeaderView(_ headerView: DrawerSidebarHeaderView, usernameButtonDidPressed button: UIButton) {
        presentMeProfile()
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
    
    func drawerSidebarHeaderView(_ headerView: DrawerSidebarHeaderView, profileBannerStatusView: ProfileBannerStatusView, followingStatusItemViewDidPressed statusItemView: ProfileBannerStatusItemView) {
        guard let followingListViewModel = FriendshipListViewModel(context: context, friendshipLookupKind: .following) else { return }
        coordinator.present(scene: .friendshipList(viewModel: followingListViewModel), from: presentingViewController, transition: .show)
        dismiss(animated: true)
    }
    
    func drawerSidebarHeaderView(_ headerView: DrawerSidebarHeaderView, profileBannerStatusView: ProfileBannerStatusView, followerStatusItemViewDidPressed statusItemView: ProfileBannerStatusItemView) {
        guard let followingListViewModel = FriendshipListViewModel(context: context, friendshipLookupKind: .followers) else { return }
        coordinator.present(scene: .friendshipList(viewModel: followingListViewModel), from: presentingViewController, transition: .show)
        dismiss(animated: true)
    }
    
    func drawerSidebarHeaderView(_ headerView: DrawerSidebarHeaderView, profileBannerStatusView: ProfileBannerStatusView, listedStatusItemViewDidPressed statusItemView: ProfileBannerStatusItemView) {
        
    }
        
}

// MARK: - UITableViewDelegate
extension DrawerSidebarViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView === self.tableView {
            
        }
        
        if tableView === pinnedTableView {
            dismiss(animated: true) {
                self.coordinator.present(scene: .setting, from: nil, transition: .modal(animated: true, completion: nil))
            }
        }
    }
    
}
