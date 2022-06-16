//
//  ListViewController.swift
//  TwidereX
//
//  Created by MainasuK on 2022-2-28.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import TwidereLocalization

final class ListViewController: UIViewController, NeedsDependency {
    
    let logger = Logger(subsystem: "ListViewController", category: "ViewController")
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: ListViewModel!

    private(set) lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.backgroundColor = .systemBackground
        tableView.rowHeight = UITableView.automaticDimension
        return tableView
    }()
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension ListViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = {
            switch viewModel.kind {
            case .none:         return nil
            case .owned:        return L10n.Scene.Lists.title
            case .subscribed:   return L10n.Scene.Lists.Tabs.subscribed.localizedCapitalized
            case .listed:       return L10n.Scene.Listed.title
            }
        }()
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
            tableView: tableView
        )
        // setup batch fetch
        viewModel.listBatchFetchViewModel.setup(scrollView: tableView)
        viewModel.listBatchFetchViewModel.shouldFetch
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.viewModel.stateMachine.enter(ListViewModel.State.Loading.self)
            }
            .store(in: &disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.deselectRow(with: transitionCoordinator, animated: animated)
    }
    
}

// MARK: - UITableViewDelegate
extension ListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): select \(indexPath.debugDescription)")
        
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard case let .list(record, _) = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        
        let listStatusViewModel = ListStatusTimelineViewModel(context: context, list: record)
        coordinator.present(
            scene: .listStatus(viewModel: listStatusViewModel),
            from: self,
            transition: .show
        )
    }
    
}
