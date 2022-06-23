//
//  ListStatusTimelineViewModel.swift
//  TwidereX
//
//  Created by MainasuK on 2022-6-16.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import UIKit
import CoreData
import CoreDataStack
import TwidereCore

final class ListStatusTimelineViewModel: ListTimelineViewModel {
    
    // output
    @Published var title: String?
    @Published var isDeleted = false
    
    init(
        context: AppContext,
        list: ListRecord
    ) {
        super.init(
            context: context,
            kind: .list(list: list)
        )
        
        isFloatyButtonDisplay = false
        
        context.authenticationService.$activeAuthenticationContext
            .map { $0?.userIdentifier }
            .assign(to: &statusRecordFetchedResultController.$userIdentifier)
        
        // bind titile
        if let object = list.object(in: context.managedObjectContext) {
            switch object {
            case .twitter(let list):
                list.publisher(for: \.name)
                    .map { $0 as String? }
                    .assign(to: &$title)
            case .mastodon(let list):
                list.publisher(for: \.title)
                    .map { $0 as String? }
                    .assign(to: &$title)
            }
        }
        
        // listen delete event
        ManagedObjectObserver.observe(context: context.managedObjectContext)
            .sink(receiveCompletion: { completion in
                // do nohting
            }, receiveValue: { [weak self] changes in
                guard let self = self else { return }
                
                let objectIDs: [NSManagedObjectID] = changes.changeTypes.compactMap { changeType in
                    guard case let .delete(object) = changeType else { return nil }
                    return object.objectID
                }
                
                let isDeleted = objectIDs.contains(list.objectID)
                self.isDeleted = isDeleted
            })
            .store(in: &disposeBag)
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}
