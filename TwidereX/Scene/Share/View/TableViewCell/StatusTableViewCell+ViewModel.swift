//
//  StatusTableViewCell+ViewModel.swift
//  StatusTableViewCell+ViewModel
//
//  Created by Cirno MainasuK on 2021-8-27.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import Combine
import SwiftUI
import CoreDataStack

extension StatusTableViewCell {
    final class ViewModel {
        enum Value {
            case feed(Feed)
            case twitterStatus(TwitterStatus)
            case mastodonStatus(MastodonStatus)
        }
        
        let value: Value
        
        init(value: Value) {
            self.value = value
        }
    }
    
    func configure(
        tableView: UITableView,
        viewModel: ViewModel,
        delegate: StatusViewTableViewCellDelegate
    ) {
        if statusView.frame == .zero {
            // set status view width
            statusView.frame.size.width = tableView.readableContentGuide.layoutFrame.width
            let contentMaxLayoutWidth = statusView.contentMaxLayoutWidth
            statusView.quoteStatusView?.frame.size.width = contentMaxLayoutWidth
            // set preferredMaxLayoutWidth for content
            statusView.contentTextView.preferredMaxLayoutWidth = contentMaxLayoutWidth
            statusView.quoteStatusView?.contentTextView.preferredMaxLayoutWidth = statusView.quoteStatusView?.contentMaxLayoutWidth
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): did layout for new cell")
        }
        
        switch viewModel.value {
        case .feed(let feed):
            statusView.configure(feed: feed)
            configureSeparator(style: feed.hasMore ? .edge : .inset)
        case .twitterStatus(let status):
            statusView.configure(twitterStatus: status)
            configureSeparator(style: .inset)
        case .mastodonStatus(let status):
            statusView.configure(mastodonStatus: status, notification: nil)
            configureSeparator(style: .inset)
        }
        
        self.delegate = delegate
    }
}


extension StatusTableViewCell {
    enum SeparatorStyle {
        case edge
        case inset
    }
    
    func configureSeparator(style: SeparatorStyle) {
        separator.removeFromSuperview()
        separator.removeConstraints(separator.constraints)
        
        switch style {
        case .edge:
            separator.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(separator)
            NSLayoutConstraint.activate([
                separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                separator.heightAnchor.constraint(equalToConstant: UIView.separatorLineHeight(of: contentView)),
            ])
        case .inset:
            separator.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(separator)
            NSLayoutConstraint.activate([
                separator.leadingAnchor.constraint(equalTo: statusView.toolbar.leadingAnchor),
                separator.trailingAnchor.constraint(equalTo: statusView.toolbar.trailingAnchor),
                separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                separator.heightAnchor.constraint(equalToConstant: UIView.separatorLineHeight(of: contentView)),
            ])
        }
    }
}
