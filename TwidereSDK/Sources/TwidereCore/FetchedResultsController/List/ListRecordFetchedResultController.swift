//
//  ListRecordFetchedResultController.swift
//  
//
//  Created by MainasuK on 2022-3-4.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack
import TwitterSDK

public final class ListRecordFetchedResultController {
    
    private var disposeBag = Set<AnyCancellable>()
    
    public let twitterListRecordFetchedResultController: TwitterListRecordFetchedResultController
    public let mastodonListRecordFetchedResultController: MastodonListRecordFetchedResultController

    // input
    @Published public var userIdentifier: UserIdentifier?
    
    // output
    @Published public var records: [ListRecord] = []
    
    public init(managedObjectContext: NSManagedObjectContext) {
        self.twitterListRecordFetchedResultController = TwitterListRecordFetchedResultController(managedObjectContext: managedObjectContext)
        self.mastodonListRecordFetchedResultController = MastodonListRecordFetchedResultController(managedObjectContext: managedObjectContext)
        // end init
        
        $userIdentifier
            .sink { [weak self] identifier in
                guard let self = self else { return }
                switch identifier {
                case .twitter:
                    self.mastodonListRecordFetchedResultController.domain = ""
                case .mastodon(let identifier):
                    self.mastodonListRecordFetchedResultController.domain = identifier.domain
                case nil:
                    self.mastodonListRecordFetchedResultController.domain = ""
                }
            }
            .store(in: &disposeBag)
        
        Publishers.CombineLatest(
            twitterListRecordFetchedResultController.$records,
            mastodonListRecordFetchedResultController.$records
        )
        .map { twitterRecords, mastodonRecords in
            var records: [ListRecord] = []
            records.append(contentsOf: twitterRecords.map { .twitter(record: $0) })
            records.append(contentsOf: mastodonRecords.map { .mastodon(record: $0) })
            return records
        }
        .assign(to: &$records)
    }

}

extension ListRecordFetchedResultController {
    public func reset() {
        twitterListRecordFetchedResultController.ids = []
        mastodonListRecordFetchedResultController.ids = []
    }
}
