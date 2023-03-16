//
//  UserHistoryViewController.swift
//  TwidereX
//
//  Created by MainasuK on 2022-7-29.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import CoreDataStack

final class UserHistoryViewController: UIViewController, NeedsDependency, MediaPreviewableViewController {

    let logger = Logger(subsystem: "UserHistoryViewController", category: "ViewController")
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: UserHistoryViewModel!
    
    let mediaPreviewTransitionController = MediaPreviewTransitionController()
    
    private(set) lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .systemBackground
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        tableView.sectionHeaderTopPadding = .zero
        return tableView
    }()

}

extension UserHistoryViewController {
    
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
            userViewTableViewCellDelegate: self
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.deselectRow(with: transitionCoordinator, animated: animated)
    }
    
}

// MARK: - AuthContextProvider
extension UserHistoryViewController: AuthContextProvider {
    var authContext: AuthContext { viewModel.authContext }
}

// MARK: - UITableViewDelegate
extension UserHistoryViewController: UITableViewDelegate, AutoGenerateTableViewDelegate {
    // sourcery:inline:UserHistoryViewController.AutoGenerateTableViewDelegate

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
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let diffableDataSource = viewModel.diffableDataSource else { return nil }
        guard let sectionIdentifier = diffableDataSource.sectionIdentifier(for: section) else { return nil }
        switch sectionIdentifier {
        case .group(let identifer):
            guard let date = History.date(from: identifer) else { return nil }
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            formatter.timeStyle = .none
            
            let title = formatter.string(from: date)
            let header = TableViewSectionTextHeaderView()
            header.label.text = title
            
            let container = UIView()
            container.backgroundColor = .secondarySystemBackground
            header.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(header)
            NSLayoutConstraint.activate([
                header.topAnchor.constraint(equalTo: container.topAnchor),
                header.leadingAnchor.constraint(equalTo: container.readableContentGuide.leadingAnchor),
                header.trailingAnchor.constraint(equalTo: container.readableContentGuide.trailingAnchor),
                header.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            ])
            return container
        }
    }
    
}

// MARK: - UserViewTableViewCellDelegate
extension UserHistoryViewController: UserViewTableViewCellDelegate { }
