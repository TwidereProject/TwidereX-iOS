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
import TwidereLocalization
import TwidereUI

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
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.backgroundColor = .systemGroupedBackground
        tableView.rowHeight = UITableView.automaticDimension
        tableView.sectionHeaderTopPadding = 14
        return tableView
    }()
    
    let historySectionHeaderView: TableViewSectionTextHeaderView = {
        let header = TableViewSectionTextHeaderView()
        header.label.text = L10n.Scene.Search.savedSearch
        return header
    }()
    
    private(set) lazy var trendSectionHeaderView: TableViewSectionTextHeaderView = {
        let headerView = TableViewSectionTextHeaderView()
        headerView.button.setImage(UIImage(systemName: "map.circle.fill"), for: .normal)
        headerView.button.tintColor = .secondaryLabel
        headerView.button.isHidden = false
        headerView.button.addTarget(self, action: #selector(SearchViewController.trendPlaceButtonDidPressed(_:)), for: .touchUpInside)
        return headerView
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
        
        // bind trend section titile
        viewModel.trendViewModel.$trendPlaceName
            .receive(on: DispatchQueue.main)
            .sink { [weak self] name in
                guard let self = self else { return }
                let title = [L10n.Scene.Trends.title, name].compactMap { $0 }.joined(separator: " - ")
                self.trendSectionHeaderView.label.text = title
            }
            .store(in: &disposeBag)
        
        // bind twitter trend place entry
        viewModel.context.authenticationService.$activeAuthenticationContext
            .receive(on: DispatchQueue.main)
            .sink { [weak self] authenticationContext in
                guard let self = self else { return }
                switch authenticationContext {
                case .twitter:
                    self.trendSectionHeaderView.button.isHidden = false
                default:
                    self.trendSectionHeaderView.button.isHidden = true
                }
            }
            .store(in: &disposeBag)
        
        // bind searchBar bookmark
        Publishers.CombineLatest3(
            viewModel.$savedSearchTexts,
            searchResultViewModel.$searchText,
            context.authenticationService.$activeAuthenticationContext
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] texts, searchText, activeAuthenticationContext in
            guard let self = self else { return }
            let text = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty,
                  !texts.contains(text)
            else {
                self.searchController.searchBar.showsBookmarkButton = false
                return
            }
            switch activeAuthenticationContext {
            case .twitter, .mastodon:
                self.searchController.searchBar.showsBookmarkButton = true
            case nil:
                self.searchController.searchBar.showsBookmarkButton = false
            }
        }
        .store(in: &disposeBag)
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

    @objc private func trendPlaceButtonDidPressed(_ sender: UIButton) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        
        coordinator.present(
            scene: .trendPlace(viewModel: viewModel.trendViewModel),
            from: self,
            transition: .modal(animated: true)
        )
    }

}

// MARK: - UITableViewDelegate
extension SearchViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let diffableDataSource = viewModel.diffableDataSource else { return nil }
        guard let section = diffableDataSource.sectionIdentifier(for: section) else { return nil }
    
        switch section {
        case .history:
            return historySectionHeaderView
        case .trend:
            return trendSectionHeaderView
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let section = diffableDataSource.sectionIdentifier(for: indexPath.section) else { return }
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
                
            case .trend(let object):
                switch object {
                case .twitter(let trend):
                    self.searchText(trend.name)
                case .mastodon(let tag):
                    let hashtagTimelineViewModel = HashtagTimelineViewModel(context: context, hashtag: tag.name)
                    coordinator.present(
                        scene: .hashtagTimeline(viewModel: hashtagTimelineViewModel),
                        from: self,
                        transition: .show
                    )
                }
            case .showMore:
                switch section {
                case .history:
                    coordinator.present(
                        scene: .savedSearch(viewModel: viewModel.savedSearchViewModel),
                        from: self,
                        transition: .show
                    )
                case .trend:
                    coordinator.present(
                        scene: .trend(viewModel: viewModel.trendViewModel),
                        from: self,
                        transition: .show
                    )
                }
                
            case .loader, .noResults:
                break
            }
        }   // end Task
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        
        guard let diffableDataSource = self.viewModel.diffableDataSource,
              case let .history(record) = diffableDataSource.itemIdentifier(for: indexPath),
              let authenticationContext = self.viewModel.context.authenticationService.activeAuthenticationContext
        else { return nil }
        
        let deleteAction = UIContextualAction(
            style: .destructive,
            title: L10n.Common.Controls.Actions.delete,
            handler: { [weak self] _, _, completionHandler in
                guard let self = self else {
                    completionHandler(false)
                    return
                }
                
                Task {
                    do {
                        try await DataSourceFacade.responseToDeleteSavedSearch(
                            dependency: self,
                            savedSearch: record,
                            authenticationContext: authenticationContext
                        )
                        completionHandler(true)
                    } catch {
                        completionHandler(false)
                    }
                }
            }
        )   // end deleteAction
        
        return UISwipeActionsConfiguration(actions: [
            deleteAction
        ])
    }
    
}

extension SearchViewController {

    @MainActor
    private func searchText(_ text: String) {
        searchController.isActive = true
        searchController.searchBar.text = text
        searchResultViewController.viewModel.selectedScope = searchResultViewController.viewModel.scopes.first
    }

}
