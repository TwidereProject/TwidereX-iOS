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
import AlamofireImage

final class HeightFixedSearchBar: UISearchBar {
    override var intrinsicContentSize: CGSize {
        return CGSize(width: CGFloat.greatestFiniteMagnitude, height: 44)
    }
}

final class SearchViewController: UIViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    private var searchDetailTransitionController = SearchDetailTransitionController()

    var disposeBag = Set<AnyCancellable>()
    
    let avatarButton = UIButton.avatarButton

    let searchBar: UISearchBar = {
        let searchBar = HeightFixedSearchBar()
        searchBar.placeholder = "Search tweets or users"
        return searchBar
    }()
    let searchBarTapPublisher = PassthroughSubject<Void, Never>()
    
}

extension SearchViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: avatarButton)
        setupSearchBar()

        searchBarTapPublisher
//            .receive(on: DispatchQueue.main)
//            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                let searchDetailViewModel = SearchDetailViewModel()
                searchDetailViewModel.needsBecomeFirstResponder = true
                self.navigationController?.delegate = self.searchDetailTransitionController
                self.coordinator.present(scene: .searchDetail(viewModel: searchDetailViewModel), from: self, transition: .customPush)
            }
            .store(in: &disposeBag)
        context.authenticationService.activeAuthenticationIndex
            .sink { [weak self] activeAuthenticationIndex in
                guard let self = self else { return }
                let placeholderImage = UIImage
                    .placeholder(size: UIButton.avatarButtonSize, color: .systemFill)
                    .af.imageRoundedIntoCircle()
                guard let twitterUser = activeAuthenticationIndex?.twitterAuthentication?.twitterUser,
                      let avatarImageURL = twitterUser.avatarImageURL() else {
                    self.avatarButton.setImage(placeholderImage, for: .normal)
                    return
                }
                let filter = ScaledToSizeCircleFilter(size: UIButton.avatarButtonSize)
                self.avatarButton.af.setImage(
                    for: .normal,
                    url: avatarImageURL,
                    placeholderImage: placeholderImage,
                    filter: filter
                )
            }
            .store(in: &disposeBag)
    }
    
}

extension SearchViewController {

    private func setupSearchBar() {
        let searchBarContainerView = UIView()
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBarContainerView.addSubview(searchBar)
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: searchBarContainerView.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: searchBarContainerView.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: searchBarContainerView.trailingAnchor),
            searchBar.bottomAnchor.constraint(equalTo: searchBarContainerView.bottomAnchor),
        ])
        searchBar.delegate = self
        
        navigationItem.titleView = searchBarContainerView
    }

}

// MARK: - UISearchBarDelegate
extension SearchViewController: UISearchBarDelegate {
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        searchBarTapPublisher.send()
        return false
    }
}
