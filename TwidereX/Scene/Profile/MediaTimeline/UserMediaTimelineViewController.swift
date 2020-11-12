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

final class UserMediaTimelineViewController: UIViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: UserMediaTimelineViewModel!
    
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: SearchMediaViewController.createCollectionViewLayout())
        collectionView.register(SearchMediaCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: SearchMediaCollectionViewCell.self))
        collectionView.register(ActivityIndicatorCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: ActivityIndicatorCollectionViewCell.self))
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
        viewModel.setupDiffableDataSource(collectionView: collectionView)
        
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
extension UserMediaTimelineViewController: UICollectionViewDelegate {
    
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

// MARK: - CustomScrollViewContainerController
extension UserMediaTimelineViewController: CustomScrollViewContainerController {
    var scrollView: UIScrollView {
        return collectionView
    }
}
