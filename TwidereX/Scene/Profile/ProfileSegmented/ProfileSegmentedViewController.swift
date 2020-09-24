//
//  ProfileSegmentedViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-24.
//

import UIKit

final class ProfileSegmentedViewController: UIViewController {
    let pagingViewController = ProfilePagingViewController()
}

extension ProfileSegmentedViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pagingViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pagingViewController.view)
        pagingViewController.didMove(toParent: self)
        NSLayoutConstraint.activate([
            pagingViewController.view.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            pagingViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: pagingViewController.view.trailingAnchor),
            view.layoutMarginsGuide.bottomAnchor.constraint(equalTo: pagingViewController.view.bottomAnchor),
        ])
    }
    
}
