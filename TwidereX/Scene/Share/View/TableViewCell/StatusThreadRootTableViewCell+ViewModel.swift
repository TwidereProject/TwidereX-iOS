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
import TwidereCore
import AppShared

extension StatusThreadRootTableViewCell {
    final class ViewModel {
        enum Value {
            case statusObject(StatusObject)
            case twitterStatus(TwitterStatus)
            case mastodonStatus(MastodonStatus)
        }
        
        let value: Value
        let activeAuthenticationContext: AnyPublisher<AuthenticationContext?, Never>
        
        init(
            value: Value,
            activeAuthenticationContext: AnyPublisher<AuthenticationContext?, Never>
        ) {
            self.value = value
            self.activeAuthenticationContext = activeAuthenticationContext
        }
    }
    
    func configure(
        tableView: UITableView,
        viewModel: StatusThreadRootTableViewCell.ViewModel,
        delegate: StatusViewTableViewCellDelegate?
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
        
        let configurationContext = StatusView.ConfigurationContext(
            dateTimeProvider: DateTimeSwiftProvider(),
            twitterTextProvider: OfficialTwitterTextProvider(),
            activeAuthenticationContext: viewModel.activeAuthenticationContext
        )
        
        switch viewModel.value {
        case .statusObject(let object):
            statusView.configure(
                statusObject: object,
                configurationContext: configurationContext
            )
        case .twitterStatus(let status):
            statusView.configure(
                twitterStatus: status,
                configurationContext: configurationContext
            )
        case .mastodonStatus(let status):
            statusView.configure(
                mastodonStatus: status,
                notification: nil,
                configurationContext: configurationContext
            )
        }
        
        
        statusView.viewModel.contentRevealChangePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak tableView] _ in
                guard let tableView = tableView else { return }
                UIView.setAnimationsEnabled(false)
                tableView.beginUpdates()
                tableView.endUpdates()
                UIView.setAnimationsEnabled(true)
            }
            .store(in: &disposeBag)
        
        self.delegate = delegate
    }
}
