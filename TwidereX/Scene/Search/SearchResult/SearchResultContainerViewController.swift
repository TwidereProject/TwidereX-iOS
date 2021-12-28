//
//  SearchResultContainerViewController.swift
//  TwidereX
//
//  Created by MainasuK on 2021-12-27.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine

final class SearchResultContainerViewController: UIViewController {
    
    var disposeBag = Set<AnyCancellable>()
    
    var searchText: String = ""
    var searchResultViewModel: SearchResultViewModel!
    var searchResultViewController: SearchResultViewController!
    
    private(set) lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = searchResultViewController
        searchController.searchBar.delegate = searchResultViewController
        searchController.automaticallyShowsCancelButton = false
        searchController.searchBar.showsCancelButton = true
        searchController.automaticallyShowsScopeBar = false
        searchController.searchBar.showsScopeBar = true
        return searchController
    }()
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension SearchResultContainerViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = L10n.Scene.Search.title
        view.backgroundColor = .secondarySystemBackground
        
        definesPresentationContext = true
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        addChild(searchResultViewController)
        searchResultViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchResultViewController.view)
        NSLayoutConstraint.activate([
            searchResultViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            searchResultViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchResultViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            searchResultViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        searchResultViewController.didMove(toParent: self)
        
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
        
        searchResultViewController.searchResultDelegate = self
        
        search(searchText)
    }
    
}

// MARK: - UIAdaptivePresentationControllerDelegate
extension SearchResultContainerViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .fullScreen
    }
}

extension SearchResultContainerViewController {

    @MainActor
    private func search(_ text: String) {
        searchController.searchBar.text = text
    }

}

// MARK: - SearchResultViewControllerDelegate
extension SearchResultContainerViewController: SearchResultViewControllerDelegate {
    func searchResultViewController(_ searchResultViewController: SearchResultViewController, searchBarCancelButtonClicked searchBar: UISearchBar) {
        dismiss(animated: true, completion: nil)
    }
}
