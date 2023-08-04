//
//  HomeTimelineViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-3.
//

import os.log
import UIKit
import CoreDataStack

final class HomeTimelineViewModel: ListTimelineViewModel {
    
    // input
    var isUpdaingDataSource = false
    var latestUnreadStatusItem: StatusItem?
    var latestUnreadStatusItemBeforeScrollToTop: StatusItem?
    
    // output
    @Published var unreadItemCount = 0
    @Published var loadItemCount = 0
    
    init(
        context: AppContext,
        authContext: AuthContext
    ) {
        super.init(
            context: context,
            authContext: authContext,
            kind: .home
        )
        // end init

        enableAutoFetchLatest = true
        
        feedFetchedResultsController.predicate = {
            let predicate: NSPredicate
            let authenticationContext = authContext.authenticationContext
            switch authenticationContext {
            case .twitter(let authenticationContext):
                let userID = authenticationContext.userID
                predicate = Feed.predicate(kind: .home, acct: Feed.Acct.twitter(userID: userID))
            case .mastodon(let authenticationContext):
                let domain = authenticationContext.domain
                let userID = authenticationContext.userID
                predicate = Feed.predicate(kind: .home, acct: Feed.Acct.mastodon(domain: domain, userID: userID))
            }
            return predicate
        }()
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s:", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
    
}

extension HomeTimelineViewModel {
    
    var sinceID: String? {
        guard let first = feedFetchedResultsController.records.first,
              let feed = first.object(in: context.managedObjectContext),
              case let .status(status) = feed.content
        else { return nil }
        return status.id
    }
    
}
