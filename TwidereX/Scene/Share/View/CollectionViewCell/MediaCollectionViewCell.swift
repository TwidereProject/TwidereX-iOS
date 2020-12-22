//
//  MediaCollectionViewCell.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-29.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit

protocol MediaCollectionViewCellDelegate: class {
    func mediaCollectionViewCell(_ cell: SearchMediaCollectionViewCell, collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
}

final class SearchMediaCollectionViewCell: UICollectionViewCell {
    
    weak var delegate: MediaCollectionViewCellDelegate?
    
    lazy var previewCollectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createCollectionViewLayout())
        collectionView.register(MediaPreviewCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: MediaPreviewCollectionViewCell.self))
        collectionView.backgroundColor = .systemFill
        collectionView.layer.masksToBounds = true
        collectionView.layer.cornerRadius = 8
        return collectionView
    }()
    
    let multiplePhotosIndicatorBackgroundVisualEffectView: UIVisualEffectView = {
        let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterialDark))
        visualEffectView.layer.masksToBounds = true
        visualEffectView.layer.cornerRadius = 4
        return visualEffectView
    }()
    let multiplePhotosIndicatorImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = Asset.ObjectTools.photos.image.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = .white
        return imageView
    }()
    
    var diffableDataSource: UICollectionViewDiffableDataSource<Section, Item>!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        multiplePhotosIndicatorBackgroundVisualEffectView.isHidden = true
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
        
        multiplePhotosIndicatorBackgroundVisualEffectView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(multiplePhotosIndicatorBackgroundVisualEffectView)
        NSLayoutConstraint.activate([
            contentView.trailingAnchor.constraint(equalTo: multiplePhotosIndicatorBackgroundVisualEffectView.trailingAnchor, constant: 4),
            contentView.bottomAnchor.constraint(equalTo: multiplePhotosIndicatorBackgroundVisualEffectView.bottomAnchor, constant: 4),
        ])
        
        multiplePhotosIndicatorImageView.translatesAutoresizingMaskIntoConstraints = false
        multiplePhotosIndicatorBackgroundVisualEffectView.contentView.addSubview(multiplePhotosIndicatorImageView)
        NSLayoutConstraint.activate([
            multiplePhotosIndicatorImageView.topAnchor.constraint(equalTo: multiplePhotosIndicatorBackgroundVisualEffectView.topAnchor),
            multiplePhotosIndicatorImageView.leadingAnchor.constraint(equalTo: multiplePhotosIndicatorBackgroundVisualEffectView.leadingAnchor),
            multiplePhotosIndicatorBackgroundVisualEffectView.trailingAnchor.constraint(equalTo: multiplePhotosIndicatorImageView.trailingAnchor),
            multiplePhotosIndicatorBackgroundVisualEffectView.bottomAnchor.constraint(equalTo: multiplePhotosIndicatorImageView.bottomAnchor),
        ])
        
        previewCollectionView.delegate = self
        diffableDataSource = UICollectionViewDiffableDataSource(collectionView: previewCollectionView) { collectionView, indexPath, item -> UICollectionViewCell? in
            switch item {
            case .preview(let url):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: MediaPreviewCollectionViewCell.self), for: indexPath) as! MediaPreviewCollectionViewCell
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
        
        multiplePhotosIndicatorBackgroundVisualEffectView.isHidden = true
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.mediaCollectionViewCell(self, collectionView: collectionView, didSelectItemAt: indexPath)
    }
    
}
