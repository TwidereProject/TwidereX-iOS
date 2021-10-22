//
//  SearchViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-28.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
//import AlamofireImage

//final class HeightFixedSearchBar: UISearchBar {
//    override var intrinsicContentSize: CGSize {
//        return CGSize(width: CGFloat.greatestFiniteMagnitude, height: 44)
//    }
//}

// DrawerSidebarTransitionableViewController
final class SearchViewController: UIViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    private(set) lazy var searchResultViewModel = SearchResultViewModel(context: context, coordinator: coordinator)
    private(set) lazy var searchResultViewController: SearchResultViewController = {
        let searchResultViewController = SearchResultViewController()
        searchResultViewController.context = context
        searchResultViewController.coordinator = coordinator
        searchResultViewController.viewModel = searchResultViewModel
        return searchResultViewController
    }()
    
    private(set) lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: searchResultViewController)
        searchController.searchResultsUpdater = searchResultViewController
        return searchController
    }()
    
//    private(set) var drawerSidebarTransitionController: DrawerSidebarTransitionController!
//    private var searchDetailTransitionController = SearchDetailTransitionController()

    var disposeBag = Set<AnyCancellable>()
//    let viewModel = SearchViewModel()
    
//    let avatarBarButtonItem = AvatarBarButtonItem()

//    let searchBar: UISearchBar = {
//        let searchBar = HeightFixedSearchBar()
//        searchBar.placeholder = L10n.Scene.Search.SearchBar.placeholder
//        return searchBar
//    }()
//    let searchBarTapPublisher = PassthroughSubject<Void, Never>()
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension SearchViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
        
        searchResultViewModel.$scopes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] scopes in
                guard let self = self else { return }
                self.searchController.searchBar.scopeButtonTitles = scopes.map { $0.title }
            }
            .store(in: &disposeBag)
        
        searchResultViewModel.$currentPageIndex
            .receive(on: DispatchQueue.main)
            .sink { [weak self] currentPageIndex in
                guard let self = self else { return }
                guard currentPageIndex < self.searchController.searchBar.scopeButtonTitles?.count ?? 0 else { return }
                self.searchController.searchBar.selectedScopeButtonIndex = currentPageIndex
            }
            .store(in: &disposeBag)

//        navigationItem.leftBarButtonItem = avatarBarButtonItem
//        setupSearchBar()
//        avatarBarButtonItem.avatarButton.addTarget(self, action: #selector(SearchViewController.avatarButtonPressed(_:)), for: .touchUpInside)
//
//        drawerSidebarTransitionController = DrawerSidebarTransitionController(drawerSidebarTransitionableViewController: self)
//
//        searchBarTapPublisher
//            .sink { [weak self] _ in
//                guard let self = self else { return }
//                let searchDetailViewModel = SearchDetailViewModel()
//                searchDetailViewModel.needsBecomeFirstResponder = true
//                self.navigationController?.delegate = self.searchDetailTransitionController
//                self.coordinator.present(scene: .searchDetail(viewModel: searchDetailViewModel), from: self, transition: .customPush)
//            }
//            .store(in: &disposeBag)
//        Publishers.CombineLatest3(
//            context.authenticationService.activeAuthenticationIndex.eraseToAnyPublisher(),
//            viewModel.avatarStyle.eraseToAnyPublisher(),
//            viewModel.viewDidAppear.eraseToAnyPublisher()
//        )
//        .receive(on: DispatchQueue.main)
//        .sink { [weak self] activeAuthenticationIndex, _, _ in
//            guard let self = self else { return }
//            guard let twitterUser = activeAuthenticationIndex?.twitterAuthentication?.twitterUser,
//                  let avatarImageURL = twitterUser.avatarImageURL() else {
//                self.avatarBarButtonItem.configure(withConfigurationInput: AvatarConfigurableViewConfiguration.Input(avatarImageURL: nil))
//                return
//            }
//            self.avatarBarButtonItem.configure(withConfigurationInput: AvatarConfigurableViewConfiguration.Input(avatarImageURL: avatarImageURL))
//        }
//        .store(in: &disposeBag)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
//        viewModel.viewDidAppear.send()
    }
    
}

extension SearchViewController {

//    private func setupSearchBar() {
//        let searchBarContainerView = UIView()
//        searchBar.translatesAutoresizingMaskIntoConstraints = false
//        searchBarContainerView.addSubview(searchBar)
//        NSLayoutConstraint.activate([
//            searchBar.topAnchor.constraint(equalTo: searchBarContainerView.topAnchor),
//            searchBar.leadingAnchor.constraint(equalTo: searchBarContainerView.leadingAnchor),
//            searchBar.trailingAnchor.constraint(equalTo: searchBarContainerView.trailingAnchor),
//            searchBar.bottomAnchor.constraint(equalTo: searchBarContainerView.bottomAnchor),
//        ])
//        searchBar.delegate = self
//
//        navigationItem.titleView = searchBarContainerView
//    }

}

extension SearchViewController {
    
//    @objc private func avatarButtonPressed(_ sender: UIButton) {
//        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
//        coordinator.present(scene: .drawerSidebar, from: self, transition: .custom(transitioningDelegate: drawerSidebarTransitionController))
//    }
    
}

// MARK: - UISearchBarDelegate
extension SearchViewController: UISearchBarDelegate {
//    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
//        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
//        searchBarTapPublisher.send()
//        return false
//    }
}
