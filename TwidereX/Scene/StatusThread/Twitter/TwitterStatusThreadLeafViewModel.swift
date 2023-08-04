//
//  TwitterStatusThreadLeafViewModel.swift
//  TwitterStatusThreadLeafViewModel
//
//  Created by Cirno MainasuK on 2021-9-1.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import Foundation
import Combine
import CoreData
import CoreDataStack
import TwitterSDK

//final class TwitterStatusThreadLeafViewModel {
//
//    var disposeBag = Set<AnyCancellable>()
//
//    // input
//    let context: AppContext
//    @Published private(set) var deletedObjectIDs: Set<NSManagedObjectID> = Set()
//
//    // output
//    @Published private var _items: [StatusItem] = []
//    let items = CurrentValueSubject<[StatusItem], Never>([])
//
//    init(context: AppContext) {
//        self.context = context
//
//        Publishers.CombineLatest(
//            $_items,
//            $deletedObjectIDs
//        )
//        .sink { [weak self] items, deletedObjectIDs in
//            guard let self = self else { return }
//            let newItems = items.filter { item in
//                switch item {
//                case .thread(let thread):
//                    return !deletedObjectIDs.contains(thread.statusRecord.objectID)
//                default:
//                    assertionFailure()
//                    return false
//                }
//            }
//            self.items.value = newItems
//        }
//        .store(in: &disposeBag)
//    }
//
//    deinit {
//        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
//    }
//
//}
//
//extension TwitterStatusThreadLeafViewModel {
//
//    // FIXME: handle node remove
//    func append(nodes: [Node]) {
//        let childrenIDs = nodes
//            .map { node in [node.statusID, node.children.first?.statusID].compactMap { $0 } }
//            .flatMap { $0 }
//        var dictionary: [TwitterStatus.ID: TwitterStatus] = [:]
//        do {
//            let request = TwitterStatus.sortedFetchRequest
//            request.predicate = TwitterStatus.predicate(ids: childrenIDs)
//            let statuses = try self.context.managedObjectContext.fetch(request)
//            for status in statuses {
//                dictionary[status.id] = status
//            }
//        } catch {
//            os_log("%{public}s[%{public}ld], %{public}s: fetch conversation fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
//            return
//        }
//
//        var newItems: [StatusItem] = []
//        for node in nodes {
//            guard let status = dictionary[node.statusID] else { continue }
//            // first tier
//            let record = ManagedObjectRecord<TwitterStatus>(objectID: status.objectID)
//            let context = StatusItem.Thread.Context(
//                status: .twitter(record: record)
//            )
//            let item = StatusItem.thread(.leaf(context: context))
//            newItems.append(item)
//
//            // second tier
//            if let child = node.children.first {
//                guard let secondaryStatus = dictionary[child.statusID] else { continue }
//                let secondaryRecord = ManagedObjectRecord<TwitterStatus>(objectID: secondaryStatus.objectID)
//                let secondaryContext = StatusItem.Thread.Context(
//                    status: .twitter(record: secondaryRecord),
//                    displayUpperConversationLink: true
//                )
//                let secondaryItem = StatusItem.thread(.leaf(context: secondaryContext))
//                newItems.append(secondaryItem)
//
//                // update first tier context
//                context.displayBottomConversationLink = true
//            }
//        }
//
//        var items = self._items
//        for item in newItems {
//            guard !items.contains(item) else { continue }
//            items.append(item)
//        }
//        self._items = items
//    }
//
//}
//
//extension TwitterStatusThreadLeafViewModel {
//    class Node {
//        typealias ID = String
//
//        let statusID: ID
//        let children: [Node]
//
//        init(statusID: ID, children: [TwitterStatusThreadLeafViewModel.Node]) {
//            self.statusID = statusID
//            self.children = children
//        }
//    }
//}
//
//extension TwitterStatusThreadLeafViewModel.Node {
//    // V1
//    static func children(
//        of statusID: ID,
//        from content: Twitter.API.Search.Content
//    ) -> [TwitterStatusThreadLeafViewModel.Node] {
//        let statuses = content.statuses ?? []
//        var dictionary: [ID: Twitter.Entity.Tweet] = [:]
//        var mapping: [ID: Set<ID>] = [:]
//
//        for status in statuses {
//            dictionary[status.idStr] = status
//            guard let replyToID = status.inReplyToStatusIDStr else { continue }
//            if var set = mapping[replyToID] {
//                set.insert(status.idStr)
//                mapping[replyToID] = set
//            } else {
//                mapping[replyToID] = Set([status.idStr])
//            }
//        }
//
//        var children: [TwitterStatusThreadLeafViewModel.Node] = []
//        let replies = Array(mapping[statusID] ?? Set())
//            .compactMap { dictionary[$0] }
//            .sorted(by: { $0.createdAt > $1.createdAt })
//        for reply in replies {
//            let child = child(of: reply.idStr, dictionary: dictionary, mapping: mapping)
//            children.append(child)
//        }
//        return children
//    }
//
//    static func child(
//        of statusID: ID,
//        dictionary: [ID: Twitter.Entity.Tweet],
//        mapping: [ID: Set<ID>]
//    ) -> TwitterStatusThreadLeafViewModel.Node {
//        let childrenIDs = mapping[statusID] ?? []
//        let children = Array(childrenIDs)
//            .compactMap { dictionary[$0] }
//            .sorted(by: { $0.createdAt > $1.createdAt })
//            .map { status in child(of: status.idStr, dictionary: dictionary, mapping: mapping) }
//        return TwitterStatusThreadLeafViewModel.Node(
//            statusID: statusID,
//            children: children
//        )
//    }
//
//    // V2
//    static func children(
//        of statusID: ID,
//        from content: Twitter.API.V2.Search.Content
//    ) -> [TwitterStatusThreadLeafViewModel.Node] {
//        let statuses = [content.data, content.includes?.tweets].compactMap { $0 }.flatMap { $0 }
//        var dictionary: [ID: Twitter.Entity.V2.Tweet] = [:]
//        var mapping: [ID: Set<ID>] = [:]
//
//        for status in statuses {
//            dictionary[status.id] = status
//            guard let replyTo = status.referencedTweets?.first(where: { $0.type == .repliedTo }),
//                  let replyToID = replyTo.id
//            else { continue }
//
//            if var set = mapping[replyToID] {
//                set.insert(status.id)
//                mapping[replyToID] = set
//            } else {
//                mapping[replyToID] = Set([status.id])
//            }
//        }
//
//        var children: [TwitterStatusThreadLeafViewModel.Node] = []
//        let replies = Array(mapping[statusID] ?? Set())
//            .compactMap { dictionary[$0] }
//            .sorted(by: { $0.createdAt > $1.createdAt })
//        for reply in replies {
//            let child = child(of: reply.id, dictionary: dictionary, mapping: mapping)
//            children.append(child)
//        }
//        return children
//    }
//
//    static func child(
//        of statusID: ID,
//        dictionary: [ID: Twitter.Entity.V2.Tweet],
//        mapping: [ID: Set<ID>]
//    ) -> TwitterStatusThreadLeafViewModel.Node {
//        let childrenIDs = mapping[statusID] ?? []
//        let children = Array(childrenIDs)
//            .compactMap { dictionary[$0] }
//            .sorted(by: { $0.createdAt > $1.createdAt })
//            .map { status in child(of: status.id, dictionary: dictionary, mapping: mapping) }
//        return TwitterStatusThreadLeafViewModel.Node(
//            statusID: statusID,
//            children: children
//        )
//    }
//
//}
//
//extension TwitterStatusThreadLeafViewModel {
//    func delete(objectIDs: [NSManagedObjectID]) {
//        var set = deletedObjectIDs
//        for objectID in objectIDs {
//            set.insert(objectID)
//        }
//        self.deletedObjectIDs = set
//    }
//}
