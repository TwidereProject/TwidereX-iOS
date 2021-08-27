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
    final class ViewModel: ObservableObject {
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
    
    func configuration(
        tableView: UITableView,
        viewModel: StatusTableViewCell.ViewModel,
        delegate: StatusTableViewCellDelegate
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
        case .twitterStatus(let status):
            assertionFailure()
        case .mastodonStatus(let status):
            statusView.configure(mastodonStatus: status)
        }
        
        self.delegate = delegate
        updateSeparatorInset()
    }
}
