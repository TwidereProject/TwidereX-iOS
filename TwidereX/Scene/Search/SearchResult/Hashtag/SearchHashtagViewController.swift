//
//  SearchHashtagViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-11-5.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import CoreDataStack

final class SearchHashtagViewController: UIViewController, NeedsDependency {
    
    let logger = Logger(subsystem: "SearchHashtagViewController", category: "ViewController")
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: SearchHashtagViewModel!
    
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(HashtagTableViewCell.self, forCellReuseIdentifier: String(describing: HashtagTableViewCell.self))
        tableView.register(TimelineBottomLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self))
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        return tableView
    }()
    
}

extension SearchHashtagViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        context.themeService.$theme
            .map { $0.background }
            .receive(on: DispatchQueue.main)
            .assign(to: \.backgroundColor, on: tableView)
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
        
        // setup batch fetch
        viewModel.listBatchFetchViewModel.setup(scrollView: tableView)
        viewModel.listBatchFetchViewModel.shouldFetch
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                guard self.isDisplaying else { return }
                guard !self.viewModel.searchText.isEmpty else { return }
                self.viewModel.stateMachine.enter(SearchHashtagViewModel.State.Loading.self)
            }
            .store(in: &disposeBag)
        
        KeyboardResponderService
            .configure(
                scrollView: tableView,
                layoutNeedsUpdate: viewModel.viewDidAppear.eraseToAnyPublisher()
            )
            .store(in: &disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.deselectRow(with: transitionCoordinator, animated: animated)
    }
    
}

// MARK: - DeselectRowTransitionCoordinator
extension SearchHashtagViewController: DeselectRowTransitionCoordinator {
    func deselectRow(with coordinator: UIViewControllerTransitionCoordinator, animated: Bool) {
        tableView.deselectRow(with: coordinator, animated: animated)
    }
}

// MARK: - AuthContextProvider
extension SearchHashtagViewController: AuthContextProvider {
    var authContext: AuthContext { viewModel.authContext }
}

// MARK: - UITableViewDelegate
extension SearchHashtagViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let item = viewModel.item(at: indexPath) else { return }
        switch item {
        case .hashtag(let data):
            switch data {
            case .mastodon(let tag):
                let hashtagTimelineViewModel = HashtagTimelineViewModel(context: context, authContext: authContext, hashtag: tag.name)
                coordinator.present(scene: .hashtagTimeline(viewModel: hashtagTimelineViewModel), from: self, transition: .show)
            }
            
        case .bottomLoader:
            break
        }
    }
    
}
