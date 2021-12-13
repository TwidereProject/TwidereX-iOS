//
//  ProfileFieldListView.swift
//  ProfileFieldListView
//
//  Created by Cirno MainasuK on 2021-9-10.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import MetaTextKit
import Meta

protocol ProfileFieldListViewDelegate: AnyObject {
    func profileFieldListView(_ profileFieldListView: ProfileFieldListView, profileFieldCollectionViewCell: ProfileFieldCollectionViewCell, profileFieldContentView: ProfileFieldContentView, metaLabel: MetaLabel, didSelectMeta meta: Meta)
}

final class ProfileFieldListView: UIView {
    
    let logger = Logger(subsystem: "ProfileFieldListView", category: "View")
    
    weak var delegate: ProfileFieldListViewDelegate?

    var collectionViewHeightLayoutConstraint: NSLayoutConstraint!
    var collectionViewHeightObservation: NSKeyValueObservation?
    let collectionView: UICollectionView = {
        var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
        configuration.showsSeparators = false
        let collectionViewLayout = UICollectionViewCompositionalLayout.list(using: configuration)
        let frame = CGRect(x: 0, y: 0, width: 100, height: 100)     // required for AutoLayout
        let collectionView = UICollectionView(frame: frame, collectionViewLayout: collectionViewLayout)
        collectionView.isScrollEnabled = false                      // required for AutoLayout
        return collectionView
    }()
    var dataSource: UICollectionViewDiffableDataSource<Section, Item>!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension ProfileFieldListView {
    enum Section: Hashable {
        case main
    }
    
    struct Item: Hashable {
        let index: Int
        let updateAt: Date
        
        let symbol: UIImage?
        let key: MetaContent?
        let value: MetaContent?
        
        
        static func == (lhs: Item, rhs: Item) -> Bool {
            return lhs.index == rhs.index
                && lhs.updateAt == rhs.updateAt
                && lhs.symbol == rhs.symbol
                && lhs.key?.string == rhs.key?.string
                && lhs.value?.string == rhs.value?.string
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(index)
            hasher.combine(updateAt)
            hasher.combine(symbol)
            key.flatMap { hasher.combine($0.string) }
            value.flatMap { hasher.combine($0.string) }
        }
    }
}

extension ProfileFieldListView {
    private func _init() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(collectionView)
        collectionViewHeightLayoutConstraint = collectionView.heightAnchor.constraint(equalToConstant: 44).priority(.defaultHigh)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
            collectionViewHeightLayoutConstraint,
        ])
        collectionViewHeightObservation = collectionView.observe(\.contentSize, options: .new, changeHandler: { [weak self] collectionView, _ in
            guard let self = self else { return }
            guard collectionView.contentSize.height != .zero else {
                self.collectionViewHeightLayoutConstraint.constant = 44
                return
            }
            self.collectionViewHeightLayoutConstraint.constant = collectionView.contentSize.height
        })
        
        let cellRegistration = UICollectionView.CellRegistration<ProfileFieldCollectionViewCell, Item> { [weak self] (cell, indexPath, item) in
            guard let self = self else { return }
            cell.item = item
            cell.setNeedsUpdateConfiguration()
            cell.delegate = self
        }
        
        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item in
            let cell = collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
            cell.delegate = self
            return cell
        }
    }
}

extension ProfileFieldListView {
    func configure(items: [Item]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items, toSection: .main)
        dataSource.applySnapshotUsingReloadData(snapshot) { [weak self] in
            guard let self = self else { return }
            self.collectionView.sizeToFit()
        }
    }
}

// MARK: - ProfileFieldCollectionViewCellDelegate
extension ProfileFieldListView: ProfileFieldCollectionViewCellDelegate {
    func profileFieldCollectionViewCell(_ cell: ProfileFieldCollectionViewCell, profileFieldContentView: ProfileFieldContentView, metaLabel: MetaLabel, didSelectMeta meta: Meta) {
        delegate?.profileFieldListView(self, profileFieldCollectionViewCell: cell, profileFieldContentView: profileFieldContentView, metaLabel: metaLabel, didSelectMeta: meta)
    }
}
