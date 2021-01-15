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
    var diffableDataSource: UICollectionViewDiffableDataSource<MediaSection, Item>!
    let items = CurrentValueSubject<[Item], Never>([])
    
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
        super.init()
        
        self.fetchedResultsController.delegate = self
        
        Publishers.CombineLatest(
            items.eraseToAnyPublisher(),
            stateMachinePublisher.eraseToAnyPublisher()
        )
        .throttle(for: .milliseconds(300), scheduler: DispatchQueue.main, latest: true)
        .receive(on: DispatchQueue.main)
        .sink { [weak self] items, state in
            guard let self = self else { return }
            os_log("%{public}s[%{public}ld], %{public}s: state did change", ((#file as NSString).lastPathComponent), #line, #function)
            
            var snapshot = NSDiffableDataSourceSnapshot<MediaSection, Item>()
            snapshot.appendSections([.main])
            snapshot.appendItems(items)
            switch self.stateMachine.currentState {
            case is State.Fail:
                // TODO:
                break
            case is State.Initial, is State.NoMore:
                break
            case is State.Idle, is State.Loading:
                snapshot.appendSections([.footer])
                snapshot.appendItems([.bottomLoader], toSection: .footer)
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
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension SearchMediaViewModel {
    enum SearchMediaError: Swift.Error {
        case invalidAuthorization
        case invalidSearchText
        case invalidAnchorToLoadMore
    }
}
