//
//  MastodonStatusThreadViewModel.swift
//  MastodonStatusThreadViewModel
//
//  Created by Cirno MainasuK on 2021-9-6.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import Foundation
import Combine
import CoreData
import CoreDataStack
import MastodonSDK
import MastodonMeta

final class MastodonStatusThreadViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    
    // output
    let ancestors = CurrentValueSubject<[StatusItem], Never>([])
    let descendants = CurrentValueSubject<[StatusItem], Never>([])
    
    init(context: AppContext) {
        self.context = context
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension MastodonStatusThreadViewModel {
    
    func appendAncestor(
        domain: String,
        nodes: [Node]
    ) {
        let ids = nodes.map { $0.statusID }
        var dictionary: [MastodonStatus.ID: MastodonStatus] = [:]
        do {
            let request = MastodonStatus.sortedFetchRequest
            request.predicate = MastodonStatus.predicate(domain: domain, ids: ids)
            let statuses = try self.context.managedObjectContext.fetch(request)
            for status in statuses {
                dictionary[status.id] = status
            }
        } catch {
            os_log("%{public}s[%{public}ld], %{public}s: fetch conversation fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
            return
        }
        
        var newItems: [StatusItem] = []
        for (i, node) in nodes.enumerated() {
            guard let status = dictionary[node.statusID] else { continue }
            let isLast = i == nodes.count - 1
            
            let record = ManagedObjectRecord<MastodonStatus>(objectID: status.objectID)
            let context = StatusItem.Thread.Context(
                status: .mastodon(record: record),
                displayUpperConversationLink: !isLast,
                displayBottomConversationLink: true
            )
            let item = StatusItem.thread(.leaf(context: context))
            newItems.append(item)
        }
        
        let items = self.ancestors.value + newItems
        self.ancestors.value = items
    }
    
    func appendDescendant(
        domain: String,
        nodes: [Node]
    ) {
        let childrenIDs = nodes
            .map { node in [node.statusID, node.children.first?.statusID].compactMap { $0 } }
            .flatMap { $0 }
        var dictionary: [MastodonStatus.ID: MastodonStatus] = [:]
        do {
            let request = MastodonStatus.sortedFetchRequest
            request.predicate = MastodonStatus.predicate(domain: domain, ids: childrenIDs)
            let statuses = try self.context.managedObjectContext.fetch(request)
            for status in statuses {
                dictionary[status.id] = status
            }
        } catch {
            os_log("%{public}s[%{public}ld], %{public}s: fetch conversation fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
            return
        }
        
        var newItems: [StatusItem] = []
        for node in nodes {
            guard let status = dictionary[node.statusID] else { continue }
            // first tier
            let record = ManagedObjectRecord<MastodonStatus>(objectID: status.objectID)
            let context = StatusItem.Thread.Context(
                status: .mastodon(record: record)
            )
            let item = StatusItem.thread(.leaf(context: context))
            newItems.append(item)
            
            // second tier
            if let child = node.children.first {
                guard let secondaryStatus = dictionary[child.statusID] else { continue }
                let secondaryRecord = ManagedObjectRecord<MastodonStatus>(objectID: secondaryStatus.objectID)
                let secondaryContext = StatusItem.Thread.Context(
                    status: .mastodon(record: secondaryRecord),
                    displayUpperConversationLink: true
                )
                let secondaryItem = StatusItem.thread(.leaf(context: secondaryContext))
                newItems.append(secondaryItem)
                
                // update first tier context
                context.displayBottomConversationLink = true
            }
        }
        
        var items = self.descendants.value
        for item in newItems {
            guard !items.contains(item) else { continue }
            items.append(item)
        }
        self.descendants.value = items
    }
    
}

extension MastodonStatusThreadViewModel {
    class Node {
        typealias ID = String
        
        let statusID: ID
        let children: [Node]
        
        init(
            statusID: ID,
            children: [MastodonStatusThreadViewModel.Node]
        ) {
            self.statusID = statusID
            self.children = children
        }
    }
}

extension MastodonStatusThreadViewModel.Node {
    static func replyToThread(
        for replyToID: Mastodon.Entity.Status.ID?,
        from statuses: [Mastodon.Entity.Status]
    ) -> [MastodonStatusThreadViewModel.Node] {
        guard let replyToID = replyToID else {
            return []
        }
        
        var dict: [Mastodon.Entity.Status.ID: Mastodon.Entity.Status] = [:]
        for status in statuses {
            dict[status.id] = status
        }
        
        var nextID: Mastodon.Entity.Status.ID? = replyToID
        var nodes: [MastodonStatusThreadViewModel.Node] = []
        while let _nextID = nextID {
            guard let status = dict[_nextID] else { break }
            nodes.append(MastodonStatusThreadViewModel.Node(
                statusID: _nextID,
                children: []
            ))
            nextID = status.inReplyToID
        }
        
        return nodes
    }
}

extension MastodonStatusThreadViewModel.Node {
    static func children(
        of statusID: ID,
        from statuses: [Mastodon.Entity.Status]
    ) -> [MastodonStatusThreadViewModel.Node] {
        var dictionary: [ID: Mastodon.Entity.Status] = [:]
        var mapping: [ID: Set<ID>] = [:]
        
        for status in statuses {
            dictionary[status.id] = status
            guard let replyToID = status.inReplyToID else { continue }
            if var set = mapping[replyToID] {
                set.insert(status.id)
                mapping[replyToID] = set
            } else {
                mapping[replyToID] = Set([status.id])
            }
        }
        
        var children: [MastodonStatusThreadViewModel.Node] = []
        let replies = Array(mapping[statusID] ?? Set())
            .compactMap { dictionary[$0] }
            .sorted(by: { $0.createdAt > $1.createdAt })
        for reply in replies {
            let child = child(of: reply.id, dictionary: dictionary, mapping: mapping)
            children.append(child)
        }
        return children
    }
    
    static func child(
        of statusID: ID,
        dictionary: [ID: Mastodon.Entity.Status],
        mapping: [ID: Set<ID>]
    ) -> MastodonStatusThreadViewModel.Node {
        let childrenIDs = mapping[statusID] ?? []
        let children = Array(childrenIDs)
            .compactMap { dictionary[$0] }
            .sorted(by: { $0.createdAt > $1.createdAt })
            .map { status in child(of: status.id, dictionary: dictionary, mapping: mapping) }
        return MastodonStatusThreadViewModel.Node(
            statusID: statusID,
            children: children
        )
    }
    
}
