//
//  SearchDetailViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-28.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import Tabman

final class SearchDetailViewController: UIViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: SearchDetailViewModel!
    
    private(set) var pagingViewController: SearchDetailPagingViewController!
    
    let searchBar: UISearchBar = {
        let searchBar = HeightFixedSearchBar()
        searchBar.placeholder = L10n.Scene.Search.SearchBar.placeholder
        return searchBar
    }()
    
    private(set) lazy var backBarButtonItem: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem(
            image: Asset.Arrows.arrowLeft.image.withRenderingMode(.alwaysTemplate),
            style: .plain,
            target: self,
            action: #selector(SearchDetailViewController.backBarButtonItemPressed(_:))
        )
        barButtonItem.tintColor = .label
        return barButtonItem
    }()
    
    let bar: TMBar = {
        let bar = TMBarView<TMHorizontalBarLayout, TMLabelBarButton, TMLineBarIndicator>()
        bar.layout.contentMode = .fit
        bar.indicator.weight = .custom(value: 2)
        bar.backgroundView.style = .flat(color: .systemBackground)
        bar.buttons.customize { barItem in
            barItem.selectedTintColor = Asset.Colors.hightLight.color
            barItem.tintColor = .secondaryLabel
        }
        return bar
    }()
    
}

extension SearchDetailViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = backBarButtonItem
        setupSearchBar()
        
        pagingViewController = SearchDetailPagingViewController()
        pagingViewController.pagingDelegate = self
        pagingViewController.viewModel = SearchDetailPagingViewModel(context: context, coordinator: coordinator)
        
        pagingViewController.addBar(
            bar,
            dataSource: pagingViewController.viewModel,
            at: .custom(view: view, layout: { bar in
                bar.translatesAutoresizingMaskIntoConstraints = false
                self.view.addSubview(bar)
                NSLayoutConstraint.activate([
                    bar.topAnchor.constraint(equalTo: self.view.layoutMarginsGuide.topAnchor),
                    bar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                    bar.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                    bar.heightAnchor.constraint(equalToConstant: 48).priority(.defaultHigh),
                ])
            })
        )

        pagingViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pagingViewController.view)
        addChild(pagingViewController)
        NSLayoutConstraint.activate([
            pagingViewController.view.topAnchor.constraint(equalTo: bar.bottomAnchor),
            pagingViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pagingViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pagingViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        pagingViewController.didMove(toParent: self)
        
        // set search text if has initialSearchText
        viewModel.searchText
            .receive(on: DispatchQueue.main)
            .first()
            .sink { [weak self] initialSearchText in
                guard let self = self else { return }
                guard !initialSearchText.isEmpty else { return }
                self.searchBar.text = initialSearchText
            }
            .store(in: &disposeBag)

        // trigger loading after view appear if has initialSearchText
        Publishers.CombineLatest(
            viewModel.searchText.eraseToAnyPublisher(),
            viewModel.viewDidAppear.eraseToAnyPublisher()
        )
        .receive(on: DispatchQueue.main)
        .first()
        .sink { [weak self] initialSearchText, _ in
            guard let self = self else { return }
            guard !initialSearchText.isEmpty else { return }
            self.viewModel.searchActionPublisher.send()
        }
        .store(in: &disposeBag)
        
        // bind search text to children
        viewModel.searchText
            .assign(to: \.value, on: pagingViewController.viewModel.searchText)
            .store(in: &disposeBag)
        viewModel.searchActionPublisher
            .subscribe(pagingViewController.viewModel.searchActionPublisher)
            .store(in: &disposeBag)
            
        view.bringSubviewToFront(bar)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if viewModel.needsBecomeFirstResponder {
            searchBar.becomeFirstResponder()
            viewModel.needsBecomeFirstResponder = false
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        viewModel.viewDidAppear.send()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        bar.layer.setupShadow(color: UIColor.black.withAlphaComponent(0.12), alpha: 1, x: 0, y: 2, blur: 2, spread: 0, roundedRect: bar.bounds, byRoundingCorners: .allCorners, cornerRadii: .zero)
    }
    
}

extension SearchDetailViewController {
    
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

extension SearchDetailViewController {
 
    @objc private func backBarButtonItemPressed(_ sender: UIBarButtonItem) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        navigationController?.popViewController(animated: true)
    }
    
}

// MARK: - UISearchBarDelegate
extension SearchDetailViewController: UISearchBarDelegate {
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        return true
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.searchText.value = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        
        viewModel.searchActionPublisher.send()
        searchBar.resignFirstResponder()
    }
}

// MARK: - SearchDetailPagingViewControllerDelegate
extension SearchDetailViewController: SearchDetailPagingViewControllerDelegate {
    
    func searchDetailPagingViewController(_ pagingViewController: SearchDetailPagingViewController, didScrollToViewController viewController: UIViewController, atIndex index: Int) {
        os_log("%{public}s[%{public}ld], %{public}s: scroll to index: %ld", ((#file as NSString).lastPathComponent), #line, #function, index)

        // trigger uninitialized model perfom search
        if let searchMediaViewController = viewController as? SearchMediaViewController {
            searchMediaViewController.viewModel.searchActionPublisher.send()
        }
        
        if let searchUserViewController = viewController as? SearchUserViewController {
            searchUserViewController.viewModel.searchActionPublisher.send()
        }
    }
    
}
