//
//  StatusSection.swift
//  StatusSection
//
//  Created by Cirno MainasuK on 2021-8-19.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack
import MetaTextKit

enum StatusSection: Hashable {
    case main
}

extension StatusSection {
    
    static let logger = Logger(subsystem: "StatusSection", category: "Logic")
    
    struct Configuration {
        let statusTableViewCellDelegate: StatusTableViewCellDelegate
    }

    static func diffableDataSource(
        tableView: UITableView,
        context: AppContext,
        configuration: Configuration
    ) -> UITableViewDiffableDataSource<StatusSection, StatusItem> {
        return UITableViewDiffableDataSource<StatusSection, StatusItem>(tableView: tableView) { tableView, indexPath, item in
            // data source should dispatch in main thread
            assert(Thread.isMainThread)
            
            // configure cell with item
            switch item {
            case .homeTimelineFeed(let record):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: StatusTableViewCell.self), for: indexPath) as! StatusTableViewCell
                context.managedObjectContext.performAndWait {
                    guard let feed = record.object(in: context.managedObjectContext) else { return }
                    if let status = feed.twitterStatus {
                        configure(tableView: tableView, cell: cell, status: status, configuration: configuration)
                    } else {
                        assertionFailure()
                    }
                }
                return cell

            case .twitterStatus(let record):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: StatusTableViewCell.self), for: indexPath) as! StatusTableViewCell
                context.managedObjectContext.performAndWait {
                    guard let status = record.object(in: context.managedObjectContext) else { return }
                    configure(tableView: tableView, cell: cell, status: status, configuration: configuration)
                }
                return cell
            }
        }
    }
}

extension StatusSection {
    
    static func configure(
        tableView: UITableView,
        cell: StatusTableViewCell,
        status: TwitterStatus,
        configuration: Configuration
    ) {
        if cell.statusView.frame == .zero {
            // set status view width
            cell.statusView.frame.size.width = tableView.readableContentGuide.layoutFrame.width
            let contentMaxLayoutWidth = cell.statusView.contentMaxLayoutWidth
            cell.statusView.quoteStatusView?.frame.size.width = contentMaxLayoutWidth
            // set preferredMaxLayoutWidth for content
            cell.statusView.contentTextView.preferredMaxLayoutWidth = contentMaxLayoutWidth
            cell.statusView.quoteStatusView?.contentTextView.preferredMaxLayoutWidth = cell.statusView.quoteStatusView?.contentMaxLayoutWidth
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): layout new cell")
        }
        configure(
            statusView: cell.statusView,
            status: status,
            configuration: configuration,
            disposeBag: &cell.disposeBag
        )
        cell.delegate = configuration.statusTableViewCellDelegate
        cell.updateSeparatorInset()
    }

    static func configure(
        statusView: StatusView,
        status: TwitterStatus,
        configuration: Configuration,
        disposeBag: inout Set<AnyCancellable>
    ) {
        configureHeader(statusView: statusView, status: status, disposeBag: &disposeBag)
        configureAuthor(statusView: statusView, status: status, disposeBag: &disposeBag)
        configureContent(statusView: statusView, status: status, disposeBag: &disposeBag)
        configureMedia(statusView: statusView, status: status, disposeBag: &disposeBag)
        configureToolbar(statusView: statusView, status: status, disposeBag: &disposeBag)
        
        if let quote = status.quote,
           let quoteStatusView = statusView.quoteStatusView {
            statusView.setQuoteDisplay()
            configure(
                statusView: quoteStatusView,
                status: quote,
                configuration: configuration,
                disposeBag: &disposeBag
            )
        }
    }
    
    static func configureHeader(
        statusView: StatusView,
        status: TwitterStatus,
        disposeBag: inout Set<AnyCancellable>
    ) {
        if let repost = status.repost {
            // repost icon
            statusView.headerIconImageView.image = Asset.Media.repeat.image
            // repost text
            Publishers.CombineLatest(
                repost.publisher(for: \.author.name),
                NotificationCenter.default.publisher(for: UIContentSizeCategory.didChangeNotification).map { _ in }.prepend(Void())
            )
            .map { text, _ -> PlaintextMetaContent in
                let userRepostText = L10n.Common.Controls.Status.userRetweeted(text)
                return PlaintextMetaContent(string: userRepostText)
            }
            .sink { metaContent in
                statusView.headerTextLabel.setupAttributes(style: StatusView.headerTextLabelStyle)
                statusView.headerTextLabel.configure(content: metaContent)
            }
            .store(in: &disposeBag)
            // set display
            statusView.setHeaderDisplay()
        }
    }
    
    static func configureAuthor(
        statusView: StatusView,
        status: TwitterStatus,
        disposeBag: inout Set<AnyCancellable>
    ) {
        let author = (status.repost ?? status).author
        
        // author avatar
        statusView.authorAvatarButton.avatarImageView.configure(
            configuration: .init(url: author.avatarImageURL())
        )
        
        // author name
        Publishers.CombineLatest(
            author.publisher(for: \.name),
            NotificationCenter.default.publisher(for: UIContentSizeCategory.didChangeNotification).map { _ in }.prepend(Void())
        )
        .map { text, _ in PlaintextMetaContent(string: text) }
        .sink { metaContent in
            statusView.authorNameLabel.setupAttributes(style: StatusView.authorNameLabelStyle)
            statusView.authorNameLabel.configure(content: metaContent)
        }
        .store(in: &disposeBag)
        
        // author username
        Publishers.CombineLatest(
            author.publisher(for: \.username),
            NotificationCenter.default.publisher(for: UIContentSizeCategory.didChangeNotification).map { _ in }.prepend(Void())
        )
        .map { text, _ in "@\(text)" }
        .assign(to: \.text, on: statusView.authorUsernameLabel)
        .store(in: &disposeBag)
        
        // timestamp
        let createdAt = (status.repost ?? status).createdAt
        statusView.timestampLabel.text = createdAt.shortTimeAgoSinceNow
        AppContext.shared.timestampUpdatePublisher
            .sink { _ in
                statusView.timestampLabel.text = createdAt.shortTimeAgoSinceNow
            }
            .store(in: &disposeBag)
    }
    
    static func configureContent(
        statusView: StatusView,
        status: TwitterStatus,
        disposeBag: inout Set<AnyCancellable>
    ) {
        let content = (status.repost ?? status).text
        func configureContent() {
            let textStyle = statusView.contentTextViewFontTextStyle ?? .body
            let textColor = statusView.contentTextViewTextColor ?? .label
            let attributedString = NSAttributedString(
                string: content,
                attributes: [
                    .font: UIFont.preferredFont(forTextStyle: textStyle),
                    .foregroundColor: textColor
                ]
            )
            statusView.contentTextView.setAttributedString(attributedString)
        }
        
        // status content
        configureContent()
        NotificationCenter.default.publisher(for: UIContentSizeCategory.didChangeNotification)
            .sink { _ in configureContent() }
            .store(in: &disposeBag)
    }
    
    static func configureMedia(
        statusView: StatusView,
        status: TwitterStatus,
        disposeBag: inout Set<AnyCancellable>
    ) {
        let maxSize = CGSize(
            width: statusView.contentMaxLayoutWidth,
            height: statusView.contentMaxLayoutWidth
        )
        var needsDisplay = true
        var mediaViews: [MediaView] = []
        let attachments = status.attachments
        switch attachments.count {
        case 0:
            needsDisplay = false
        case 1:
            let attachment = attachments[0]
            let aspectRatio = attachment.size
            let adaptiveLayout = MediaGridContainerView.AdaptiveLayout(aspectRatio: aspectRatio, maxSize: maxSize)
            let view = statusView.mediaGridContainerView.dequeueMediaView(adaptiveLayout: adaptiveLayout)
            mediaViews.append(view)
        default:
            let gridLayout = MediaGridContainerView.GridLayout(count: attachments.count, maxSize: maxSize)
            let views = statusView.mediaGridContainerView.dequeueMediaView(gridLayout: gridLayout)
            mediaViews.append(contentsOf: views)
        }
        
        guard needsDisplay else {
            return
        }
        statusView.setMediaDisplay()
        
        func videoInfo(from attachment: TwitterAttachment) -> MediaView.Configuration.VideoInfo {
            MediaView.Configuration.VideoInfo(
                assertURL: attachment.assetURL,
                previewURL: attachment.previewURL,
                durationMS: attachment.durationMS
            )
        }
        
        for (i, (attachment, mediaView)) in zip(attachments, mediaViews).enumerated() {
            guard i < MediaGridContainerView.maxCount else { break }
            switch attachment.kind {
            case .photo:
                mediaView.setup(configuration: MediaView.Configuration.image(url: attachment.assetURL))
            case .video:
                let info = videoInfo(from: attachment)
                mediaView.setup(configuration: MediaView.Configuration.video(info: info))
            case .animatedGIF:
                let info = videoInfo(from: attachment)
                mediaView.setup(configuration: MediaView.Configuration.gif(info: info))
            }
        }
    }
    
    static func configureToolbar(
        statusView: StatusView,
        status: TwitterStatus,
        disposeBag: inout Set<AnyCancellable>
    ) {
        let status = status.repost ?? status
        statusView.toolbar.setupReply(count: status.replyCount, isEnabled: true)
        statusView.toolbar.setupRepost(count: status.repostCount, isEnabled: true, isLocked: false)
        statusView.toolbar.setupLike(count: status.likeCount)
    }
}
