//
//  ProfileHeaderViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-24.
//

import os.log
import UIKit
import Combine
import TabBarPager

protocol ProfileHeaderViewControllerDelegate: AnyObject {
    func headerViewController(_ viewController: ProfileHeaderViewController, profileHeaderView: ProfileHeaderView, friendshipButtonDidPressed button: UIButton)
}

final class ProfileHeaderViewController: UIViewController {
    
    static let headerMinHeight: CGFloat = 50
    
    let logger = Logger(subsystem: "ProfileHeaderViewController", category: "ViewController")
    weak var delegate: ProfileHeaderViewControllerDelegate?
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: ProfileHeaderViewModel!
    weak var headerDelegate: TabBarPagerHeaderDelegate?
    
    private(set) lazy var headerView = ProfileHeaderView()

    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension ProfileHeaderViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 8),
        ])
        headerView.preservesSuperviewLayoutMargins = true
        
        viewModel.$user
            .sink { [weak self] user in
                guard let self = self else { return }
                self.headerView.configure(user: user)
            }
            .store(in: &disposeBag)
        
        viewModel.$relationshipOptionSet
            .receive(on: DispatchQueue.main)
            .sink { [weak self] relationshipOptionSet in
                guard let self = self else { return }
                self.headerView.configure(relationshipOptionSet: relationshipOptionSet)
            }
            .store(in: &disposeBag)
        
        headerView.friendshipButton.addTarget(self, action: #selector(ProfileHeaderViewController.friendshipButtonDidPressed(_:)), for: .touchUpInside)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        headerDelegate?.viewLayoutDidUpdate(self)
    }
    
}

extension ProfileHeaderViewController {
    @objc private func friendshipButtonDidPressed(_ sender: UIButton) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        delegate?.headerViewController(self, profileHeaderView: headerView, friendshipButtonDidPressed: sender)
    }
}

// MARK: - TabBarPagerHeader
extension ProfileHeaderViewController: TabBarPagerHeader { }
