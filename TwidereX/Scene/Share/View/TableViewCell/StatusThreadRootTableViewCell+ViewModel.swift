//
//  StatusThreadRootTableViewCell+ViewModel.swift
//  StatusThreadRootTableViewCell+ViewModel
//
//  Created by Cirno MainasuK on 2021-8-30.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import Combine
import SwiftUI
import CoreDataStack

extension StatusThreadRootTableViewCell {
    final class ViewModel {
        enum Value {
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
        viewModel: StatusThreadRootTableViewCell.ViewModel,
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
        case .twitterStatus(let status):
            statusView.configure(twitterStatus: status)
        case .mastodonStatus(let status):
            statusView.configure(mastodonStatus: status)
        }
        
        self.delegate = delegate
    }
}
