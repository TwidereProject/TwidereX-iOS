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

final class SearchResultViewController: TabmanViewController, NeedsDependency {
    
    let logger = Logger(subsystem: "SearchResultViewController", category: "ViewController")
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: SearchResultViewModel!
    
    override func pageboyViewController(
        _ pageboyViewController: PageboyViewController,
        didScrollToPageAt index: TabmanViewController.PageIndex,
        direction: PageboyViewController.NavigationDirection, animated: Bool
    ) {
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
                if let preferredScope = self.viewModel.preferredScope {
                    // TODO:
                } else {
                    self.scrollToPage(.first, animated: false, completion: nil)
                }
            }
            .store(in: &disposeBag)
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
