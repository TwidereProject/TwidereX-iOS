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

// DrawerSidebarTransitionableViewController
final class SearchViewController: UIViewController, NeedsDependency, DrawerSidebarTransitionHostViewController {
    
    let logger = Logger(subsystem: "SearchViewController", category: "ViewController")
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: SearchViewModel!
    
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
        searchController.searchBar.delegate = searchResultViewController
        return searchController
    }()
    
    private(set) var drawerSidebarTransitionController: DrawerSidebarTransitionController!
    let avatarBarButtonItem = AvatarBarButtonItem()

    private(set) lazy var tableView: UITableView = {
        let style: UITableView.Style = UIDevice.current.userInterfaceIdiom == .phone ? .grouped : .insetGrouped
        let tableView = UITableView(frame: .zero, style: style)
        tableView.backgroundColor = .systemGroupedBackground
        tableView.rowHeight = UITableView.automaticDimension
        tableView.sectionHeaderTopPadding = 14
        return tableView
    }()
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension SearchViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        drawerSidebarTransitionController = DrawerSidebarTransitionController(hostViewController: self)

        view.backgroundColor = .systemGroupedBackground
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
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
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        tableView.delegate = self
        viewModel.setupDiffableDataSource(
            tableView: tableView
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let transitionCoordinator = self.transitionCoordinator {
            searchResultViewController.deselectRow(with: transitionCoordinator, animated: animated)            
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        viewModel.viewDidAppear.send()
    }
    
}

extension SearchViewController {
    
//    @objc private func avatarButtonPressed(_ sender: UIButton) {
//        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
//        coordinator.present(scene: .drawerSidebar, from: self, transition: .custom(transitioningDelegate: drawerSidebarTransitionController))
//    }
    
}

// MARK: - UITableViewDelegate
extension SearchViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let diffableDataSource = viewModel.diffableDataSource else { return nil }
        guard let section = diffableDataSource.sectionIdentifier(for: section) else { return nil }
    
        let container = UIView()
        container.preservesSuperviewLayoutMargins = true
        
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .secondaryLabel
        label.text = {
            switch section {
            case .history:
                return L10n.Scene.Search.savedSearch
            case .trend:
                return L10n.Scene.Trends.worldWide
            }
        }()
        
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor),
            label.leadingAnchor.constraint(equalTo: container.readableContentGuide.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: container.readableContentGuide.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: 6),
        ])
        
        return container
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        
        Task {
            let managedObjectContext = self.context.managedObjectContext
            switch item {
            case .history(let record):
                let _query: String? = await managedObjectContext.perform {
                    guard let object = record.object(in: managedObjectContext) else { return nil }
                    return object.query
                }
                guard let query = _query else { return }
                self.searchText(query)
                
            case .trend:
                break
            case .loader:
                break
            }
            
        }
    }
    
}

extension SearchViewController {

    @MainActor
    private func searchText(_ text: String) {
        searchController.isActive = true
        searchController.searchBar.text = text
    }

}
