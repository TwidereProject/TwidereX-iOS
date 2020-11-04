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

final class SearchMediaViewController: UIViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: SearchMediaViewModel!

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: SearchMediaViewController.createCollectionViewLayout())
        collectionView.register(SearchMediaCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: SearchMediaCollectionViewCell.self))
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
        
        collectionView.delegate = self
        viewModel.setupDiffableDataSource(collectionView: collectionView)
        
        viewModel.context.authenticationService.currentActiveTwitterAutentication
            .assign(to: \.value, on: viewModel.currentTwitterAuthentication)
            .store(in: &disposeBag)
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
            case MediaSection.loader.rawValue:
                let item = NSCollectionLayoutItem(
                    layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                       heightDimension: .fractionalHeight(1.0)))
                let group = NSCollectionLayoutGroup.vertical(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1.0),
                        heightDimension: .absolute(44.0)),
                    subitem: item,
                    count: 1
                )
                let section = NSCollectionLayoutSection(group: group)
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
extension SearchMediaViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        os_log("%{public}s[%{public}ld], %{public}s: select at indexPath: %s", ((#file as NSString).lastPathComponent), #line, #function, indexPath.description)

        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        let item = diffableDataSource.itemIdentifier(for: indexPath)
        switch item {
        case .photoTweet(let objectID, let attribute):
            let managedObjectContext = self.viewModel.fetchedResultsController.managedObjectContext
            managedObjectContext.performAndWait {
                guard let tweet = managedObjectContext.object(with: objectID) as? Tweet else { return }
                os_log("%{public}s[%{public}ld], %{public}s: select tweet: %s", ((#file as NSString).lastPathComponent), #line, #function, tweet.id)
            }

        default:
            return
        }
    }
}