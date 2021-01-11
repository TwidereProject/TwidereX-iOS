//
//  MentionTimelineViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-3.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import func AVFoundation.AVMakeRect
import UIKit
import GameplayKit
import Combine
import CoreData
import CoreDataStack
import AlamofireImage
import DateToolsSwift

final class MentionTimelineViewModel: NSObject {
    
    var disposeBag = Set<AnyCancellable>()
    var observations = Set<NSKeyValueObservation>()

    // input
    let context: AppContext
    let fetchedResultsController: NSFetchedResultsController<MentionTimelineIndex>
    let viewDidAppear = PassthroughSubject<Void, Never>()

    weak var contentOffsetAdjustableTimelineViewControllerDelegate: ContentOffsetAdjustableTimelineViewControllerDelegate?
    weak var tableView: UITableView?
    
    // output
    // top loader
    private(set) lazy var loadLatestStateMachine: GKStateMachine = {
        // exclude timeline middle fetcher state
        let stateMachine = GKStateMachine(states: [
            LoadLatestState.Initial(viewModel: self),
            LoadLatestState.Loading(viewModel: self),
            LoadLatestState.Fail(viewModel: self),
            LoadLatestState.Idle(viewModel: self),
        ])
        stateMachine.enter(LoadLatestState.Initial.self)
        return stateMachine
    }()
    lazy var loadLatestStateMachinePublisher = CurrentValueSubject<LoadLatestState?, Never>(nil)
    let isFetchingLatestTimeline = CurrentValueSubject<Bool, Never>(false)
    // bottom loader
    private(set) lazy var loadoldestStateMachine: GKStateMachine = {
        // exclude timeline middle fetcher state
        let stateMachine = GKStateMachine(states: [
            LoadOldestState.Initial(viewModel: self),
            LoadOldestState.Loading(viewModel: self),
            LoadOldestState.Fail(viewModel: self),
            LoadOldestState.Idle(viewModel: self),
            LoadOldestState.NoMore(viewModel: self),
        ])
        stateMachine.enter(LoadOldestState.Initial.self)
        return stateMachine
    }()
    lazy var loadOldestStateMachinePublisher = CurrentValueSubject<LoadOldestState?, Never>(nil)
    // middle loader
    let loadMiddleSateMachineList = CurrentValueSubject<[NSManagedObjectID: GKStateMachine], Never>([:])    // MentionTimelineIndex.objectID : middle loading state machine
    var diffableDataSource: UITableViewDiffableDataSource<TimelineSection, Item>?
    var cellFrameCache = NSCache<NSNumber, NSValue>()
    let avatarStyle = CurrentValueSubject<UserDefaults.AvatarStyle, Never>(UserDefaults.shared.avatarStyle)

    init(context: AppContext) {
        self.context  = context
        self.fetchedResultsController = {
            let fetchRequest = MentionTimelineIndex.sortedFetchRequest
            fetchRequest.fetchBatchSize = 20
            fetchRequest.returnsObjectsAsFaults = false
            fetchRequest.relationshipKeyPathsForPrefetching = [#keyPath(MentionTimelineIndex.tweet)]
            let controller = NSFetchedResultsController(
                fetchRequest: fetchRequest,
                managedObjectContext: context.managedObjectContext,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            
            return controller
        }()
        super.init()
        
        fetchedResultsController.delegate = self
        
        UserDefaults.shared
            .observe(\.avatarStyle) { [weak self] defaults, _ in
                guard let self = self else { return }
                self.avatarStyle.value = defaults.avatarStyle
            }
            .store(in: &observations)
    }
    
}
