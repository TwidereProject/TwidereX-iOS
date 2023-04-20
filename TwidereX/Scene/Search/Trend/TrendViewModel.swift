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
import TwitterSDK

final class TrendViewModel: ObservableObject {
    
    let logger = Logger(subsystem: "TrendViewModel", category: "ViewModel")
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let authContext: AuthContext
    let trendService: TrendService
    @Published var trendGroupIndex: TrendService.TrendGroupIndex = .none
    @Published var searchText = ""

    // output
    var diffableDataSource: UITableViewDiffableDataSource<SearchSection, SearchItem>?
    @Published var isTrendFetched = false
    @Published var twitterTrendPlaces: [Twitter.Entity.Trend.Place] = []
    @Published var trendPlaceName: String?

    let activeTwitterTrendPlacePublisher = PassthroughSubject<Twitter.Entity.Trend.Place, Never>()
    
    init(
        context: AppContext,
        authContext: AuthContext
    ) {
        self.context = context
        self.authContext = authContext
        self.trendService = TrendService(apiService: context.apiService)
        // end init
        
        switch authContext.authenticationContext {
        case .twitter:
            let placeID = TrendViewModel.defaultTwitterTrendPlace?.woeid ?? 1 // fallback to world-wide "1"
            self.trendGroupIndex = .twitter(placeID: placeID)
        case .mastodon(let authenticationContext):
            self.trendGroupIndex = .mastodon(domain: authenticationContext.domain)
        case nil:
            self.trendGroupIndex = .none
        }
        
        Publishers.CombineLatest(
            $trendGroupIndex,
            $twitterTrendPlaces
        )
        .map { trendGroupIndex, twitterTrendPlaces in
            switch trendGroupIndex {
            case .none:
                return nil
            case .twitter(let placeID):
                let _place = twitterTrendPlaces
                    .first(where: { $0.woeid == placeID })
                let name = _place?.name ?? TrendViewModel.defaultTwitterTrendPlace?.name ?? L10n.Scene.Trends.worldWideWithoutPrefix
                return name
            case .mastodon:
                return nil
            }
        }
        .assign(to: &$trendPlaceName)
    }
    
}


extension TrendViewModel {
    func fetchTrendPlaces() async throws {
        guard twitterTrendPlaces.isEmpty else { return }
        guard case let .twitter(authenticationContext) = authContext.authenticationContext else { return }
        let response = try await context.apiService.twitterTrendPlaces(authenticationContext: authenticationContext)
        twitterTrendPlaces = response.value
            .filter { $0.parentID == 1 }
            .sorted(by: { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending })
    }
}

extension TrendViewModel {
    
    // reset to worldwide
    func resetTrendGroupIndex() {
        TrendViewModel.defaultTwitterTrendPlace = nil
        trendGroupIndex = .twitter(placeID: 1)      // worldwide
    }

    // set place
    func updateTrendGroupIndex(place: Twitter.Entity.Trend.Place) {
        TrendViewModel.defaultTwitterTrendPlace = place
        trendGroupIndex = .twitter(placeID: place.woeid)
    }
    
    static var defaultTwitterTrendPlace: Twitter.Entity.Trend.Place? {
        get {
            guard let data = UserDefaults.shared.data(forKey: #function),
                  let place = try? JSONDecoder().decode(Twitter.Entity.Trend.Place.self, from: data)
            else { return nil }
            return place
        }
        set {
            let data: Data? = newValue.flatMap { place in
                let data = try? JSONEncoder().encode(place)
                return data
            }
            UserDefaults.shared[#function] = data
        }
    }
}
