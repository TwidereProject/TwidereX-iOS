//
//  TimelineViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-1.
//

import os.log
import UIKit
import Combine

final class TimelineViewController: UIViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    private(set) lazy var viewModel = TimelineViewModel(context: context)
    
    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.register(TimelineCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: TimelineCollectionViewCell.self))
        return collectionView
    }()
}

extension TimelineViewController {
    
    private func createLayout() -> UICollectionViewLayout {
        let estimatedHeight = CGFloat(100)
        let layoutSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                heightDimension: .estimated(estimatedHeight))
        let item = NSCollectionLayoutItem(layoutSize: layoutSize)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: layoutSize,
                                                       subitem: item,
                                                       count: 1)
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        section.interGroupSpacing = 10
        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }
}

extension TimelineViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Timeline"
        view.backgroundColor = .systemBackground
        
        #if DEBUG
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Fetch", style: .plain, target: self, action: #selector(TimelineViewController.fetchBarButtonItemPressed(_:)))
        #endif
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        collectionView.backgroundColor = .systemBackground
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor)
        ])
        
        viewModel.collectionView = collectionView
        viewModel.setupDiffableDataSource(for: collectionView)
        collectionView.delegate = self
        do {
            try viewModel.fetchedResultsController.performFetch()
        } catch {
            assertionFailure(error.localizedDescription)
        }
        collectionView.dataSource = viewModel.diffableDataSource
        collectionView.reloadData()
        
        context.authenticationService.twitterAuthentications
            .map { $0.first }
            .assign(to: \.value, on: viewModel.currentTwitterAuthentication)
            .store(in: &disposeBag)
    }
}

extension TimelineViewController {
    #if DEBUG
    @objc private func fetchBarButtonItemPressed(_ sender: UIBarButtonItem) {
        guard let twitterAuthentication = viewModel.currentTwitterAuthentication.value else {
            assertionFailure()
            return
        }
        context.apiService.twitterHomeTimeline(twitterAuthentication: twitterAuthentication)
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveSubscription:  { [weak self] _ in
                self?.navigationItem.leftBarButtonItem?.isEnabled = false
            })
            .sink { [weak self] completion in
                self?.navigationItem.leftBarButtonItem?.isEnabled = true
                switch completion {
                case .failure(let error):
                    // TODO: handle error
                    os_log("%{public}s[%{public}ld], %{public}s: fetch tweets failed. %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                case .finished:
                    break
                }
            } receiveValue: { tweets in
                // do nothing
            }
            .store(in: &disposeBag)
    }
    #endif
}

// MARK: - UICollectionViewDelegate
extension TimelineViewController: UICollectionViewDelegate {
    
}
