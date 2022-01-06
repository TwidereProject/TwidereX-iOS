//
//  SavedSearchFetchedResultController.swift
//  
//
//  Created by MainasuK on 2021-12-22.
//

import os.log
import Foundation
import UIKit
import Combine
import CoreData
import CoreDataStack
import TwitterSDK

public final class SavedSearchFetchedResultController {
    
    private var disposeBag = Set<AnyCancellable>()
    
    public let twitterSavedSearchFetchedResultController: TwitterSavedSearchFetchedResultController
    public let mastodonSavedSearchFetchedResultController: MastodonSavedSearchFetchedResultController
    
    // input
    @Published public var userIdentifier: UserIdentifier?
    
    // output
    @Published public var records: [SavedSearchRecord] = []
    
    public init(managedObjectContext: NSManagedObjectContext) {
        self.twitterSavedSearchFetchedResultController = TwitterSavedSearchFetchedResultController(managedObjectContext: managedObjectContext)
        self.mastodonSavedSearchFetchedResultController = MastodonSavedSearchFetchedResultController(managedObjectContext: managedObjectContext)
        // end init
        
        $userIdentifier
            .sink { [weak self] identifier in
                guard let self = self else { return }
                switch identifier {
                case .twitter(let identifier):
                    self.mastodonSavedSearchFetchedResultController.reset()
                    self.twitterSavedSearchFetchedResultController.userID = identifier.id
                case .mastodon(let identifier):
                    self.twitterSavedSearchFetchedResultController.reset()
                    self.mastodonSavedSearchFetchedResultController.userID = identifier.id
                    self.mastodonSavedSearchFetchedResultController.domain = identifier.domain
                case nil:
                    self.reset()
                }
            }
            .store(in: &disposeBag)
        
        Publishers.CombineLatest(
            twitterSavedSearchFetchedResultController.records,
            mastodonSavedSearchFetchedResultController.records
        )
        .map { twitterRecords, mastodonRecords in
            var records: [SavedSearchRecord] = []
            records.append(contentsOf: twitterRecords.map { .twitter(record: $0) })
            records.append(contentsOf: mastodonRecords.map { .mastodon(record: $0) })
            return records
        }
        .assign(to: \.records, on: self)
        .store(in: &disposeBag)
    }

}

extension SavedSearchFetchedResultController {
    public func reset() {
        twitterSavedSearchFetchedResultController.reset()
        mastodonSavedSearchFetchedResultController.reset()
    }
}
