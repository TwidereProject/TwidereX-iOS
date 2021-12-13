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
import TwitterSDK
import TwidereUI

final class SearchMediaViewModel {
    
    let logger = Logger(subsystem: "SearchMediaViewModel", category: "ViewModel")
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let statusRecordFetchedResultController: StatusRecordFetchedResultController
    let listBatchFetchViewModel = ListBatchFetchViewModel()
    let viewDidAppear = CurrentValueSubject<Void, Never>(Void())
    @Published var searchText = ""
    @Published var userIdentifier: UserIdentifier?
    
    // output
    var diffableDataSource: UICollectionViewDiffableDataSource<StatusMediaGallerySection, StatusItem>?
    @MainActor private(set) lazy var stateMachine: GKStateMachine = {
        let stateMachine = GKStateMachine(states: [
            State.Initial(viewModel: self),
            State.Idle(viewModel: self),
            State.Reset(viewModel: self),
            State.Loading(viewModel: self),
            State.Fail(viewModel: self),
            State.NoMore(viewModel: self),
        ])
        stateMachine.enter(State.Initial.self)
        return stateMachine
    }()
    
    init(context: AppContext) {
        self.context = context
        self.statusRecordFetchedResultController = StatusRecordFetchedResultController(managedObjectContext: context.managedObjectContext)
        // end init
        
        $searchText
            .removeDuplicates()
            .throttle(for: 0.5, scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] searchText in
                guard let self = self else { return }
                self.logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): search \(searchText)")
                Task {
                    await self.stateMachine.enter(SearchMediaViewModel.State.Reset.self)
                }
            }
            .store(in: &disposeBag)
        
        $userIdentifier
            .assign(to: &statusRecordFetchedResultController.$userIdentifier)
        
        
//        self.fetchedResultsController.delegate = self
        
//        Publishers.CombineLatest(
//            items.eraseToAnyPublisher(),
//            stateMachinePublisher.eraseToAnyPublisher()
//        )
//        .throttle(for: .milliseconds(300), scheduler: DispatchQueue.main, latest: true)
//        .receive(on: DispatchQueue.main)
//        .sink { [weak self] items, state in
//            guard let self = self else { return }
//            os_log("%{public}s[%{public}ld], %{public}s: state did change", ((#file as NSString).lastPathComponent), #line, #function)
//            
//            var snapshot = NSDiffableDataSourceSnapshot<MediaSection, Item>()
//            snapshot.appendSections([.main])
//            snapshot.appendItems(items)
//            switch self.stateMachine.currentState {
//            case is State.Fail:
//                // TODO:
//                break
//            case is State.Initial, is State.NoMore:
//                break
//            case is State.Idle, is State.Loading:
//                snapshot.appendSections([.footer])
//                snapshot.appendItems([.bottomLoader], toSection: .footer)
//            default:
//                assertionFailure()
//            }
//            
//            self.diffableDataSource?.apply(snapshot, animatingDifferences: true)
//        }
//        .store(in: &disposeBag)
//        
//        searchMediaTweetIDs
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] ids in
//                guard let self = self else { return }
//                self.fetchedResultsController.fetchRequest.predicate = Tweet.predicate(idStrs: ids)
//                do {
//                    try self.fetchedResultsController.performFetch()
//                } catch {
//                    assertionFailure(error.localizedDescription)
//                }
//            }
//            .store(in: &disposeBag)
//        
//        searchActionPublisher
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] _ in
//                guard let self = self else { return }
//                self.stateMachine.enter(State.Loading.self)
//            }
//            .store(in: &disposeBag)
    }
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}
