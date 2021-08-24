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

    static func diffableDataSource(
        tableView: UITableView,
        context: AppContext
    ) -> UITableViewDiffableDataSource<StatusSection, StatusItem> {
        return UITableViewDiffableDataSource<StatusSection, StatusItem>(
            tableView: tableView
        ) { tableView, indexPath, item in
            // data source should dispatch in main thread
            assert(Thread.isMainThread)
            
            // configure cell with item
            switch item {
            case .homeTimelineFeed(let record):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: StatusTableViewCell.self), for: indexPath) as! StatusTableViewCell
                context.managedObjectContext.performAndWait {
                    guard let feed = record.object(in: context.managedObjectContext) else { return }
                    if let status = feed.twitterStatus {
                        configure(tableView: tableView, statusView: cell.statusView, status: status, disposeBag: &cell.disposeBag)
                    } else {
                        assertionFailure()
                    }
                }
                return cell

            case .twitterStatus(let record):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: StatusTableViewCell.self), for: indexPath) as! StatusTableViewCell
                context.managedObjectContext.performAndWait {
                    guard let status = record.object(in: context.managedObjectContext) else { return }
                    configure(tableView: tableView, statusView: cell.statusView, status: status, disposeBag: &cell.disposeBag)
                }
                return cell
            }
        }
    }
}

extension StatusSection {

    static func configure(
        tableView: UITableView,
        statusView: StatusView,
        status: TwitterStatus,
        disposeBag: inout Set<AnyCancellable>
    ) {
        if statusView.frame == .zero {
            statusView.frame.size.width = tableView.readableContentGuide.layoutFrame.width
            statusView.contentTextView.preferredMaxLayoutWidth = statusView.contentMaxLayoutWidth
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): layout new cell")
        }
        configureHeader(statusView: statusView, status: status, disposeBag: &disposeBag)
        configureAuthor(statusView: statusView, status: status, disposeBag: &disposeBag)
        configureContent(statusView: statusView, status: status, disposeBag: &disposeBag)
        configureMedia(statusView: statusView, status: status, disposeBag: &disposeBag)
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
            let attributedString = NSAttributedString(
                string: content,
                attributes: [
                    .font: UIFont.preferredFont(forTextStyle: .body),
                    .foregroundColor: UIColor.label
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
        
        for (i, (attachment, mediaView)) in zip(attachments, mediaViews).enumerated() {
            guard i < MediaGridContainerView.maxCount else { break }
            switch attachment.kind {
            case .photo:
                mediaView.configure(imageURL: attachment.assetURL)
            case .video:
                break
            case .animatedGIF:
                break
            }
        }
    }
}
