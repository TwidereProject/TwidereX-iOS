//
//  SearchTimelineViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-28.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import GameplayKit
import Combine
import CoreData
import CoreDataStack
import TwitterAPI
import AlamofireImage

class SearchTimelineViewModel: NSObject {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let searchText = CurrentValueSubject<String, Never>("")
    let searchActionPublisher = PassthroughSubject<Void, Never>()
    let tweetFetchedResultsController: TweetFetchedResultsController

    weak var tableView: UITableView?
    
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
    var diffableDataSource: UITableViewDiffableDataSource<TimelineSection, Item>?
    // var cellFrameCache = NSCache<NSNumber, NSValue>()
    
    init(context: AppContext) {
        self.context = context
        self.tweetFetchedResultsController = TweetFetchedResultsController(managedObjectContext: context.managedObjectContext, additionalTweetPredicate: Tweet.notDeleted())

        super.init()
        
        Publishers.CombineLatest(
            tweetFetchedResultsController.items.eraseToAnyPublisher(),
            stateMachinePublisher.eraseToAnyPublisher()
        )
        .throttle(for: .milliseconds(300), scheduler: DispatchQueue.main, latest: true)
        .receive(on: DispatchQueue.main)
        .sink { [weak self] timelineItems, state in
            guard let self = self else { return }
            os_log("%{public}s[%{public}ld], %{public}s: state did change", ((#file as NSString).lastPathComponent), #line, #function)

            var snapshot = NSDiffableDataSourceSnapshot<TimelineSection, Item>()
            snapshot.appendSections([.main])
            snapshot.appendItems(timelineItems)
            switch self.stateMachine.currentState {
            case is State.Fail:
                // TODO:
                break
            case is State.Initial, is State.NoMore:
                break
            case is State.Idle, is State.Loading:
                snapshot.appendItems([.bottomLoader], toSection: .main)
            default:
                assertionFailure()
            }
            
            self.diffableDataSource?.apply(snapshot, animatingDifferences: true)
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
