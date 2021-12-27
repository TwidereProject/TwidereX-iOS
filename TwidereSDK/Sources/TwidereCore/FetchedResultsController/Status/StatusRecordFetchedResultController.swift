//
//  StatusRecordFetchedResultController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-12.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import Foundation
import UIKit
import Combine
import CoreData
import CoreDataStack
import TwitterSDK

public final class StatusRecordFetchedResultController {
    
    private var disposeBag = Set<AnyCancellable>()
    
    public let twitterStatusFetchedResultController: TwitterStatusFetchedResultController
    public let mastodonStatusFetchedResultController: MastodonStatusFetchedResultController
    
    // input
    @Published public var userIdentifier: UserIdentifier?
    
    // output
    public let records = CurrentValueSubject<[StatusRecord], Never>([])
    
    public init(managedObjectContext: NSManagedObjectContext) {
        self.twitterStatusFetchedResultController = TwitterStatusFetchedResultController(managedObjectContext: managedObjectContext)
        self.mastodonStatusFetchedResultController = MastodonStatusFetchedResultController(managedObjectContext: managedObjectContext)
        // end init
        
        $userIdentifier
            .sink { [weak self] identifier in
                guard let self = self else { return }
                switch identifier {
                case .twitter:
                    // default on twitter
                    break
                case .mastodon(let identifier):
                    self.mastodonStatusFetchedResultController.domain.value = identifier.domain
                case nil:
                    self.mastodonStatusFetchedResultController.domain.value = ""
                }
            }
            .store(in: &disposeBag)
        
        Publishers.CombineLatest(
            twitterStatusFetchedResultController.records,
            mastodonStatusFetchedResultController.records
        )
        .map { twitterRecords, mastodonRecords in
            var records: [StatusRecord] = []
            records.append(contentsOf: twitterRecords.map { .twitter(record: $0) })
            records.append(contentsOf: mastodonRecords.map { .mastodon(record: $0) })
            return records
        }
        .assign(to: \.value, on: records)
        .store(in: &disposeBag)

    }

}

extension StatusRecordFetchedResultController {
    public func reset() {
        twitterStatusFetchedResultController.statusIDs.value = []
        mastodonStatusFetchedResultController.statusIDs.value = []
    }
}
