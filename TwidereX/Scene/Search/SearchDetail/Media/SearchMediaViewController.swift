//
//  SearchMediaViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-29.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import Combine

final class SearchMediaViewController: UIViewController {
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: SearchMediaViewModel!

    
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createCollectionViewLayout())
        collectionView.register(SearchMediaPhotoCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: SearchMediaPhotoCollectionViewCell.self))
        collectionView.register(ActivityIndicatorCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: ActivityIndicatorCollectionViewCell.self))
        return collectionView
    }()
    
}

extension SearchMediaViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        collectionView.backgroundColor = .systemBackground
        
        viewModel.setupDiffableDataSource(collectionView: collectionView)
        var snapshot = NSDiffableDataSourceSnapshot<SearchMediaViewModel.SearchMediaSection, SearchMediaViewModel.SearchMediaItem>()
        snapshot.appendSections([.main, .loader])
        snapshot.appendItems([], toSection: .main)
        snapshot.appendItems([.bottomLoader], toSection: .loader)
        viewModel.diffableDataSource.apply(snapshot)
    }
    
}

extension SearchMediaViewController {
    
    private func createCollectionViewLayout() -> UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, layoutEnvironment -> NSCollectionLayoutSection? in
            let columnCount: CGFloat = {
                switch sectionIndex {
                case SearchMediaViewModel.SearchMediaSection.main.rawValue:
                    return round(max(1.0, layoutEnvironment.container.effectiveContentSize.width / 200.0))
                case SearchMediaViewModel.SearchMediaSection.loader.rawValue:
                    return 1.0
                default:
                    assertionFailure()
                    return 1.0
                }
            }()
            let item = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0 / columnCount),
                                                   heightDimension: .fractionalHeight(1.0)))
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .fractionalHeight(1.0)),
                subitem: item,
                count: Int(columnCount)
            )
            let section = NSCollectionLayoutSection(group: group)
            return section
        }
        return layout
    }
    
}
