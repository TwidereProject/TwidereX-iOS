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
    static func diffableDataSource(
        collectionView: UICollectionView,
        context: AppContext
    ) -> UICollectionViewDiffableDataSource<StatusSection, StatusItem> {
        let cellRegistrationForTwitterStatus = UICollectionView.CellRegistration<StatusCollectionViewCell, TwitterStatus> { cell, indexPath, status in
            configure(statusView: cell.statusView, status: status, disposeBag: &cell.disposeBag)
        }

        return UICollectionViewDiffableDataSource<StatusSection, StatusItem>(
            collectionView: collectionView
        ) { collectionView, indexPath, item in
            // data source should dispatch in main thread
            assert(Thread.isMainThread)
            // configure cell with item
            switch item {
            case .homeTimelineFeed(let objectID):
                guard let feed = try? context.managedObjectContext.existingObject(with: objectID) as? Feed,
                      let status = feed.twitterStatus
                else {
                    assertionFailure()
                    return UICollectionViewCell()
                }
                return collectionView.dequeueConfiguredReusableCell(
                    using: cellRegistrationForTwitterStatus,
                    for: indexPath,
                    item: status
                )
                
            case .twitterStatus(let objectID):
                guard let status = try? context.managedObjectContext.existingObject(with: objectID) as? TwitterStatus
                else {
                    assertionFailure()
                    return UICollectionViewCell()
                }
                return collectionView.dequeueConfiguredReusableCell(
                    using: cellRegistrationForTwitterStatus,
                    for: indexPath,
                    item: status
                )
            }
        }
    }
}

extension StatusSection {

    static func configure(
        statusView: StatusView,
        status: TwitterStatus,
        disposeBag: inout Set<AnyCancellable>
    ) {
        configureAuthor(statusView: statusView, status: status, disposeBag: &disposeBag)
        configureContent(statusView: statusView, status: status, disposeBag: &disposeBag)
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
        // statusView.authorNameLabel.configure(content: PlaintextMetaContent(string: " "))
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
        // statusView.authorUsernameLabel.text = " "
        Publishers.CombineLatest(
            author.publisher(for: \.username),
            NotificationCenter.default.publisher(for: UIContentSizeCategory.didChangeNotification).map { _ in }.prepend(Void())
        )
            .map { text, _ in "@\(text)" }
            .assign(to: \.text, on: statusView.authorUsernameLabel)
            .store(in: &disposeBag)
    }
    
    static func configureContent(
        statusView: StatusView,
        status: TwitterStatus,
        disposeBag: inout Set<AnyCancellable>
    ) {
        // status content
        let attributedString = NSAttributedString(
            string: status.text,
            attributes: [
                .font: UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 14, weight: .regular)),
                .foregroundColor: UIColor.label
            ]
        )
        statusView.contentTextView.setAttributedString(attributedString)
    }
    
}
