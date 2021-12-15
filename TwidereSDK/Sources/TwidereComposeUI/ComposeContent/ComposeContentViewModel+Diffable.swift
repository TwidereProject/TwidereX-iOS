//
//  ComposeContentViewModel+Diffable.swift
//  AppShared
//
//  Created by MainasuK on 2021/11/17.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import Combine
import TwidereCore
import TwidereUI
import MetaTextKit

extension ComposeContentViewModel {
    public enum Section: Hashable {
        case main
    }
    
    public enum Item: Int, Comparable, Hashable, CaseIterable {
        case replyTo
        case input
        case quote
        case attachment
        case poll
        
        public static func < (lhs: ComposeContentViewModel.Item, rhs: ComposeContentViewModel.Item) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
    }
}

extension ComposeContentViewModel {
    public func setupDiffableDataSource(
        tableView: UITableView,
        customEmojiPickerInputView: CustomEmojiPickerInputView,
        composeInputTableViewCellDelegate: ComposeInputTableViewCellDelegate & MetaTextDelegate & UITextViewDelegate,
        composeAttachmentTableViewCellDelegate: ComposeAttachmentTableViewCellDelegate,
        composePollTableViewCellDelegate: ComposePollTableViewCellDelegate
    ) {
        // set delegate
        composeInputTableViewCell.delegate = composeInputTableViewCellDelegate
        composeInputTableViewCell.contentMetaText.delegate = composeInputTableViewCellDelegate
        composeInputTableViewCell.contentMetaText.textView.delegate = composeInputTableViewCellDelegate
        composeInputTableViewCell.contentWarningMetaText.delegate = composeInputTableViewCellDelegate
        composeInputTableViewCell.contentWarningMetaText.textView.delegate = composeInputTableViewCellDelegate
        composeAttachmentTableViewCell.delegate = composeAttachmentTableViewCellDelegate
        composePollTableViewCell.delegate = composePollTableViewCellDelegate
        
        // configure emoji picker
        customEmojiPickerInputViewModel.customEmojiPickerInputView = customEmojiPickerInputView
        
        // setup custom emoji data source
        customEmojiPickerInputView.collectionView.register(CustomEmojiPickerItemCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: CustomEmojiPickerItemCollectionViewCell.self))
        customEmojiPickerInputView.collectionView.register(CustomEmojiPickerHeaderCollectionReusableView.self, forSupplementaryViewOfKind: String(describing: CustomEmojiPickerHeaderCollectionReusableView.self), withReuseIdentifier: String(describing: CustomEmojiPickerHeaderCollectionReusableView.self))
        customEmojiDiffableDataSource = UICollectionViewDiffableDataSource(collectionView: customEmojiPickerInputView.collectionView) { collectionView, indexPath, item in
            switch item {
            case .emoji(let emoji):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: CustomEmojiPickerItemCollectionViewCell.self), for: indexPath) as! CustomEmojiPickerItemCollectionViewCell
                let url = URL(string: emoji.url)
                cell.emojiImageView.sd_setImage(
                    with: url,
                    placeholderImage: CustomEmojiPickerItemCollectionViewCell.placeholder,
                    options: [],
                    context: nil
                )
                cell.accessibilityLabel = emoji.shortcode
                return cell
            }
        }
        
        customEmojiDiffableDataSource?.supplementaryViewProvider = { [weak customEmojiDiffableDataSource] collectionView, kind, indexPath -> UICollectionReusableView? in
            guard let dataSource = customEmojiDiffableDataSource else { return nil }
            let sections = dataSource.snapshot().sectionIdentifiers
            guard indexPath.section < sections.count else { return nil }
            let section = sections[indexPath.section]
            
            switch kind {
            case String(describing: CustomEmojiPickerHeaderCollectionReusableView.self):
                let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: String(describing: CustomEmojiPickerHeaderCollectionReusableView.self), for: indexPath) as! CustomEmojiPickerHeaderCollectionReusableView
                switch section {
                case .section(let category):
                    header.titleLabel.text = category
                }
                return header
            default:
                assertionFailure()
                return nil
            }
        }
        
        $emojiViewModel
            .sink { [weak self] emojiViewModel in
                guard let self = self else { return }
                guard let dataSource = self.customEmojiDiffableDataSource else { return }
                
                guard let emojiViewModel = emojiViewModel else {
                    self.emojiViewModelSubscription = nil
                    let snapshot = NSDiffableDataSourceSnapshot<CustomEmojiPickerInputView.ViewModel.Section, CustomEmojiPickerInputView.ViewModel.Item>()
                    dataSource.apply(snapshot)
                    return
                }
                
                self.emojiViewModelSubscription = emojiViewModel.$emojis
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] emojis in
                        guard let self = self else { return }
                        guard let dataSource = self.customEmojiDiffableDataSource else { return }
                        
                        var snapshot = NSDiffableDataSourceSnapshot<CustomEmojiPickerInputView.ViewModel.Section, CustomEmojiPickerInputView.ViewModel.Item>()
                        let categoryCollection = emojis.asCategoryCollection
                        // unindexed
                        if !categoryCollection.unindexed.isEmpty {
                            let section = CustomEmojiPickerInputView.ViewModel.Section.section(category: emojiViewModel.domain)
                            snapshot.appendSections([section])
                            let items = categoryCollection.unindexed.map {
                                CustomEmojiPickerInputView.ViewModel.Item.emoji(emoji: $0)
                            }
                            snapshot.appendItems(items, toSection: section)
                        }
                        // indexed
                        for (category, indexed) in categoryCollection.orderedDictionary {
                            let section = CustomEmojiPickerInputView.ViewModel.Section.section(category: category)
                            snapshot.appendSections([section])
                            let items = indexed.map {
                                CustomEmojiPickerInputView.ViewModel.Item.emoji(emoji: $0)
                            }
                            snapshot.appendItems(items, toSection: section)
                        }
                        dataSource.apply(snapshot)
                    }
            }
            .store(in: &disposeBag)
        
        // setup data source
        diffableDataSource = UITableViewDiffableDataSource(tableView: tableView) { [weak self] tableView, indexPath, item in
            // data source should dispatch in main thread
            assert(Thread.isMainThread)
            
            guard let self = self else { return UITableViewCell() }
            return self.cell(for: item, tableView: tableView, at: indexPath)
        }
                
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items.sorted(), toSection: .main)
        
        diffableDataSource?.applySnapshotUsingReloadData(snapshot, completion: nil)
        
        $items
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                guard let self = self else { return }
                guard let diffableDataSource = self.diffableDataSource else { return }
                var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
                snapshot.appendSections([.main])
                let sortedItems = items.sorted()
                snapshot.appendItems(sortedItems, toSection: .main)
                diffableDataSource.apply(snapshot)
            }
            .store(in: &disposeBag)
    }
    
    private func cell(for item: Item, tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        switch item {
        case .replyTo:
            guard let status = self.replyTo else {
                assertionFailure()
                return UITableViewCell()
            }
            composeReplyTableViewCell.prepareForReuse()
            composeReplyTableViewCell.configure(
                tableView: tableView,
                viewModel: ComposeReplyTableViewCell.ViewModel(
                    status: status,
                    statusViewConfigureContext: StatusView.ConfigurationContext(
                        dateTimeProvider: configurationContext.dateTimeProvider,
                        twitterTextProvider: configurationContext.twitterTextProvider,
                        activeAuthenticationContext: Just(nil).eraseToAnyPublisher()
                    )
                )
            )
            return composeReplyTableViewCell
        case .input:
            composeInputTableViewCell.conversationLinkLineView.isHidden = replyTo == nil
            let contentWarningMetaContent = Meta.convert(from: .mastodon(string: currentContentWarningInput, emojis: emojiViewModel?.emojis.asDictionary ?? [:]))
            composeInputTableViewCell.contentWarningMetaText.configure(content: contentWarningMetaContent)
            customEmojiPickerInputViewModel.configure(textInput: composeInputTableViewCell.contentWarningMetaText.textView)
            customEmojiPickerInputViewModel.configure(textInput: composeInputTableViewCell.contentMetaText.textView)
            
            return composeInputTableViewCell
        case .quote:
            let cell = UITableViewCell()
            cell.backgroundColor = .yellow
            return cell
        case .attachment:
            return composeAttachmentTableViewCell
        case .poll:
            composePollTableViewCell.customEmojiPickerInputViewModel = customEmojiPickerInputViewModel
            return composePollTableViewCell
        }
    }
}
