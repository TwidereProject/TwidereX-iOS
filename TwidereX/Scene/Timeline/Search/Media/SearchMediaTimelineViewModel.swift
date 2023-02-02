//
//  SearchMediaTimelineViewModel.swift
//  TwidereX
//
//  Created by MainasuK on 2022-6-16.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import UIKit
import TwidereCore

final class SearchMediaTimelineViewModel: GridTimelineViewModel {
    
    // input
    @Published var searchText = ""
    
    // output
    
    init(
        context: AppContext,
        authContext: AuthContext
    ) {
        let searchTimelineContext = StatusFetchViewModel.Timeline.Kind.SearchTimelineContext(
            timelineKind: .media,
            searchText: nil
        )
        super.init(
            context: context,
            authContext: authContext,
            kind: .search(searchTimelineContext: searchTimelineContext)
        )
        
        isRefreshControlEnabled = false
        isFloatyButtonDisplay = false
        
        context.authenticationService.$activeAuthenticationContext
            .map { $0?.userIdentifier }
            .assign(to: &statusRecordFetchedResultController.$userIdentifier)
        
        // bind searchText
        $searchText.assign(to: &searchTimelineContext.$searchText)
        
        $searchText
            .removeDuplicates()
            .throttle(for: 0.5, scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] searchText in
                guard let self = self else { return }
                self.logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): search \(searchText)")
                Task {
                    await self.stateMachine.enter(TimelineViewModel.LoadOldestState.Reloading.self)
                }
            }
            .store(in: &disposeBag)
        
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}
