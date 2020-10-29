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
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search tweets or users"
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
        pagingViewController.viewModel = SearchDetailPagingViewModel(context: context)
        
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
        
        DispatchQueue.once {
            searchBar.becomeFirstResponder()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        bar.layer.setupShadow(color: UIColor.black.withAlphaComponent(0.12), alpha: 1, x: 0, y: 2, blur: 2, spread: 0, roundedRect: bar.bounds, byRoundingCorners: .allCorners, cornerRadii: .zero)
    }
    
}

extension SearchDetailViewController {
    
    private func setupSearchBar() {
        navigationItem.titleView = searchBar
        searchBar.delegate = self
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
