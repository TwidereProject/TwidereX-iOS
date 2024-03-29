//
//  StatusThreadViewModel.swift
//  StatusThreadViewModel
//
//  Created by Cirno MainasuK on 2021-8-30.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import GameplayKit
import TwitterSDK
import MastodonSDK
import CoreData
import CoreDataStack
import TwidereCore

@MainActor
final class StatusThreadViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    let logger = Logger(subsystem: "StatusThreadViewModel", category: "ViewModel")
    
    @Published public var viewLayoutFrame = ViewLayoutFrame()
    
    let conversationRootTableViewCell = StatusTableViewCell()
    
    var fetchInitalConversationTask: AnyCancellable?

    // input
    let context: AppContext
    let authContext: AuthContext
    let kind: Kind
    
    @Published var deleteStatusIDs = Set<Twitter.Entity.V2.Tweet.ID>()
//    let twitterStatusThreadReplyViewModel: TwitterStatusThreadReplyViewModel
//    let twitterStatusThreadLeafViewModel: TwitterStatusThreadLeafViewModel
//    let mastodonStatusThreadViewModel: MastodonStatusThreadViewModel
//    let topListBatchFetchViewModel = ListBatchFetchViewModel(direction: .top)
//    let bottomListBatchFetchViewModel = ListBatchFetchViewModel(direction: .bottom)
//    let viewDidAppear = PassthroughSubject<Void, Never>()

    
    // output
    var diffableDataSource: UITableViewDiffableDataSource<Section, Item>?
    
    @Published private(set) var status: StatusObject?
    @Published private(set) var statusViewModel: StatusView.ViewModel?
    
    @Published var topPendingThreads: [Thread] = []
    @Published var topThreads: [Thread] = []
    @Published var bottomThreads: [Thread] = []
    
    @Published var topCursor: Cursor = .none
    @Published var bottomCursor: Cursor = .none
    @Published var isLoadTop: Bool = false
    @Published var isLoadBottom: Bool = false
    
    @Published var conversationLinkConfiguration: [StatusRecord: LinkConfiguration] = [:]

    public init(
        context: AppContext,
        authContext: AuthContext,
        kind: Kind
    ) {
        self.context = context
        self.authContext = authContext
        self.kind = kind
        // end init
        
        switch kind {
        case .status(let status):
            update(status: status)
        case .twitter, .mastodon:
            Task {
                await fetch(kind: kind)
            }   // end Task
        }
        
        fetchInitalConversationTask = Timer.publish(every: 3, on: .main, in: .common)
            .autoconnect()
            .map { _ in () }
            .prepend(())
            .sink { [weak self] in
                guard let self = self else { return }
                guard let status = self.status else { return }
                guard self.topCursor.isNone && self.bottomCursor.isNone else {
                    self.fetchInitalConversationTask = nil
                    return
                }
                let record = status.asRecord
                Task {
                    try await self.fetchConversation(status: record, cursor: .none)
                }   // end Task
            }
        //        self.twitterStatusThreadReplyViewModel = TwitterStatusThreadReplyViewModel(context: context, authContext: authContext)
//        self.twitterStatusThreadLeafViewModel = TwitterStatusThreadLeafViewModel(context: context)
//        self.mastodonStatusThreadViewModel = MastodonStatusThreadViewModel(context: context)
//        self.root = CurrentValueSubject(optionalRoot)
        
//        viewDidAppear
//            .subscribe(twitterStatusThreadReplyViewModel.viewDidAppear)
//            .store(in: &disposeBag)
//
//        // TODO: handle lazy thread loading
//        hasReplyTo = {
//            guard case let .root(threadContext) = optionalRoot else { return false }
//            guard let status = threadContext.status.object(in: context.managedObjectContext) else { return false }
//            switch status {
//            case .twitter(let _status):
//                let status = _status.repost ?? _status
//                return status.replyToStatusID != nil
//            case .mastodon(let _status):
//                let status = _status.repost ?? _status
//                return status.replyToStatusID != nil
//            }
//        }()
//
//        ManagedObjectObserver.observe(context: context.managedObjectContext)
//            .sink(receiveCompletion: { completion in
//                // do nohting
//            }, receiveValue: { [weak self] changes in
//                guard let self = self else { return }
//
//                let objectIDs: [NSManagedObjectID] = changes.changeTypes.compactMap { changeType in
//                    guard case let .delete(object) = changeType else { return nil }
//                    return object.objectID
//                }
//
//                self.delete(objectIDs: objectIDs)
//            })
//            .store(in: &disposeBag)
//
//        Publishers.CombineLatest(
//            twitterStatusThreadReplyViewModel.$items,
//            mastodonStatusThreadViewModel.ancestors
//        )
//        .map { $0 + $1 }
//        .assign(to: &$replies)
//
//        Publishers.CombineLatest(
//            twitterStatusThreadLeafViewModel.items,
//            mastodonStatusThreadViewModel.descendants
//        )
//        .map { $0 + $1 }
//        .assign(to: &$leafs)
    }
    
}

extension StatusThreadViewModel {
    enum Kind {
        case status(StatusRecord)
        case twitter(Twitter.Entity.V2.Tweet.ID)
        case mastodon(domain: String, Mastodon.Entity.Status.ID)
    }
    
    enum Thread: Hashable {
        case selfThread(status: StatusRecord)
        case conversationThread(components: [StatusRecord])
    }
    
    enum Cursor {
        case none
        case value(String)
        case noMore
        
        var isNone: Bool {
            switch self {
            case .none: return true
            default:    return false
            }
        }
        
        var isNoMore: Bool {
            switch self {
            case .noMore: return true
            default:      return false
            }
        }
        
        var value: String? {
            switch self {
            case .value(let value): return value
            default:                return nil
            }
        }
    }
    
    struct LinkConfiguration {
        let isTopLinkDisplay: Bool
        let isBottomLinkDisplay: Bool
    }
    
    public enum Section: Hashable {
        case main
    }   // end Section
    
    public enum Item: Hashable, DifferenceItem {
        // case
        case status(status: StatusRecord)
        case root
        case topLoader
        case bottomLoader
        
        public static func == (lhs: StatusThreadViewModel.Item, rhs: StatusThreadViewModel.Item) -> Bool {
            switch (lhs, rhs) {
            case (.status(let lhs), .status(let rhs)):
                return lhs.objectID == rhs.objectID
            case (.root, .root):
                return true
            case (.topLoader, .topLoader):
                return true
            case (.bottomLoader, .bottomLoader):
                return true
            default:
                return false
            }
        }
        
        public func hash(into hasher: inout Hasher) {
            switch self {
            case .status(let status):
                hasher.combine(String(describing: Item.status.self))
                hasher.combine(status.objectID)
            case .root:
                hasher.combine(String(describing: Item.root.self))
            case .topLoader:
                hasher.combine(String(describing: Item.topLoader.self))
            case .bottomLoader:
                hasher.combine(String(describing: Item.bottomLoader.self))
            }
        }
        
        public var isTransient: Bool {
            switch self {
            case .topLoader, .bottomLoader:         return true
            default:                                return false
            }
        }
    }   // end Item
}

extension StatusThreadViewModel {
    @MainActor
    func update(status record: StatusRecord) {
        guard let status = record.object(in: context.managedObjectContext) else {
            assertionFailure()
            return
        }
        self.status = status
        
        // setup link configuration for root
        updateConversationRootLink(status: status)
        
        guard statusViewModel == nil else { return }
        let _statusViewViewModel = StatusView.ViewModel(
            status: status,
            authContext: authContext,
            kind: .conversationRoot,
            delegate: conversationRootTableViewCell,
            viewLayoutFramePublisher: $viewLayoutFrame
        )
        self.statusViewModel = _statusViewViewModel
    }
    
    @MainActor
    func fetch(kind: Kind) async {
        guard status == nil else { return }
        
        do {
            switch kind {
            case .status:
                return
            case .twitter(let statusID):
                guard let authenticationContext = authContext.authenticationContext.twitterAuthenticationContext else { return }
                _ = try await context.apiService.twitterStatus(
                    statusIDs: [statusID],
                    authenticationContext: authenticationContext
                )
                let request = TwitterStatus.sortedFetchRequest
                request.predicate = TwitterStatus.predicate(id: statusID)
                request.fetchLimit = 1
                guard let result = try context.managedObjectContext.fetch(request).first else {
                    return
                }
                update(status: .twitter(record: result.asRecrod))
            case .mastodon(let domain, let statusID):
                guard let authenticationContext = authContext.authenticationContext.mastodonAuthenticationContext else { return }
                _ = try await context.apiService.mastodonStatus(
                    statusID: statusID,
                    authenticationContext: authenticationContext
                )
                let request = MastodonStatus.sortedFetchRequest
                request.predicate = MastodonStatus.predicate(domain: domain, id: statusID)
                request.fetchLimit = 1
                guard let result = try context.managedObjectContext.fetch(request).first else {
                    return
                }
                update(status: .mastodon(record: result.asRecrod))
            }
        } catch {
            try? await Task.sleep(nanoseconds: 3 * .second)
            await fetch(kind: kind)
        }
    }
    
    @MainActor
    func loadTop() async throws {
        guard !isLoadTop else { return }
        isLoadTop = true
        defer { isLoadTop = false }
        
        guard let status = self.statusViewModel?.status?.asRecord else { return }
        guard case .value(let cursor) = topCursor else { return }
        try await fetchConversation(status: status, cursor: .value(cursor))
    }

    @MainActor
    func loadBottom() async throws {
        guard !isLoadBottom else { return }
        isLoadBottom = true
        defer { isLoadBottom = false }
        
        guard let status = self.statusViewModel?.status?.asRecord else { return }
        guard case .value(let cursor) = bottomCursor else { return }
        try await fetchConversation(status: status, cursor: .value(cursor))
    }

    @MainActor
    func appendBottom(threads: [Thread]) {
        var result = self.bottomThreads
        result.append(contentsOf: threads)
        self.bottomThreads = result
    }
    
    @MainActor
    func enqueueTop(threads: [Thread]) {
        var result = self.topThreads
        result.insert(contentsOf: threads, at: 0)
        self.topThreads = result
    }

}

extension StatusThreadViewModel {
    private func fetchConversation(
        status: StatusRecord,
        cursor: Cursor
    ) async throws {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch conversation, cursor: \(String(describing: cursor))")
        switch status {
        case .twitter(let record):
            try await fetchConversation(status: record, cursor: cursor)
        case .mastodon(let record):
            try await fetchConversation(status: record, cursor: cursor)
        }
    }
    
    @MainActor
    private func fetchConversation(
        status: ManagedObjectRecord<TwitterStatus>,
        cursor: Cursor
    ) async throws {
        guard let authenticationContext = authContext.authenticationContext.twitterAuthenticationContext else { return }
        let _conversationRootStatusID: TwitterStatus.ID? = await context.managedObjectContext.perform {
            guard let status = status.object(in: self.context.managedObjectContext) else { return nil }
            let statusID = (status.repost ?? status).id     // remove repost wrapper
            return statusID
        }
        guard let conversationRootStatusID = _conversationRootStatusID else {
            assertionFailure()
            return
        }
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch conversation for \(conversationRootStatusID), cursor: \(cursor.value ?? "<nil>")")
        let response = try await context.apiService.twitterStatusConversation(
            conversationRootStatusID: conversationRootStatusID,
            query: .init(cursor: cursor.value),
            authenticationContext: authenticationContext
        )
        
        // update cursor
        if let cursor = response.value.topCursor {
            self.topCursor = .value(cursor)
        } else {
            self.topCursor = .noMore
        }
        if let cursor = response.value.bottomCursor {
            self.bottomCursor = .value(cursor)
        } else {
            self.bottomCursor = .noMore
        }
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch conversation success, top cursor: \(response.value.topCursor ?? "<nil>"), bottom cursor: \(response.value.bottomCursor ?? "<nil>")")
        
        let statusDict: [Twitter.Entity.V2.Tweet.ID: ManagedObjectRecord<TwitterStatus>] = {
            var dict: [TwitterStatus.ID: ManagedObjectRecord<TwitterStatus>] = [:]
            let request = TwitterStatus.sortedFetchRequest
            let statusIDs = response.value.statusIDs
            request.predicate = TwitterStatus.predicate(ids: statusIDs)
            let result = try? context.managedObjectContext.fetch(request)
            for status in result ?? [] {
                guard status.id != conversationRootStatusID else { continue }
                dict[status.id] = status.asRecrod
            }
            return dict
        }()
        let topThreads: [Thread] = {
            var threads: [Thread] = []
            for statusID in response.value.data.thread {
                guard let status = statusDict[statusID] else {
                    continue
                }
                guard statusID != conversationRootStatusID else {
                    continue
                }
                threads.append(.selfThread(status: .twitter(record: status)))
            }
            return threads
        }()
        let bottomThreads: [Thread] = {
            var threads: [Thread] = []
            for array in response.value.data.consersation {
                let components = array
                    .compactMap { statusDict[$0] }
                    .map { StatusRecord.twitter(record: $0) }
                guard !components.isEmpty else {
                    assertionFailure()
                    continue
                }
                threads.append(.conversationThread(components: components))
            }
            return threads
        }()
        enqueueTop(threads: topThreads)
        appendBottom(threads: bottomThreads)
        
        if topThreads.isEmpty && bottomThreads.isEmpty {
            // trigger data source update
            update(status: .twitter(record: status))
        }
    }
    
    @MainActor
    private func fetchConversation(
        status: ManagedObjectRecord<MastodonStatus>,
        cursor: Cursor
    ) async throws {
        guard let authenticationContext = authContext.authenticationContext.mastodonAuthenticationContext else { return }
        guard let conversationRootStatus = status.object(in: context.managedObjectContext) else {
            assertionFailure()
            return
        }
        let conversationRootStatusID = conversationRootStatus.id
        
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch conversation for \(conversationRootStatusID), cursor: \(cursor.value ?? "<nil>")")

        let response = try await context.apiService.mastodonStatusContext(
            statusID: conversationRootStatusID,
            authenticationContext: authenticationContext
        )
        
        // update cursor
        self.topCursor = .noMore
        self.bottomCursor = .noMore
        
        let ancestorNodes = MastodonStatusThreadViewModel.Node.replyToThread(
            for: conversationRootStatus.replyToStatusID,
            from: response.value.ancestors
        )
        let descendantNodes = MastodonStatusThreadViewModel.Node.children(
            of: conversationRootStatusID,
            from: response.value.descendants
        )
        let statusDict: [Mastodon.Entity.Status.ID: ManagedObjectRecord<MastodonStatus>] = {
            var dict: [MastodonStatus.ID: ManagedObjectRecord<MastodonStatus>] = [:]
            let request = MastodonStatus.sortedFetchRequest
            var statusIDs: [MastodonStatus.ID] = []
            statusIDs += ancestorNodes.map { $0.statusID }
            statusIDs += descendantNodes
                        .map { node in [node.statusID, node.children.first?.statusID].compactMap { $0 } }
                        .flatMap { $0 }
            request.predicate = MastodonStatus.predicate(domain: authenticationContext.domain, ids: statusIDs)
            let result = try? context.managedObjectContext.fetch(request)
            for status in result ?? [] {
                guard status.id != conversationRootStatusID else { continue }
                dict[status.id] = status.asRecrod
            }
            return dict
        }()
        let topThreads: [Thread] = {
            var threads: [Thread] = []
            for node in ancestorNodes {
                guard let record = statusDict[node.statusID] else { continue }
                threads.append(.selfThread(status: .mastodon(record: record)))
            }
            return threads
        }()
        let bottomThreads: [Thread] = {
            var threads: [Thread] = []
            for node in descendantNodes {
                guard let record = statusDict[node.statusID] else { continue }
                var components: [StatusRecord] = []
                // first tier
                components.append(.mastodon(record: record))
                // second tier
                if let child = node.children.first, let secondRecord = statusDict[child.statusID] {
                    components.append(.mastodon(record: secondRecord))
                }
                threads.append(.conversationThread(components: components))
            }
            return threads
        }()
        enqueueTop(threads: topThreads)
        appendBottom(threads: bottomThreads)
        
        if topThreads.isEmpty && bottomThreads.isEmpty {
            // trigger data source update
            update(status: .mastodon(record: status))
        }
    }
}

extension StatusThreadViewModel {
    private func updateConversationRootLink(status: StatusObject) {
        switch status {
        case .twitter(let status):
            let hasReplyTo = (status.repost ?? status).replyToStatusID != nil
            let linkConfiguration = LinkConfiguration(
                isTopLinkDisplay: hasReplyTo,
                isBottomLinkDisplay: false
            )
            self.conversationLinkConfiguration[.twitter(record: status.asRecrod)] = linkConfiguration
        case .mastodon(let status):
            let hasReplyTo = (status.repost ?? status).replyToStatusID != nil
            let linkConfiguration = LinkConfiguration(
                isTopLinkDisplay: hasReplyTo,
                isBottomLinkDisplay: false
            )
            self.conversationLinkConfiguration[.mastodon(record: status.asRecrod)] = linkConfiguration
        }
    }
//    func delete(objectIDs: [NSManagedObjectID]) {
//        if let root = root.value,
//           case let .root(threadContext) = root,
//           objectIDs.contains(threadContext.status.objectID)
//        {
//            self.root.value = nil
//            self.twitterStatusThreadReplyViewModel.root = nil
//        }
//
//        self.twitterStatusThreadReplyViewModel.delete(objectIDs: objectIDs)
//        self.twitterStatusThreadLeafViewModel.delete(objectIDs: objectIDs)
//        self.mastodonStatusThreadViewModel.delete(objectIDs: objectIDs)
//    }
}
