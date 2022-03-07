//
//  ListViewController.swift
//  TwidereX
//
//  Created by MainasuK on 2022-2-28.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import UIKit
import TwidereLocalization
import TwidereUI

class ListViewController: UIViewController, NeedsDependency {
    
    let logger = Logger(subsystem: "ListViewController", category: "ViewController")
    
    // MARK: NeedsDependency
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var viewModel: ListViewModel!
    
    private(set) lazy var tableView: UITableView = {
        let style: UITableView.Style = UIDevice.current.userInterfaceIdiom == .phone ? .grouped : .insetGrouped
        let tableView = UITableView(frame: .zero, style: style)
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.backgroundColor = .systemGroupedBackground
        tableView.rowHeight = UITableView.automaticDimension
        tableView.sectionHeaderTopPadding = 14
        return tableView
    }()
    
}

extension ListViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = L10n.Scene.Lists.title
        
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.deselectRow(with: transitionCoordinator, animated: animated)
    }
    
}

// MARK: - UITableViewDelegate
extension ListViewController: UITableViewDelegate {

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
                    return L10n.Scene.Lists.Tabs.subscribed
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
            case .list(let record):
                let listStatusViewModel = ListStatusViewModel(context: context, list: record)
                coordinator.present(
                    scene: .listStatus(viewModel: listStatusViewModel),
                    from: self,
                    transition: .show
                )
            case .showMore:
                switch section {
                case .twitter(let kind):
                    switch kind {
                    case .owned:
                        assertionFailure()
//                        coordinator.present(
//                            scene: .twitterUserOwnedList(viewModel: viewModel.twitterUserOwnedListViewModel),
//                            from: self,
//                            transition: .show
//                        )
                    case .subscribed:
                        assertionFailure("TODO")
                    case .listed:
                        assertionFailure("Should display without fold")
                    }
                    
                case .mastodon:
                    assertionFailure()
                }
            case .loader, .noResults:
                break
            }
        }   // end Task
    }
    
}
