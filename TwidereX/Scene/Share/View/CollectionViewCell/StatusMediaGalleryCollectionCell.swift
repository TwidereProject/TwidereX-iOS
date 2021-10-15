//
//  StatusMediaGalleryCollectionCell.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-14.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import Combine
import TabBarPager
import CoverFlowStackCollectionViewLayout

final class StatusMediaGalleryCollectionCell: UICollectionViewCell {
    
    var disposeBag = Set<AnyCancellable>()
    private(set) lazy var viewModel: ViewModel = {
        let viewModel = ViewModel()
        viewModel.bind(cell: self)
        return viewModel
    }()

    let mediaView = MediaView()
    
    let collectionViewLayout: CoverFlowStackCollectionViewLayout = {
        let layout = CoverFlowStackCollectionViewLayout()
        layout.startTrailingMarginRatio = 0.05
        layout.endTrailingMarginRatio = 0.10
        return layout
    }()
    private(set) lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        collectionView.backgroundColor = .clear
        collectionView.layer.masksToBounds = true
        collectionView.layer.cornerRadius = MediaView.cornerRadius
        collectionView.layer.cornerCurve = .continuous
        return collectionView
    }()
    var diffableDataSource: UICollectionViewDiffableDataSource<CoverFlowStackSection, CoverFlowStackItem>?
        
    override func prepareForReuse() {
        super.prepareForReuse()
    
        disposeBag.removeAll()
        mediaView.prepareForReuse()
        diffableDataSource?.applySnapshotUsingReloadData(.init())
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension StatusMediaGalleryCollectionCell {
    
    private func _init() {        
        mediaView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(mediaView)
        NSLayoutConstraint.activate([
            mediaView.topAnchor.constraint(equalTo: contentView.topAnchor),
            mediaView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            mediaView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            mediaView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: contentView.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
        
        let configuration = CoverFlowStackSection.Configuration()
        diffableDataSource = CoverFlowStackSection.diffableDataSource(
            collectionView: collectionView,
            configuration: configuration
        )
    }
    
}
