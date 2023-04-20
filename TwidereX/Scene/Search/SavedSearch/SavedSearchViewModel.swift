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
    let authContext: AuthContext
    let savedSearchService: SavedSearchService
    let savedSearchFetchedResultController: SavedSearchFetchedResultController

    // output
    var diffableDataSource: UITableViewDiffableDataSource<SearchSection, SearchItem>?
    @Published var isSavedSearchFetched = false

    init(
        context: AppContext,
        authContext: AuthContext
    ) {
        self.context = context
        self.authContext = authContext
        self.savedSearchService = SavedSearchService(apiService: context.apiService)
        self.savedSearchFetchedResultController = SavedSearchFetchedResultController(managedObjectContext: context.managedObjectContext)
        // end init

        savedSearchFetchedResultController.userIdentifier = authContext.authenticationContext.userIdentifier
    }
}
