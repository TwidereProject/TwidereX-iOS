//
//  MentionPickViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-14.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import AlamofireImage
import TwitterAPI

final class MentionPickViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let primaryItem: MentionPickItem
    let secondaryItems: [MentionPickItem]
    
    // output
    var diffableDataSource: UITableViewDiffableDataSource<MentionPickSection, MentionPickItem>!
    
    init(context: AppContext, primaryItem: MentionPickItem, secondaryItems: [MentionPickItem]) {
        self.context = context
        self.primaryItem = primaryItem
        self.secondaryItems = secondaryItems
    }
    
}

extension MentionPickViewModel {
    
    func setupDiffableTableViewDataSource(for tableView: UITableView) {
        diffableDataSource = UITableViewDiffableDataSource(tableView: tableView) { [weak self] tableView, indexPath, item -> UITableViewCell? in
            guard let self = self else { return nil }
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: MentionPickTableViewCell.self), for: indexPath) as! MentionPickTableViewCell
            MentionPickViewModel.configure(cell: cell, item: item)
            return cell
        }
        
        var snapshot = NSDiffableDataSourceSnapshot<MentionPickSection, MentionPickItem>()
        snapshot.appendSections([.primary])
        snapshot.appendItems([primaryItem], toSection: .primary)
        if !secondaryItems.isEmpty {
            snapshot.appendSections([.secondary])
            snapshot.appendItems(secondaryItems, toSection: .secondary)
        }
        diffableDataSource.apply(snapshot)
    }
}

extension MentionPickViewModel {
    
    static func configure(cell: MentionPickTableViewCell, item: MentionPickItem) {
        switch item {
        case .twitterUser(let username, let attribute):
            let avatarImageURL = attribute.avatarImageURL
            UserDefaults.shared
                .observe(\.avatarStyle, options: [.initial, .new]) { defaults, _ in
                    cell.userBriefInfoView.configure(avatarImageURL: avatarImageURL)
                }
                .store(in: &cell.observations)
            
            cell.userBriefInfoView.nameLabel.text = attribute.name ?? "-"
            cell.userBriefInfoView.usernameLabel.text = " "
            cell.userBriefInfoView.detailLabel.text = "@" + username
            
            cell.userBriefInfoView.activityIndicatorView.isHidden = attribute.state == .finish
            cell.userBriefInfoView.checkmarkButton.isHidden = attribute.state == .loading
            
            if attribute.selected {
                cell.userBriefInfoView.checkmarkButton.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
            } else {
                cell.userBriefInfoView.checkmarkButton.setImage(UIImage(systemName: "circle"), for: .normal)
            }
            cell.selectionStyle = attribute.disabled ? .none : .default
            cell.userBriefInfoView.checkmarkButton.tintColor = attribute.disabled ? .systemGray : (attribute.selected ? Asset.Colors.hightLight.color : .systemGray)
        }

    }
    
}

extension MentionPickViewModel {
    
    func resolveLoadingItems(twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox) -> AnyPublisher<Twitter.Response.Content<Twitter.API.V2.UserLookup.Content>, Error> {        
        let usernames = secondaryItems
            .compactMap { item -> String? in
                switch item {
                case .twitterUser(let username, let attribute):
                    guard attribute.state == .loading else { return nil }
                    return username
                }
            }
        return context.apiService.users(
            usernames: usernames,
            twitterAuthenticationBox: twitterAuthenticationBox
        )
    }
}
