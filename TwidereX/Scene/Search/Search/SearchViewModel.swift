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
    let savedSearchViewModel: SavedSearchViewModel
    let viewDidAppear = PassthroughSubject<Void, Never>()
    
    // output
    var diffableDataSource: UITableViewDiffableDataSource<SearchSection, SearchItem>?
    @Published var savedSearchTexts = Set<String>()

    init(context: AppContext) {
        self.context = context
        self.savedSearchViewModel = SavedSearchViewModel(context: context)
        // end init
        
        viewDidAppear
            .sink { [weak self] _ in
                guard let self = self else { return }
                guard let authenticationContext = self.context.authenticationService.activeAuthenticationContext.value else { return }
                
                Task {
                    do {
                        try await self.savedSearchViewModel.savedSearchService.fetchList(authenticationContext: authenticationContext)
                    } catch {
                        // do nothing
                    }
                    self.savedSearchViewModel.isSavedSearchFetched = true
                }
            }
            .store(in: &disposeBag)
        
        savedSearchViewModel.savedSearchFetchedResultController
            .$records
            .sink { [weak self] records in
                guard let self = self else { return }
                let texts: [String] = records.compactMap { record in
                    guard let object = record.object(in: self.context.managedObjectContext) else { return nil }
                    switch object {
                    case .twitter(let savedSearch):
                        return savedSearch.query
                    }
                }
                self.savedSearchTexts = Set(texts)
            }
            .store(in: &disposeBag)
    }
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}
