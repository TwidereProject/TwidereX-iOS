//
//  UserRecordFetchedResultController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-26.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import Foundation
import UIKit
import Combine
import CoreData
import CoreDataStack
import TwitterSDK

final public class UserRecordFetchedResultController {
    
    private var disposeBag = Set<AnyCancellable>()
    
    public let twitterUserFetchedResultsController: TwitterUserFetchedResultsController
    public let mastodonUserFetchedResultController: MastodonUserFetchedResultController
    
    // input
    @Published public var userIdentifier: UserIdentifier?
    
    // output
    @Published public var records: [UserRecord] = []
    
    public init(managedObjectContext: NSManagedObjectContext) {
        self.twitterUserFetchedResultsController = TwitterUserFetchedResultsController(managedObjectContext: managedObjectContext)
        self.mastodonUserFetchedResultController = MastodonUserFetchedResultController(managedObjectContext: managedObjectContext)
        // end init
        
        $userIdentifier
            .sink { [weak self] identifier in
                guard let self = self else { return }
                switch identifier {
                case .twitter:
                    // default on twitter
                    break
                case .mastodon(let identifier):
                    self.mastodonUserFetchedResultController.domain.value = identifier.domain
                case nil:
                    self.mastodonUserFetchedResultController.domain.value = ""
                }
            }
            .store(in: &disposeBag)
        
        Publishers.CombineLatest(
            twitterUserFetchedResultsController.records,
            mastodonUserFetchedResultController.records
        )
        .map { twitterRecords, mastodonRecords in
            var records: [UserRecord] = []
            records.append(contentsOf: twitterRecords.map { .twitter(record: $0) })
            records.append(contentsOf: mastodonRecords.map { .mastodon(record: $0) })
            return records
        }
        .assign(to: &$records)
    }
    
}

extension UserRecordFetchedResultController {
    public func reset() {
        twitterUserFetchedResultsController.userIDs.value = []
        mastodonUserFetchedResultController.userIDs.value = []
    }
}
