//
//  ComposeReplyTableViewCell+ViewModel.swift
//  
//
//  Created by MainasuK on 2021/11/22.
//

import UIKit
import TwidereCore

extension ComposeReplyTableViewCell {
    public struct ViewModel {
        public let status: StatusObject
        public let statusViewConfigureContext: StatusView.ConfigurationContext
        
        public init(
            status: StatusObject,
            statusViewConfigureContext: StatusView.ConfigurationContext
        ) {
            self.status = status
            self.statusViewConfigureContext = statusViewConfigureContext
        }
    }
}

extension ComposeReplyTableViewCell {
    public func configure(
        tableView: UITableView,
        viewModel: ViewModel
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
        
        switch viewModel.status {
        case .twitter(let status):
            statusView.configure(
                twitterStatus: status,
                configurationContext: viewModel.statusViewConfigureContext
            )
        case .mastodon(let status):
            statusView.configure(
                mastodonStatus: status,
                notification: nil,
                configurationContext: viewModel.statusViewConfigureContext
            )
        }   
    }
}
