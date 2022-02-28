//
//  TrendViewModel.swift
//  TwidereX
//
//  Created by MainasuK on 2021-12-28.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import TwidereCore

final class TrendViewModel {
    
    let logger = Logger(subsystem: "TrendViewModel", category: "ViewModel")
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let trendService: TrendService
    @Published var trendGroupIndex: TrendService.TrendGroupIndex = .none

    // output
    var diffableDataSource: UITableViewDiffableDataSource<SearchSection, SearchItem>?
    @Published var isTrendFetched = false

    init(context: AppContext) {
        self.context = context
        self.trendService = TrendService(apiService: context.apiService)
        // end init
        
        context.authenticationService.$activeAuthenticationContext
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] authenticationContext in
                guard let self = self else { return }
                
                switch authenticationContext {
                case .twitter:
                    self.trendGroupIndex = .twitter(placeID: 1)         // default world wide
                case .mastodon(let authenticationContext):
                    self.trendGroupIndex = .mastodon(domain: authenticationContext.domain)
                case nil:
                    self.trendGroupIndex = .none
                }
            }
            .store(in: &disposeBag)
    }
    
}
