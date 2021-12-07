//
//  TwitterStatusThreadReplyViewModel.swift
//  TwidereX
//
//  Created by MainasuK on 2021-12-6.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import Foundation
import Combine
import GameplayKit
import TwitterSDK
import CoreData
import CoreDataStack
import TwidereCore

final class TwitterStatusThreadReplyViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    @Published var root: ManagedObjectRecord<TwitterStatus>?
    @Published var nodes: [TwitterStatusReplyNode] = []
    let viewDidAppear = PassthroughSubject<Void, Never>()
    
    // output
    @Published var items: [StatusItem] = []
    
    
    private(set) lazy var stateMachine: GKStateMachine = {
        // exclude timeline middle fetcher state
        let stateMachine = GKStateMachine(states: [
            State.Initial(viewModel: self),
            State.Prepare(viewModel: self),
            State.Idle(viewModel: self),
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
        
        Publishers.CombineLatest(
            $root,
            viewDidAppear.eraseToAnyPublisher()
        )
        .receive(on: DispatchQueue.main)    // <- required here due to state machine access $root value
        .sink { [weak self] root, _ in
            guard let self = self else { return }
            guard root != nil else { return }
            
            if self.stateMachine.currentState is State.Initial {
                self.stateMachine.enter(State.Prepare.self)
            }
        }
        .store(in: &disposeBag)
        
        $nodes
            .map { nodes in
                var items: [StatusItem] = []
                for (i, node) in nodes.enumerated() {
                    guard case let .success(record) = node.status else { continue }
                    let isLast = i == nodes.count - 1
                    let context = StatusItem.Thread.Context(
                        status: .twitter(record: record),
                        displayUpperConversationLink: !isLast,
                        displayBottomConversationLink: true
                    )
                    let thread = StatusItem.Thread.reply(context: context)
                    items.append(.thread(thread))
                }
                return items
            }
            .assign(to: &$items)
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension TwitterStatusThreadReplyViewModel {
    public class TwitterStatusReplyNode: CustomDebugStringConvertible {
        let statusID: TwitterStatus.ID
        let replyToStatusID: TwitterStatus.ID?
        
        let status: Status
        
        init(
            statusID: TwitterStatus.ID,
            replyToStatusID: TwitterStatus.ID?,
            status: Status
        ) {
            self.statusID = statusID
            self.replyToStatusID = replyToStatusID
            self.status = status
        }
        
        enum Status {
            case notDetermined
            case fail(Error)
            case success(ManagedObjectRecord<TwitterStatus>)
        }
        
        public var debugDescription: String {
            return "twitter status [\(statusID)] -> \(replyToStatusID ?? "<nil>"), \(status)"
        }
    }
}
