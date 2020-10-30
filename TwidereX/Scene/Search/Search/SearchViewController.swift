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

final class SearchViewController: UIViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    private var searchDetailTransitionController = SearchDetailTransitionController()

    var disposeBag = Set<AnyCancellable>()
    
    let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search tweets or users"
        return searchBar
    }()
    let searchBarTapPublisher = PassthroughSubject<Void, Never>()
    
}

extension SearchViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "person"), style: .plain, target: nil, action: nil)
        
        setupSearchBar()
        
        searchBarTapPublisher
            .receive(on: DispatchQueue.main)
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                let searchDetailViewModel = SearchDetailViewModel()
                searchDetailViewModel.needsBecomeFirstResponder = true
                self.navigationController?.delegate = self.searchDetailTransitionController
                self.coordinator.present(scene: .searchDetail(viewModel: searchDetailViewModel), from: self, transition: .customPush)
            }
            .store(in: &disposeBag)
    }
    
}

extension SearchViewController {

    private func setupSearchBar() {
        navigationItem.titleView = searchBar
        searchBar.delegate = self
    }

}

extension SearchViewController {

}

// MARK: - UISearchBarDelegate
extension SearchViewController: UISearchBarDelegate {
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        searchBarTapPublisher.send()
        return false
    }
}
