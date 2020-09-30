//
//  TweetConversationViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-15.
//

import os.log
import UIKit
import Combine
import CoreDataStack
import TwitterAPI

final class TweetConversationViewController: UIViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: TweetConversationViewModel!
    
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(ConversationPostTableViewCell.self, forCellReuseIdentifier: String(describing: ConversationPostTableViewCell.self))
        tableView.register(TimelinePostTableViewCell.self, forCellReuseIdentifier: String(describing: TimelinePostTableViewCell.self))
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        return tableView
    }()
    
}

extension TweetConversationViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        tableView.backgroundColor = .systemBackground
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor)
        ])
        
        viewModel.conversationPostTableViewCellDelegate = self
        viewModel.setupDiffableDataSource(for: tableView)
        tableView.delegate = self
        tableView.dataSource = viewModel.diffableDataSource
        tableView.reloadData()
    }
    
}

// MARK: - UITableViewDelegate
extension TweetConversationViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 200
    }
}

// MARK: - ConversationPostTableViewCellDelegate
extension TweetConversationViewController: ConversationPostTableViewCellDelegate {
    
    func conversationPostTableViewCell(_ cell: ConversationPostTableViewCell, avatarImageViewDidPressed imageView: UIImageView) {
//        let tweet = viewModel.rootItem.retweetObject ?? viewModel.tweetObject
//        let twitterUser = tweet.userObject
//        let profileViewModel = ProfileViewModel(twitterUser: twitterUser)
//        self.coordinator.present(scene: .profile(viewModel: profileViewModel), from: self, transition: .showDetail)
    }
    
    func conversationPostTableViewCell(_ cell: ConversationPostTableViewCell, quoteAvatarImageViewDidPressed imageView: UIImageView) {
//        guard let tweet = viewModel.tweetObject.retweetObject?.quoteObject ?? viewModel.tweetObject.quoteObject else { return }
//        let twitterUser = tweet.userObject
//        let profileViewModel = ProfileViewModel(twitterUser: twitterUser)
//        self.coordinator.present(scene: .profile(viewModel: profileViewModel), from: self, transition: .showDetail)
    }
    
    
}
