//
//  StatusThreadViewController.swift
//  StatusThreadViewController
//
//  Created by Cirno MainasuK on 2021-8-30.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine

final class StatusThreadViewController: UIViewController, NeedsDependency, MediaPreviewTransitionHostViewController {

    let logger = Logger(subsystem: "StatusThreadViewController", category: "ViewController")
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }

    var disposeBag = Set<AnyCancellable>()
    var viewModel: StatusThreadViewModel!
    
    let mediaPreviewTransitionController = MediaPreviewTransitionController()
    
    private(set) lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(StatusThreadRootTableViewCell.self, forCellReuseIdentifier: String(describing: StatusThreadRootTableViewCell.self))
        tableView.register(StatusTableViewCell.self, forCellReuseIdentifier: String(describing: StatusTableViewCell.self))
        tableView.register(TimelineBottomLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self))
        tableView.backgroundColor = .systemBackground
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        return tableView
    }()
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s:", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension StatusThreadViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
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
            tableView: tableView,
            statusViewTableViewCellDelegate: self
        )
        viewModel.topListBatchFetchViewModel.setup(scrollView: tableView)
        viewModel.bottomListBatchFetchViewModel.setup(scrollView: tableView)
        viewModel.topListBatchFetchViewModel.shouldFetch
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.viewModel.twitterStatusThreadReplyViewModel.stateMachine.enter(TwitterStatusThreadReplyViewModel.State.Loading.self)
            }
            .store(in: &disposeBag)
        viewModel.bottomListBatchFetchViewModel.shouldFetch
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.viewModel.loadThreadStateMachine.enter(StatusThreadViewModel.LoadThreadState.Loading.self)
            }
            .store(in: &disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        tableView.deselectRow(with: transitionCoordinator, animated: animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        viewModel.viewDidAppear.send()
    }
}

// MARK: - UITableViewDelegate
extension StatusThreadViewController: UITableViewDelegate, AutoGenerateTableViewDelegate {
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let diffableDataSource = viewModel.diffableDataSource else { return indexPath }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return indexPath }
        guard case let .thread(thread) = item else { return indexPath }
        
        switch thread {
        case .root:
            return nil
        case .reply, .leaf:
            return indexPath
        }
    }
    
    // sourcery:inline:StatusThreadViewController.AutoGenerateTableViewDelegate

    // Generated using Sourcery
    // DO NOT EDIT
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        aspectTableView(tableView, didSelectRowAt: indexPath)
    }
    // sourcery:end
    
    
}


// MARK: - StatusViewTableViewCellDelegate
extension StatusThreadViewController: StatusViewTableViewCellDelegate { }
