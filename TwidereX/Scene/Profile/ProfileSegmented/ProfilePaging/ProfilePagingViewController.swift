//
//  ProfilePagingViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-24.
//

import UIKit
import Pageboy
import Tabman

final class ProfilePagingViewController: TabmanViewController {
    
    let viewModel = ProfilePagingViewModel()
}

extension ProfilePagingViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource = viewModel
        
//        let testView = UIView()
//        testView.backgroundColor = .systemPink
//        testView.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(testView)
//        NSLayoutConstraint.activate([
//            testView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            view.trailingAnchor.constraint(equalTo: testView.trailingAnchor),
//            view.layoutMarginsGuide.bottomAnchor.constraint(equalTo: testView.bottomAnchor),
//            testView.heightAnchor.constraint(equalToConstant: 100),
//        ])
    }
    
}
