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
import TwitterSDK

final class SearchViewModel {
    
    let logger = Logger(subsystem: "SearchViewModel", category: "ViewModel")
    
    var disposeBag = Set<AnyCancellable>()
    var observations = Set<NSKeyValueObservation>()
    
    // input
    let context: AppContext
    let authContext: AuthContext
    let savedSearchViewModel: SavedSearchViewModel
    let trendViewModel: TrendViewModel
    let viewDidAppear = PassthroughSubject<Void, Never>()
    
    // output
    var diffableDataSource: UITableViewDiffableDataSource<SearchSection, SearchItem>?
    @Published var savedSearchTexts = Set<String>()

    init(
        context: AppContext,
        authContext: AuthContext
    ) {
        self.context = context
        self.authContext = authContext
        self.savedSearchViewModel = SavedSearchViewModel(context: context, authContext: authContext)
        self.trendViewModel = TrendViewModel(context: context, authContext: authContext)
        // end init
        
        viewDidAppear
            .sink { [weak self] _ in
                guard let self = self else { return }
                guard let authenticationContext = self.context.authenticationService.activeAuthenticationContext else { return }
                
                Task {
                    do {
                        try await self.savedSearchViewModel.savedSearchService.fetchList(authenticationContext: authenticationContext)
                        self.savedSearchViewModel.isSavedSearchFetched = true
                    } catch {
                        // do nothing
                    }
                }
            }
            .store(in: &disposeBag)
        
        Publishers.CombineLatest(
            trendViewModel.$trendGroupIndex,
            viewDidAppear
        )
        .sink { [weak self] trendGroupIndex, _ in
            guard let self = self else { return }
            guard let authenticationContext = self.context.authenticationService.activeAuthenticationContext else { return }
            
            Task { @MainActor in 
                do {
                    try await self.trendViewModel.trendService.fetchTrend(
                        index: trendGroupIndex,
                        authenticationContext: authenticationContext
                    )
                    self.trendViewModel.isTrendFetched = true
                } catch {
                    // do nothing
                }
            }   // end Task
        }
        .store(in: &disposeBag)
        
        viewDidAppear
            .sink { [weak self] _ in
                guard let self = self else { return }
                Task {
                    try await self.trendViewModel.fetchTrendPlaces()
                }   // end Task
            }
            .store(in: &disposeBag)
        
        savedSearchViewModel.savedSearchFetchedResultController.$records
            .sink { [weak self] records in
                guard let self = self else { return }
                let texts: [String] = records.compactMap { record in
                    guard let object = record.object(in: self.context.managedObjectContext) else { return nil }
                    switch object {
                    case .twitter(let savedSearch):
                        return savedSearch.query
                    case .mastodon(let savedSearch):
                        return savedSearch.query
                    }
                }
                self.savedSearchTexts = Set(texts)
            }
            .store(in: &disposeBag)
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}
