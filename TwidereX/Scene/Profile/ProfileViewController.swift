//
//  ProfileViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-24.
//

import UIKit
import Combine

final class ProfileViewController: UIViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    //var viewModel: TweetPostViewModel!
    
    
    lazy var profileSegmentedViewController = ProfileSegmentedViewController()
    lazy var profileHeaderViewController = ProfileHeaderViewController()
    
}

extension ProfileViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Me"
        view.backgroundColor = .systemBackground
        
        addChild(profileSegmentedViewController)
        profileSegmentedViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(profileSegmentedViewController.view)
        profileSegmentedViewController.didMove(toParent: self)
        NSLayoutConstraint.activate([
            profileSegmentedViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            profileSegmentedViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            profileSegmentedViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            profileSegmentedViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        addChild(profileHeaderViewController)
        profileHeaderViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(profileHeaderViewController.view)
        profileHeaderViewController.didMove(toParent: self)
        NSLayoutConstraint.activate([
            profileHeaderViewController.view.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            profileHeaderViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: profileHeaderViewController.view.trailingAnchor),
            profileHeaderViewController.view.heightAnchor.constraint(equalToConstant: 300),
        ])
        
        profileHeaderViewController.view.backgroundColor = UIColor.green.withAlphaComponent(0.5)
        
//        profileSegmentedViewController.view.backgroundColor = .red
        //profileHeaderViewController.view.backgroundColor = .green
        
//        tableView.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(tableView)
//        tableView.backgroundColor = .systemBackground
//        NSLayoutConstraint.activate([
//            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//            tableView.topAnchor.constraint(equalTo: view.topAnchor)
//        ])
        
//        viewModel.setupDiffableDataSource(for: tableView)
//        tableView.delegate = self
//        tableView.dataSource = viewModel.diffableDataSource
//        tableView.reloadData()
    }
    
}

// MARK: - UITableViewDelegate
extension ProfileViewController: UITableViewDelegate {
    
//    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
//        return 200
//    }
}
