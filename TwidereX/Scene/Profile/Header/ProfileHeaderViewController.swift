//
//  ProfileHeaderViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-24.
//

import os.log
import UIKit
import Combine

protocol ProfileHeaderViewControllerDelegate: AnyObject {
    func profileHeaderViewController(_ viewController: ProfileHeaderViewController, viewLayoutDidUpdate view: UIView)
}

final class ProfileHeaderViewController: UIViewController {
    
    static let headerMinHeight: CGFloat = 50
    
    weak var delegate: ProfileHeaderViewControllerDelegate?
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: ProfileHeaderViewModel!
    
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
            view.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: ProfileHeaderViewController.headerMinHeight + 8),
        ])
        headerView.preservesSuperviewLayoutMargins = true
        
        viewModel.$user
            .sink { [weak self] user in
                guard let self = self else { return }
                self.headerView.configure(user: user)
            }
            .store(in: &disposeBag)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        delegate?.profileHeaderViewController(self, viewLayoutDidUpdate: view)
        view.layer.setupShadow(
            color: UIColor.black.withAlphaComponent(0.12),
            alpha: 1,
            x: 0,
            y: 2,
            blur: 2,
            spread: 0,
            roundedRect: view.bounds,
            byRoundingCorners: .allCorners,
            cornerRadii: .zero
        )
    }
    
}
