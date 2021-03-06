//
//  SearchMediaViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-29.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack

final class SearchMediaViewController: UIViewController, MediaPreviewableViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: SearchMediaViewModel!
    
    let mediaPreviewTransitionController = MediaPreviewTransitionController()

    private(set) lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: SearchMediaViewController.createCollectionViewLayout())
        collectionView.register(SearchMediaCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: SearchMediaCollectionViewCell.self))
        collectionView.register(ActivityIndicatorCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: ActivityIndicatorCollectionViewCell.self))
        return collectionView
    }()
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
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
        
        collectionView.delegate = self
        viewModel.setupDiffableDataSource(collectionView: collectionView, mediaCollectionViewCellDelegate: self)
    }
    
}

extension SearchMediaViewController {
    
    static func createCollectionViewLayout() -> UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, layoutEnvironment -> NSCollectionLayoutSection? in
            switch sectionIndex {
            case MediaSection.main.rawValue:
                let columnCount: CGFloat = round(max(1.0, layoutEnvironment.container.effectiveContentSize.width / 200.0))
                let item = NSCollectionLayoutItem(
                    layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0 / columnCount),
                                                       heightDimension: .fractionalHeight(1.0)))
                item.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1.0),
                        heightDimension: .fractionalWidth(1.0 / columnCount)),
                    subitem: item,
                    count: Int(columnCount)
                )
                let section = NSCollectionLayoutSection(group: group)
                if #available(iOS 14.0, *) {
                    section.contentInsetsReference = .readableContent
                } else {
                    // Fallback on earlier versions
                    // iOS 13 workaround
                    section.contentInsets.leading = 16
                    section.contentInsets.trailing = 16
                }
                return section
            case MediaSection.footer.rawValue:
                let item = NSCollectionLayoutItem(
                    layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                       heightDimension: .estimated(60)))
                let group = NSCollectionLayoutGroup.horizontal(     // <- horizontal for self size
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1.0),
                        heightDimension: .estimated(60)),
                    subitem: item,
                    count: 1
                )
                let section = NSCollectionLayoutSection(group: group)
                if #available(iOS 14.0, *) {
                    section.contentInsetsReference = .readableContent
                } else {
                    // Fallback on earlier versions
                }
                return section
            default:
                assertionFailure()
                return nil
            }
        }
        return layout
    }
    
}

// MARK: - UIScrollViewDelegate
extension SearchMediaViewController {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === collectionView else { return }
        let cells = collectionView.visibleCells.compactMap { $0 as? ActivityIndicatorCollectionViewCell }
        guard let loaderCollectionViewCell = cells.first else { return }

        if let tabBar = tabBarController?.tabBar, let window = view.window {
            let loaderCollectionViewCellFrameInWindow = collectionView.convert(loaderCollectionViewCell.frame, to: nil)
            let windowHeight = window.frame.height
            let loaderAppear = (loaderCollectionViewCellFrameInWindow.origin.y + 0.8 * loaderCollectionViewCell.frame.height) < (windowHeight - tabBar.frame.height)
            if loaderAppear {
                viewModel.stateMachine.enter(SearchMediaViewModel.State.Loading.self)
            }
        } else {
            viewModel.stateMachine.enter(SearchMediaViewModel.State.Loading.self)
        }
    }
}

// MARK: - UICollectionViewDelegate
extension SearchMediaViewController: UICollectionViewDelegate { }

// MARK: - MediaCollectionViewCellDelegate
extension SearchMediaViewController: MediaCollectionViewCellDelegate {
    
    func mediaCollectionViewCell(_ cell: SearchMediaCollectionViewCell, collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // discard nest collectionView and indexPath
        guard let indexPath = self.collectionView.indexPath(for: cell) else { return }
        handleCollectionView(self.collectionView, didSelectItemAt: indexPath)
    }
    
}
