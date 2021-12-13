//
//  SearchHashtagViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-11-5.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack
import GameplayKit

final class SearchHashtagViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    let logger = Logger(subsystem: "SearchHashtagViewModel", category: "ViewModel")
    
    // input
    let context: AppContext
    let listBatchFetchViewModel = ListBatchFetchViewModel()
    let viewDidAppear = PassthroughSubject<Void, Never>()
    @Published var items: [HashtagItem] = []
    @Published var searchText = ""
    
    // output
    var diffableDataSource: UITableViewDiffableDataSource<HashtagSection, HashtagItem>?
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
        // end init
        
        $searchText
            .removeDuplicates()
            .throttle(for: 0.5, scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] searchText in
                guard let self = self else { return }
                self.logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): search \(searchText)")
                Task {
                    await self.stateMachine.enter(SearchHashtagViewModel.State.Reset.self)                    
                }
            }
            .store(in: &disposeBag)
    }
}
