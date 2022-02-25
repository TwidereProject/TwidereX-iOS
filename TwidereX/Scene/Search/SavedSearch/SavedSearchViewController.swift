//
//  SavedSearchViewController.swift
//  TwidereX
//
//  Created by MainasuK on 2021-12-27.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine

final class SavedSearchViewController: UIViewController, NeedsDependency {
    
    let logger = Logger(subsystem: "SavedSearchViewController", category: "ViewController")
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: SavedSearchViewModel!

    private(set) lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .systemBackground
        tableView.rowHeight = UITableView.automaticDimension
        return tableView
    }()
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension SavedSearchViewController {
    
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
        viewModel.setupDiffableDataSource(tableView: tableView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.deselectRow(with: transitionCoordinator, animated: animated)
    }
    
}

// MARK: - UITableViewDelegate
extension SavedSearchViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): select \(indexPath.debugDescription)")
        
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard case let .history(record) = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        
        DataSourceFacade.coordinateToSearchResult(
            dependency: self,
            savedSearch: record
        )
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        
        guard let diffableDataSource = self.viewModel.diffableDataSource,
              case let .history(record) = diffableDataSource.itemIdentifier(for: indexPath),
              let authenticationContext = self.viewModel.context.authenticationService.activeAuthenticationContext
        else { return nil }
        
        let deleteAction = UIContextualAction(
            style: .destructive,
            title: L10n.Common.Controls.Actions.delete,
            handler: { [weak self] _, _, completionHandler in
                guard let self = self else {
                    completionHandler(false)
                    return
                }
                
                Task {
                    do {
                        try await DataSourceFacade.responseToDeleteSavedSearch(
                            dependency: self,
                            savedSearch: record,
                            authenticationContext: authenticationContext
                        )
                        completionHandler(true)
                    } catch {
                        completionHandler(false)
                    }
                }
            }
        )   // end deleteAction
        
        return UISwipeActionsConfiguration(actions: [
            deleteAction
        ])
    }
    
}
