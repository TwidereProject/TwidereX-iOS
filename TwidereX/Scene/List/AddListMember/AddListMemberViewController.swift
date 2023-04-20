//
//  AddListMemberViewController.swift
//  TwidereX
//
//  Created by MainasuK on 2022-3-22.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import UIKit
import TwidereLocalization

final class AddListMemberViewController: UIViewController, NeedsDependency {
    
    let logger = Logger(subsystem: "AddListMemberViewModelViewController", category: "ViewController")
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var viewModel: AddListMemberViewModel!
    
    private(set) lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = {
            switch viewModel.list {
            case .twitter:      return L10n.Scene.ListsUsers.Add.search
            case .mastodon:     return L10n.Scene.ListsUsers.Add.searchWithinPeopleYouFollow
            }
        }()
        return searchController
    }()
    
    let searchUserViewController = SearchUserViewController()
    
}

extension AddListMemberViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = L10n.Scene.ListsUsers.Add.title
        searchController.delegate = self
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false

        searchUserViewController.context = context
        searchUserViewController.coordinator = coordinator
        searchUserViewController.viewModel = SearchUserViewModel(
            context: context,
            authContext: viewModel.authContext,
            kind: .listMember(list: viewModel.list)
        )
        viewModel.$userIdentifier.assign(to: &searchUserViewController.viewModel.$userIdentifier)
        
        addChild(searchUserViewController)
        searchUserViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchUserViewController.view)
        NSLayoutConstraint.activate([
            searchUserViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            searchUserViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchUserViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            searchUserViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        searchUserViewController.didMove(toParent: self)
        
        searchUserViewController.viewModel.listMembershipViewModel?.delegate = viewModel.listMembershipViewModelDelegate
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // trigger searchController present
        searchController.isActive = true
    }
    
}

// MARK: - UISearchControllerDelegate
extension AddListMemberViewController: UISearchControllerDelegate {
    func didPresentSearchController(_ searchController: UISearchController) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        
        searchController.searchBar.becomeFirstResponder()
    }
}

// MARK: - UISearchResultsUpdating
extension AddListMemberViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): search text: \(searchController.searchBar.text ?? "<nil>")")
        
        let searchText = searchController.searchBar.text ?? ""
        searchUserViewController.viewModel.searchText = searchText
    }
}

// MARK: - UISearchBarDelegate
extension AddListMemberViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        
        dismiss(animated: true, completion: nil)
    }
}
