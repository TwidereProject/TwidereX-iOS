//
//  SearchResultViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-22.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import Tabman
import Pageboy

protocol DeselectRowTransitionCoordinator {
    func deselectRow(with coordinator: UIViewControllerTransitionCoordinator, animated: Bool)
}

final class SearchResultViewController: TabmanViewController, NeedsDependency {
    
    let logger = Logger(subsystem: "SearchResultViewController", category: "ViewController")
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: SearchResultViewModel!
    
    override func pageboyViewController(
        _ pageboyViewController: PageboyViewController,
        didScrollToPageAt index: TabmanViewController.PageIndex,
        direction: PageboyViewController.NavigationDirection,
        animated: Bool
    ) {
        super.pageboyViewController(
            pageboyViewController,
            didScrollToPageAt: index,
            direction: direction,
            animated: animated
        )
        
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): index: \(index)")
        viewModel.currentPageIndex = index        
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension SearchResultViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource = viewModel

        viewModel.$scopes
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] scopes in
                guard let self = self else { return }
                self.reloadData()
                self.scrollToPage(.first, animated: false, completion: nil)
                self.viewModel.selectedScope = scopes.first
            }
            .store(in: &disposeBag)
        
        viewModel.$selectedScope
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] scope in
                guard let self = self else { return }
                guard let scope = scope else { return }
                guard let index = self.viewModel.scopes.firstIndex(of: scope) else { return }
                self.scrollToPage(.at(index: index), animated: true, completion: nil)
            }
            .store(in: &disposeBag)
    }
    
}

// MARK: - DeselectRowTransitionCoordinator
extension SearchResultViewController: DeselectRowTransitionCoordinator {
    func deselectRow(with coordinator: UIViewControllerTransitionCoordinator, animated: Bool) {
        for viewController in viewModel.viewControllers {
            guard let viewController = viewController as? DeselectRowTransitionCoordinator else { continue }
            viewController.deselectRow(with: coordinator, animated: animated)
        }
    }
}

// MARK: - UISearchResultsUpdating
extension SearchResultViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): search text: \(searchController.searchBar.text ?? "<nil>")")
        
        let searchText = searchController.searchBar.text ?? ""
        viewModel.searchText = searchText
    }
}

// MARK: - UISearchBarDelegate
extension SearchResultViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): selectedScope: \(selectedScope)")
        let scopes = viewModel.scopes
        guard selectedScope < scopes.count else { return }
        let scope = scopes[selectedScope]
        viewModel.selectedScope = scope
    }
}
