//
//  SidebarViewController.swift
//  TwidereX
//
//  Created by DTK on 2020-10-29.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit

@available(iOS 14.0, *)
final class SidebarViewController: UIViewController {
    
    private(set) lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createCollectionViewLayout())
        return collectionView
    }()
    private var dataSource: UICollectionViewDiffableDataSource<SidebarSection, SidebarItem>!

}

extension SidebarViewController {

    private enum SidebarSection: Int {
        case main
    }
    
    private struct SidebarItem: Identifiable, Hashable {
        let id: UUID
        let title: String
        let subtitle: String?
        let image: UIImage?
    }
}

extension SidebarViewController {

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
        
        setupDataSource()
    }
    
}

extension SidebarViewController {
 
    private func createCollectionViewLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { sectionIndex, layoutEnvironment -> NSCollectionLayoutSection? in
            var configuration = UICollectionLayoutListConfiguration(appearance: .sidebar)
            configuration.showsSeparators = false
            configuration.headerMode = .none
            
            let section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: layoutEnvironment)
            return section
        }
    }
    
    
    private func setupDataSource() {
        let rowRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, SidebarItem> { cell, indexPath, item in
            var contentConfiguration = UIListContentConfiguration.sidebarSubtitleCell()
            contentConfiguration.text = item.title
            contentConfiguration.secondaryText = item.subtitle
            contentConfiguration.image = item.image
            cell.contentConfiguration = contentConfiguration
        }
        
        dataSource = UICollectionViewDiffableDataSource<SidebarSection, SidebarItem>(collectionView: collectionView) { collectionView, indexPath, item -> UICollectionViewCell? in
            return collectionView.dequeueConfiguredReusableCell(using: rowRegistration, for: indexPath, item: item)
        }
        
        var snapshot = NSDiffableDataSourceSectionSnapshot<SidebarItem>()
        snapshot.append([
            SidebarItem(id: UUID(), title: "Timeline", subtitle: nil, image: UIImage(systemName: "house")!),
            SidebarItem(id: UUID(), title: "Me", subtitle: nil, image: UIImage(systemName: "person")!),
        ])
        dataSource.apply(snapshot, to: .main, animatingDifferences: false)
    }
    
}


// MARK: - UICollectionViewDelegate
extension SidebarViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let sidebarItem = dataSource.itemIdentifier(for: indexPath) else { return }
        
        
    }
}
