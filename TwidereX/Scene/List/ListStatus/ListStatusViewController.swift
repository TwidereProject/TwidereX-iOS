//
//  ListStatusViewController.swift
//  TwidereX
//
//  Created by MainasuK on 2022-3-2.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import CoreDataStack

final class ListStatusViewController: UIViewController, NeedsDependency, MediaPreviewTransitionHostViewController {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    let logger = Logger(subsystem: "ListStatusViewController", category: "ViewController")
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: ListStatusViewModel!
    
    let mediaPreviewTransitionController = MediaPreviewTransitionController()
    
    let menuBarButtonItem: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem()
        barButtonItem.image = UIImage(systemName: "ellipsis")
        return barButtonItem
    }()

    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        return tableView
    }()
        
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension ListStatusViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.$title
            .receive(on: DispatchQueue.main)
            .sink { [weak self] title in
                guard let self = self else { return }
                self.title = title
            }
            .store(in: &disposeBag)
        view.backgroundColor = .systemBackground
        
        navigationItem.rightBarButtonItem = menuBarButtonItem
        context.authenticationService.$activeAuthenticationContext
            .asyncMap { [weak self] authenticationContext -> UIMenu? in
                guard let self = self else { return nil }
                guard let list = self.viewModel.list else { return nil }
                guard let authenticationContext = authenticationContext else { return nil }
                do {
                    let menu = try await DataSourceFacade.createMenuForList(
                        dependency: self,
                        list: list,
                        authenticationContext: authenticationContext
                    )
                    return menu
                } catch {
                    assertionFailure(error.localizedDescription)
                    return nil
                }
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] menu in
                guard let self = self else { return }
                guard let menu = menu else { return }
                self.menuBarButtonItem.menu = menu
            }
            .store(in: &disposeBag)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        tableView.backgroundColor = .systemBackground
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
        
        // setup batch fetch
        viewModel.listBatchFetchViewModel.setup(scrollView: tableView)
        viewModel.listBatchFetchViewModel.shouldFetch
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.viewModel.stateMachine.enter(ListStatusViewModel.State.Loading.self)
            }
            .store(in: &disposeBag)
        
        // trigger loading
        viewModel.$list
            .removeDuplicates()
            .receive(on: DispatchQueue.main)        // <- required here due to trigger upstream on willSet
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.viewModel.stateMachine.enter(ListStatusViewModel.State.Reloading.self)
            }
            .store(in: &disposeBag)
        
        viewModel.$isDeleted
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isDeleted in
                guard let self = self else { return }
                guard isDeleted else { return }
                
                // pop if current view controller on screen when isDeleted
                if self.navigationController?.visibleViewController === self {
                    self.navigationController?.popViewController(animated: true)
                }
            }
            .store(in: &disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.deselectRow(with: transitionCoordinator, animated: animated)
        
        // pop if view controller will appear when isDeleted
        if viewModel.isDeleted {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
}

// MARK: - UITableViewDelegate
extension ListStatusViewController: UITableViewDelegate, AutoGenerateTableViewDelegate {
    // sourcery:inline:ListStatusViewController.AutoGenerateTableViewDelegate

    // Generated using Sourcery
    // DO NOT EDIT
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        aspectTableView(tableView, didSelectRowAt: indexPath)
    }

    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return aspectTableView(tableView, contextMenuConfigurationForRowAt: indexPath, point: point)
    }

    func tableView(_ tableView: UITableView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        return aspectTableView(tableView, previewForHighlightingContextMenuWithConfiguration: configuration)
    }

    func tableView(_ tableView: UITableView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        return aspectTableView(tableView, previewForDismissingContextMenuWithConfiguration: configuration)
    }

    func tableView(_ tableView: UITableView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        aspectTableView(tableView, willPerformPreviewActionForMenuWith: configuration, animator: animator)
    }
    // sourcery:end
}

// MARK: - CustomScrollViewContainerController
extension ListStatusViewController: ScrollViewContainer {
    var scrollView: UIScrollView { return tableView }
}

// MARK: - StatusViewTableViewCellDelegate
extension ListStatusViewController: StatusViewTableViewCellDelegate { }
