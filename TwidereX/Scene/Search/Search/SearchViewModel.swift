//
//  SearchViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-8.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import TwidereCore

final class SearchViewModel {
    
    let logger = Logger(subsystem: "SearchViewModel", category: "ViewModel")
    
    var disposeBag = Set<AnyCancellable>()
    var observations = Set<NSKeyValueObservation>()
    
    // input
    let context: AppContext
    let savedSearchService: SavedSearchService
    let viewDidAppear = PassthroughSubject<Void, Never>()
    let savedSearchFetchedResultController: SavedSearchFetchedResultController
    
    // output
    var diffableDataSource: UITableViewDiffableDataSource<SearchSection, SearchItem>?
    @Published var isSavedSearchFetched = false

    init(context: AppContext) {
        self.context = context
        self.savedSearchService = SavedSearchService(apiService: context.apiService)
        self.savedSearchFetchedResultController = SavedSearchFetchedResultController(managedObjectContext: context.managedObjectContext)
        // end init
        
        context.authenticationService.activeAuthenticationContext
            .map { $0?.userIdentifier }
            .assign(to: \.userIdentifier, on: savedSearchFetchedResultController)
            .store(in: &disposeBag)
        
        viewDidAppear
            .sink { [weak self] _ in
                guard let self = self else { return }
                guard let authenticationContext = self.context.authenticationService.activeAuthenticationContext.value else { return }
                
                Task {
                    do {
                        try await self.savedSearchService.fetchList(authenticationContext: authenticationContext)
                    } catch {
                        // do nothing
                    }
                    self.isSavedSearchFetched = true
                }
            }
            .store(in: &disposeBag)
    }
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}
