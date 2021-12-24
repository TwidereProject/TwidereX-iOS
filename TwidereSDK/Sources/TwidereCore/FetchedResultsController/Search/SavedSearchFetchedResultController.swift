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
    
    // input
    @Published public var userIdentifier: UserIdentifier?
    
    // output
    @Published public var records: [SavedSearchRecord] = []
    
    public init(managedObjectContext: NSManagedObjectContext) {
        self.twitterSavedSearchFetchedResultController = TwitterSavedSearchFetchedResultController(managedObjectContext: managedObjectContext)
        // end init
        
        $userIdentifier
            .sink { [weak self] identifier in
                guard let self = self else { return }
                switch identifier {
                case .twitter(let identifier):
                    self.twitterSavedSearchFetchedResultController.userID = identifier.id
                case .mastodon(let identifier):
                    self.twitterSavedSearchFetchedResultController.userID = ""
                    // TODO:
                case nil:
                    self.reset()
                }
            }
            .store(in: &disposeBag)
        
        twitterSavedSearchFetchedResultController.records
            .map { twitterRecords in
                var records: [SavedSearchRecord] = []
                records.append(contentsOf: twitterRecords.map { .twitter(record: $0) })
                return records
            }
            .assign(to: \.records, on: self)
            .store(in: &disposeBag)

    }

}

extension SavedSearchFetchedResultController {
    public func reset() {
        twitterSavedSearchFetchedResultController.userID = ""
    }
}
