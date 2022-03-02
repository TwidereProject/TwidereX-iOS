//
//  TwitterUserOwnedListViewController.swift
//  TwidereX
//
//  Created by MainasuK on 2022-3-1.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine

final class TwitterUserOwnedListViewController: UIViewController, NeedsDependency {
    
    let logger = Logger(subsystem: "TwitterUserOwnedListViewController", category: "ViewController")
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: TwitterUserOwnedListViewModel!

    private(set) lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.backgroundColor = .systemBackground
        tableView.rowHeight = UITableView.automaticDimension
        return tableView
    }()
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension TwitterUserOwnedListViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = L10n.Scene.Lists.title
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
extension TwitterUserOwnedListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): select \(indexPath.debugDescription)")
        
//        guard let diffableDataSource = viewModel.diffableDataSource else { return }
//        guard case let .trend(object) = diffableDataSource.itemIdentifier(for: indexPath) else { return }
//
//        switch object {
//        case .twitter(let trend):
//            DataSourceFacade.coordinateToSearchResult(
//                dependency: self,
//                trend: object
//            )
//        case .mastodon(let tag):
//            let hashtagTimelineViewModel = HashtagTimelineViewModel(context: context, hashtag: tag.name)
//            coordinator.present(
//                scene: .hashtagTimeline(viewModel: hashtagTimelineViewModel),
//                from: self,
//                transition: .show
//            )
//        }
    }
    
}
