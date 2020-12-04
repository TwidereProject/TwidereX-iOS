//
//  ProfileHeaderViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-24.
//

import os.log
import UIKit

protocol ProfileHeaderViewControllerDelegate: class {
    func profileHeaderViewController(_ viewController: ProfileHeaderViewController, viewLayoutDidUpdate view: UIView)
}

final class ProfileHeaderViewController: UIViewController {
    
    static let headerMinHeight: CGFloat = 50
    
    weak var delegate: ProfileHeaderViewControllerDelegate?
    
    let profileBannerView = ProfileBannerView()

    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension ProfileHeaderViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        profileBannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(profileBannerView)
        NSLayoutConstraint.activate([
            profileBannerView.topAnchor.constraint(equalTo: view.topAnchor),
            profileBannerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            profileBannerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: profileBannerView.bottomAnchor, constant: ProfileHeaderViewController.headerMinHeight + 8),
        ])
        profileBannerView.preservesSuperviewLayoutMargins = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        delegate?.profileHeaderViewController(self, viewLayoutDidUpdate: view)
        view.layer.setupShadow(color: UIColor.black.withAlphaComponent(0.12), alpha: 1, x: 0, y: 2, blur: 2, spread: 0, roundedRect: view.bounds, byRoundingCorners: .allCorners, cornerRadii: .zero)
    }
    
}
