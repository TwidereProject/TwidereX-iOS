//
//  SavedSearchViewModel.swift
//  TwidereX
//
//  Created by MainasuK on 2021-12-27.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import TwidereCore

final class SavedSearchViewModel {
    
    let logger = Logger(subsystem: "SavedSearchViewModel", category: "ViewModel")
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let savedSearchService: SavedSearchService
    let savedSearchFetchedResultController: SavedSearchFetchedResultController

    // output
    var diffableDataSource: UITableViewDiffableDataSource<SearchSection, SearchItem>?
    @Published var isSavedSearchFetched = false

    init(context: AppContext) {
        self.context = context
        self.savedSearchService = SavedSearchService(apiService: context.apiService)
        self.savedSearchFetchedResultController = SavedSearchFetchedResultController(managedObjectContext: context.managedObjectContext)
        // end init

        context.authenticationService.$activeAuthenticationContext
            .map { $0?.userIdentifier }
            .assign(to: \.userIdentifier, on: savedSearchFetchedResultController)
            .store(in: &disposeBag)
    }
}
