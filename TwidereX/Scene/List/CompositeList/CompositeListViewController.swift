//
//  CompositeListViewController.swift
//  TwidereX
//
//  Created by MainasuK on 2022-3-7.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import TwidereLocalization
import TwidereUI

class CompositeListViewController: UIViewController, NeedsDependency {
    
    var disposeBag = Set<AnyCancellable>()
    
    let logger = Logger(subsystem: "CompositeListViewController", category: "ViewController")
    
    // MARK: NeedsDependency
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var viewModel: CompositeListViewModel!
    
    private(set) lazy var tableView: UITableView = {
        let style: UITableView.Style = UIDevice.current.userInterfaceIdiom == .phone ? .grouped : .insetGrouped
        let tableView = UITableView(frame: .zero, style: style)
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.backgroundColor = .systemGroupedBackground
        tableView.rowHeight = UITableView.automaticDimension
        tableView.sectionHeaderTopPadding = 14
        return tableView
    }()
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension CompositeListViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = {
            switch viewModel.kind {
            case .lists:        return L10n.Scene.Lists.title
            case .listed:       return L10n.Scene.Listed.title
            }
        }()
        
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
        
        switch viewModel.kind {
        case .lists:
            break
        case .listed:
            // setup batch fetch
            viewModel.listBatchFetchViewModel.setup(scrollView: tableView)
            viewModel.listBatchFetchViewModel.shouldFetch
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    guard let self = self else { return }
                    self.viewModel.listedListViewModel.stateMachine.enter(ListViewModel.State.Loading.self)
                }
                .store(in: &disposeBag)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.deselectRow(with: transitionCoordinator, animated: animated)
    }
    
}

// MARK: - UITableViewDelegate
extension CompositeListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let diffableDataSource = viewModel.diffableDataSource else { return nil }
        guard let section = diffableDataSource.sectionIdentifier(for: section) else { return nil }
    
        let header = TableViewSectionTextHeaderView()
        
        header.label.text = {
            switch section {
            case .twitter(let kind):
                switch kind {
                case .owned:
                    return L10n.Scene.Lists.title
                case .subscribed:
                    return L10n.Scene.Lists.Tabs.subscribed.localizedCapitalized
                case .listed:
                    return " "
                }
            case .mastodon:
                return " "
            }
        }()
        
        return header
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): indexPath: \(indexPath)")
        
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let section = diffableDataSource.sectionIdentifier(for: indexPath.section) else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        
        Task {
            switch item {
            case .list(let record, _):
                let listStatusViewModel = ListStatusViewModel(context: context, list: record)
                coordinator.present(
                    scene: .listStatus(viewModel: listStatusViewModel),
                    from: self,
                    transition: .show
                )
            case .showMore:
                switch section {
                case .twitter(let kind):
                    let listViewModel: ListViewModel = {
                        switch kind {
                        case .owned:        return viewModel.ownedListViewModel
                        case .subscribed:   return viewModel.subscribedListViewModel
                        case .listed:       return viewModel.listedListViewModel
                        }
                    }()
                    coordinator.present(
                        scene: .list(viewModel: listViewModel),
                        from: self,
                        transition: .show
                    )
                    
                case .mastodon:
                    assertionFailure("There is no entry will go here")
                }
            case .loader, .noResults:
                break
            }
        }   // end Task
    }
    
}
