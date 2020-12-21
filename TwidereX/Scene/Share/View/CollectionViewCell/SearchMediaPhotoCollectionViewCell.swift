//
//  SearchMediaCollectionViewCell.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-29.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit

final class SearchMediaCollectionViewCell: UICollectionViewCell {
    
    lazy var previewCollectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createCollectionViewLayout())
        collectionView.register(SearchMediaPreviewCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: SearchMediaPreviewCollectionViewCell.self))
        return collectionView
    }()
    
    var diffableDataSource: UICollectionViewDiffableDataSource<Section, Item>!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        diffableDataSource.apply(NSDiffableDataSourceSnapshot())
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

extension SearchMediaCollectionViewCell {
    
    private func _init() {
        previewCollectionView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(previewCollectionView)
        NSLayoutConstraint.activate([
            previewCollectionView.topAnchor.constraint(equalTo: contentView.topAnchor),
            previewCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            previewCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            previewCollectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
        
        previewCollectionView.delegate = self
        diffableDataSource = UICollectionViewDiffableDataSource(collectionView: previewCollectionView) { collectionView, indexPath, item -> UICollectionViewCell? in
            switch item {
            case .preview(let url):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: SearchMediaPreviewCollectionViewCell.self), for: indexPath) as! SearchMediaPreviewCollectionViewCell
                let placeholderImage = UIImage.placeholder(color: .systemFill)
                if let url = url {
                    cell.previewImageView.af.setImage(
                        withURL: url,
                        placeholderImage: placeholderImage,
                        imageTransition: .crossDissolve(0.2)
                    )
                } else {
                    cell.previewImageView.image = placeholderImage
                }
                return cell
            }
        }
    }
    
}

extension SearchMediaCollectionViewCell {
    private func createCollectionViewLayout() -> UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, layoutEnvironment -> NSCollectionLayoutSection? in
            let item = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                   heightDimension: .fractionalHeight(1.0)))
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .fractionalHeight(1.0)),
                subitems: [item]
            )
            let section = NSCollectionLayoutSection(group: group)
            section.orthogonalScrollingBehavior = .groupPaging
            return section
        }
        return layout
    }
}

extension SearchMediaCollectionViewCell {
    enum Section: Hashable {
        case main
    }
    
    enum Item: Hashable {
        case preview(url: URL?)
    }
}


// MARK: - UICollectionViewDelegate
extension SearchMediaCollectionViewCell: UICollectionViewDelegate {
    
}
