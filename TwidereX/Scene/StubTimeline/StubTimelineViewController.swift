//
//  StubTimelineViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-8-2.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import Combine

final class StubTimelineViewController: UIViewController {
    
    var disposeBag = Set<AnyCancellable>()
    
    private(set) lazy var viewModel = StubTimelineViewModel()
    
    private(set) lazy var collectionView: UICollectionView = {
        let layoutConfiguration = UICollectionLayoutListConfiguration(appearance: .plain)
        let layout = UICollectionViewCompositionalLayout.list(using: layoutConfiguration)
        let collectionView = ContentOffsetFixedCollectionView(frame: .zero, collectionViewLayout: layout)
        return collectionView
    }()
    
    private(set) lazy var refreshControl = UIRefreshControl()
    
    
    
}

extension StubTimelineViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        collectionView.backgroundColor = .systemBackground
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.frame = view.bounds
        view.addSubview(collectionView)
        viewModel.setupDiffableDataSource(collectionView: collectionView)
        
        collectionView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(StubTimelineViewController.refreshControlValueDidChanged(_:)), for: .valueChanged)
        viewModel.didLoadLatest
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self = self else { return }
                self.refreshControl.endRefreshing()
            }
            .store(in: &disposeBag)
    }
    
}

extension StubTimelineViewController {
    @objc private func refreshControlValueDidChanged(_ sender: UIRefreshControl) {
        Task(priority: .userInitiated) {
            await self.viewModel.loadLatest()
        }
    }
}

