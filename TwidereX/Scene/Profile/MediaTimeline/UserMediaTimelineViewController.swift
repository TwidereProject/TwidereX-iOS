//
//  UserMediaTimelineViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-4.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack

final class UserMediaTimelineViewController: UIViewController, MediaPreviewableViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    let mediaPreviewTransitionController = MediaPreviewTransitionController()

    var disposeBag = Set<AnyCancellable>()
    var viewModel: UserMediaTimelineViewModel!
    
    private(set) lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: SearchMediaViewController.createCollectionViewLayout())
        collectionView.register(SearchMediaCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: SearchMediaCollectionViewCell.self))
        collectionView.register(ActivityIndicatorCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: ActivityIndicatorCollectionViewCell.self))
        collectionView.register(TimelineHeaderCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: TimelineHeaderCollectionViewCell.self))
        return collectionView
    }()
    
}

extension UserMediaTimelineViewController {
    
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
        
        // trigger timeline loading
        viewModel.userID
            .removeDuplicates()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.viewModel.stateMachine.enter(UserMediaTimelineViewModel.State.Reloading.self)
            }
            .store(in: &disposeBag)
    }
    
}

// MARK: - UIScrollViewDelegate
extension UserMediaTimelineViewController {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === collectionView else { return }
        let cells = collectionView.visibleCells.compactMap { $0 as? ActivityIndicatorCollectionViewCell }
        guard let loaderCollectionViewCell = cells.first else { return }
        
        if let tabBar = tabBarController?.tabBar, let window = view.window {
            let loaderCollectionViewCellFrameInWindow = collectionView.convert(loaderCollectionViewCell.frame, to: nil)
            let windowHeight = window.frame.height
            let loaderAppear = (loaderCollectionViewCellFrameInWindow.origin.y + 0.8 * loaderCollectionViewCell.frame.height) < (windowHeight - tabBar.frame.height)
            if loaderAppear {
                viewModel.stateMachine.enter(UserMediaTimelineViewModel.State.LoadingMore.self)
            }
        } else {
            viewModel.stateMachine.enter(UserMediaTimelineViewModel.State.LoadingMore.self)
        }
    }
}

// MARK: - UICollectionViewDelegate
extension UserMediaTimelineViewController: UICollectionViewDelegate { }

// MARK: - CustomScrollViewContainerController
extension UserMediaTimelineViewController: ScrollViewContainer {
    var scrollView: UIScrollView { return collectionView }
}

// MARK: - MediaCollectionViewCellDelegate
extension UserMediaTimelineViewController: MediaCollectionViewCellDelegate {
    
    func mediaCollectionViewCell(_ cell: SearchMediaCollectionViewCell, collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // discard nest collectionView and indexPath
        guard let indexPath = self.collectionView.indexPath(for: cell) else { return }
        handleCollectionView(self.collectionView, didSelectItemAt: indexPath)
    }
    
}
