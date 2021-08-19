//
//  HomeTimelineViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-3.
//

import os.log
import func AVFoundation.AVMakeRect
import UIKit
import AVKit
import Combine
import CoreData
import CoreDataStack
import GameplayKit
import AlamofireImage
import Kingfisher
import DateToolsSwift
import ActiveLabel

final class HomeTimelineViewModel: NSObject {
    
    let logger = Logger(subsystem: "HomeTimelineViewModel", category: "ViewModel")

    var disposeBag = Set<AnyCancellable>()
    var observations = Set<NSKeyValueObservation>()
    
    // input
    let context: AppContext
//    let timelinePredicate = CurrentValueSubject<NSPredicate?, Never>(nil)
    let fetchedResultsController: FeedFetchedResultsController
//    let isFetchingLatestTimeline = CurrentValueSubject<Bool, Never>(false)
//    let viewDidAppear = PassthroughSubject<Void, Never>()
    
//    weak var contentOffsetAdjustableTimelineViewControllerDelegate: ContentOffsetAdjustableTimelineViewControllerDelegate?
//    weak var tableView: UITableView?
//    weak var timelineMiddleLoaderTableViewCellDelegate: TimelineMiddleLoaderTableViewCellDelegate?
    
    // output
    var diffableDataSource: UICollectionViewDiffableDataSource<StatusSection, StatusItem>?
    var didLoadLatest = PassthroughSubject<Void, Never>()

    // top loader
//    private(set) lazy var loadLatestStateMachine: GKStateMachine = {
//        // exclude timeline middle fetcher state
//        let stateMachine = GKStateMachine(states: [
//            LoadLatestState.Initial(viewModel: self),
//            LoadLatestState.Loading(viewModel: self),
//            LoadLatestState.Fail(viewModel: self),
//            LoadLatestState.Idle(viewModel: self),
//        ])
//        stateMachine.enter(LoadLatestState.Initial.self)
//        return stateMachine
//    }()
//    lazy var loadLatestStateMachinePublisher = CurrentValueSubject<LoadLatestState?, Never>(nil)
//    // bottom loader
//    private(set) lazy var loadoldestStateMachine: GKStateMachine = {
//        // exclude timeline middle fetcher state
//        let stateMachine = GKStateMachine(states: [
//            LoadOldestState.Initial(viewModel: self),
//            LoadOldestState.Loading(viewModel: self),
//            LoadOldestState.Fail(viewModel: self),
//            LoadOldestState.Idle(viewModel: self),
//            LoadOldestState.NoMore(viewModel: self),
//        ])
//        stateMachine.enter(LoadOldestState.Initial.self)
//        return stateMachine
//    }()
//    lazy var loadOldestStateMachinePublisher = CurrentValueSubject<LoadOldestState?, Never>(nil)
//    // middle loader
//    let loadMiddleSateMachineList = CurrentValueSubject<[NSManagedObjectID: GKStateMachine], Never>([:])    // TimelineIndex.objectID : middle loading state machine
//    var diffableDataSource: UITableViewDiffableDataSource<TimelineSection, Item>?
//    var cellFrameCache = NSCache<NSNumber, NSValue>()
//    let avatarStyle = CurrentValueSubject<UserDefaults.AvatarStyle, Never>(UserDefaults.shared.avatarStyle)
    
    init(context: AppContext) {
        self.context  = context
        self.fetchedResultsController = FeedFetchedResultsController(managedObjectContext: context.managedObjectContext)
//        self.fetchedResultsController = {
//            let fetchRequest = TimelineIndex.sortedFetchRequest
//            fetchRequest.fetchBatchSize = 12        // 8 (row-per-screen) * 1.5 (magic batch scale)
//            fetchRequest.returnsObjectsAsFaults = false
//            // not Prefetching relationship save lots time cost (save ~2s when 30K entries)
//            // fetchRequest.relationshipKeyPathsForPrefetching = [#keyPath(TimelineIndex.tweet)]
//            let controller = NSFetchedResultsController(
//                fetchRequest: fetchRequest,
//                managedObjectContext: context.managedObjectContext,
//                sectionNameKeyPath: nil,
//                cacheName: nil
//            )
//
//            return controller
//        }()
        super.init()
        
        context.authenticationService.activeAuthenticationIndex
            .sink { [weak self] authenticationIndex in
                guard let self = self else { return }
                let emptyFeedPredicate = Feed.predicate(kind: .home, acct: Feed.Acct.twitter(userID: ""))
                guard let authenticationIndex = authenticationIndex else {
                    self.fetchedResultsController.predicate.value = emptyFeedPredicate
                    return
                }
                
                let predicate: NSPredicate?
                switch authenticationIndex.platform {
                case .twitter:
                    if let userID = authenticationIndex.twitterAuthentication?.userID {
                        predicate = Feed.predicate(kind: .home, acct: Feed.Acct.twitter(userID: userID))
                    } else {
                        predicate = nil
                    }
                case .mastodon:
                    // TODO:
                    predicate = nil
                case .none:
                    // TODO:
                    predicate = nil
                }
                
                self.fetchedResultsController.predicate.value = predicate ?? emptyFeedPredicate
            }
            .store(in: &disposeBag)
        
//        timelinePredicate
//            .receive(on: DispatchQueue.main)
//            .compactMap { $0 }
//            .first()    // set once
//            .sink { [weak self] predicate in
//                guard let self = self else { return }
//                self.fetchedResultsController.fetchRequest.predicate = predicate
//                do {
//                    self.diffableDataSource?.defaultRowAnimation = .fade
//                    let start = CACurrentMediaTime()
//                    try self.fetchedResultsController.performFetch()
//                    let end = CACurrentMediaTime()
//                    os_log("%{public}s[%{public}ld], %{public}s: fetch initial timeline cost %.2fs", ((#file as NSString).lastPathComponent), #line, #function, end - start)
//
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
//                        guard let self = self else { return }
//                        self.diffableDataSource?.defaultRowAnimation = .automatic
//                    }
//                } catch {
//                    assertionFailure(error.localizedDescription)
//                }
//            }
//            .store(in: &disposeBag)
//
//        context.authenticationService.activeAuthenticationIndex
//            .sink { [weak self] activeAuthenticationIndex in
//                guard let self = self else { return }
//                guard let activeAuthenticationIndex = activeAuthenticationIndex else { return }
//                    switch activeAuthenticationIndex.platform {
//                    case .twitter:
//                        guard let twitterAuthentication = activeAuthenticationIndex.twitterAuthentication else { return }
//                        let activeTwitterUserID = twitterAuthentication.userID
//                        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
//                            TimelineIndex.predicate(userID: activeTwitterUserID),
//                            TimelineIndex.predicate(platform: .twitter),
//                            TimelineIndex.notDeleted()
//                        ])
//                        self.timelinePredicate.value = predicate
//                    case .mastodon:
//                        // TODO:
//                        break
//                    case .none:
//                        // do nothing
//                        break
//                    }
//            }
//            .store(in: &disposeBag)
//
//        UserDefaults.shared
//            .observe(\.avatarStyle) { [weak self] defaults, _ in
//                guard let self = self else { return }
//                self.avatarStyle.value = defaults.avatarStyle
//            }
//            .store(in: &observations)
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s:", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}
