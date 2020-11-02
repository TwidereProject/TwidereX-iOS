//
//  SearchMediaViewModel.swift
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
import GameplayKit
import TwitterAPI

final class SearchMediaViewModel: NSObject {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let fetchedResultsController: NSFetchedResultsController<Tweet>
    let currentTwitterAuthentication: CurrentValueSubject<TwitterAuthentication?, Never>
    let searchMediaTweetIDs = CurrentValueSubject<[Twitter.Entity.Tweet.ID], Never>([])
    let searchText = CurrentValueSubject<String, Never>("")
    let searchActionPublisher = PassthroughSubject<Void, Never>()
    
    // output
    private(set) lazy var stateMachine: GKStateMachine = {
        let stateMachine = GKStateMachine(states: [
            State.Initial(viewModel: self),
            State.Idle(viewModel: self),
            State.Loading(viewModel: self),
            State.Fail(viewModel: self),
            State.NoMore(viewModel: self),
        ])
        stateMachine.enter(State.Initial.self)
        return stateMachine
    }()
    lazy var stateMachinePublisher = CurrentValueSubject<State, Never>(State.Initial(viewModel: self))
    var diffableDataSource: UICollectionViewDiffableDataSource<SearchMediaSection, SearchMediaItem>!
    let items = CurrentValueSubject<[SearchMediaItem], Never>([])
    
    init(context: AppContext) {
        self.context = context
        self.fetchedResultsController = {
            let fetchRequest = Tweet.sortedFetchRequest
            fetchRequest.predicate = Tweet.predicate(idStrs: [])
            fetchRequest.returnsObjectsAsFaults = false
            fetchRequest.fetchBatchSize = 20
            let controller = NSFetchedResultsController(
                fetchRequest: fetchRequest,
                managedObjectContext: context.managedObjectContext,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            
            return controller
        }()
        self.currentTwitterAuthentication = CurrentValueSubject(context.authenticationService.currentActiveTwitterAutentication.value)
        super.init()
        
        self.fetchedResultsController.delegate = self
        
        Publishers.CombineLatest(
            items.eraseToAnyPublisher(),
            stateMachinePublisher.eraseToAnyPublisher()
        )
        .throttle(for: .seconds(1), scheduler: DispatchQueue.main, latest: true)
        .receive(on: DispatchQueue.main)
        .sink { [weak self] items, state in
            guard let self = self else { return }
            os_log("%{public}s[%{public}ld], %{public}s: state did change", ((#file as NSString).lastPathComponent), #line, #function)
            
            var snapshot = NSDiffableDataSourceSnapshot<SearchMediaSection, SearchMediaItem>()
            snapshot.appendSections([.main])
            snapshot.appendItems(items)
            switch self.stateMachine.currentState {
            case is State.Fail:
                // TODO:
                break
            case is State.Initial, is State.NoMore:
                break
            case is State.Idle, is State.Loading:
                snapshot.appendSections([.loader])
                snapshot.appendItems([.bottomLoader], toSection: .loader)
            default:
                assertionFailure()
            }
            
            self.diffableDataSource?.apply(snapshot, animatingDifferences: true)
        }
        .store(in: &disposeBag)
        
        searchMediaTweetIDs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ids in
                guard let self = self else { return }
                self.fetchedResultsController.fetchRequest.predicate = Tweet.predicate(idStrs: ids)
                do {
                    try self.fetchedResultsController.performFetch()
                } catch {
                    assertionFailure(error.localizedDescription)
                }
            }
            .store(in: &disposeBag)
        
        searchActionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.stateMachine.enter(State.Loading.self)
            }
            .store(in: &disposeBag)
    }
    
}

// MARK: - NSFetchedResultsControllerDelegate
extension SearchMediaViewModel: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        
        guard diffableDataSource != nil else { return }
        let oldSnapshot = diffableDataSource.snapshot()
        
        var oldSnapshotAttributeDict: [NSManagedObjectID : SearchMediaItem.PhotoAttribute] = [:]
        for item in oldSnapshot.itemIdentifiers {
            guard case let .photo(objectID, attribute) = item else { continue }
            oldSnapshotAttributeDict[objectID] = attribute
        }
        
        // let snapshot = snapshot as NSDiffableDataSourceSnapshot<String, NSManagedObjectID>
        // guard snapshot.numberOfItems == searchMediaTweetIDs.value.count else { return }
        let tweets = fetchedResultsController.fetchedObjects ?? []
        guard tweets.count == searchMediaTweetIDs.value.count else { return }
        
        var items: [SearchMediaItem] = []
        for tweet in tweets {
            let mediaArray = Array(tweet.media ?? Set())
            let photoMedia = mediaArray.filter { $0.type == "photo" }
            guard !photoMedia.isEmpty else { continue }
            let attribute = oldSnapshotAttributeDict[tweet.objectID] ?? SearchMediaItem.PhotoAttribute(index: 0)
            let item = SearchMediaItem.photo(tweetObjectID: tweet.objectID, attribute: attribute)
            items.append(item)
        }
        
        self.items.value = items
    }
}

extension SearchMediaViewModel {
    enum SearchMediaError: Swift.Error {
        case invalidAuthorization
        case invalidSearchText
        case invalidAnchorToLoadMore
    }
}
