//
//  HomeTimelineViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-3.
//

import os.log
import UIKit
import CoreDataStack

final class HomeTimelineViewModel: TimelineViewModel {
    
    init(context: AppContext) {
        super.init(context: context, kind: .home)
        
        context.authenticationService.$activeAuthenticationContext
            .sink { [weak self] authenticationContext in
                guard let self = self else { return }
                let emptyFeedPredicate = Feed.nonePredicate()
                guard let authenticationContext = authenticationContext else {
                    self.fetchedResultsController.predicate = emptyFeedPredicate
                    return
                }
                
                let predicate: NSPredicate
                switch authenticationContext {
                case .twitter(let authenticationContext):
                    let userID = authenticationContext.userID
                    predicate = Feed.predicate(kind: .home, acct: Feed.Acct.twitter(userID: userID))
                case .mastodon(let authenticationContext):
                    let domain = authenticationContext.domain
                    let userID = authenticationContext.userID
                    predicate = Feed.predicate(kind: .home, acct: Feed.Acct.mastodon(domain: domain, userID: userID))
                }
                self.fetchedResultsController.predicate = predicate
            }
            .store(in: &disposeBag)
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s:", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}
