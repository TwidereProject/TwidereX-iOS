//
//  BehaviorsPreferenceViewModel.swift
//  TwidereX
//
//  Created by MainasuK on 2022-7-27.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import UIKit
import SwiftUI
import Combine
import CoreDataStack
import TwidereCommon
import TwidereCore
import TwitterSDK
import MastodonSDK

final class BehaviorsPreferenceViewModel: ObservableObject {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    
    // Tab Bar
    @Published var preferredTabBarLabelDisplay = UserDefaults.shared.preferredTabBarLabelDisplay
    @Published var tabBarTapScrollPreference = UserDefaults.shared.tabBarTapScrollPreference
    
    // Timeline Refreshing
    @Published var preferredTimelineAutoRefresh = UserDefaults.shared.preferredTimelineAutoRefresh
    @Published var timelineRefreshInterval = UserDefaults.shared.timelineRefreshInterval
    @Published var preferredTimelineResetToTop = UserDefaults.shared.preferredTimelineResetToTop
    
    // History
    @Published var preferredEnableHistory = UserDefaults.shared.preferredEnableHistory

    // output    
    
    init(
        context: AppContext
    ) {
        self.context = context
        // end init

        // preferredTabBarLabelDisplay
        UserDefaults.shared.publisher(for: \.preferredTabBarLabelDisplay)
            .removeDuplicates()
            .assign(to: &$preferredTabBarLabelDisplay)
        $preferredTabBarLabelDisplay
            .sink { preferredTabBarLabelDisplay in
                UserDefaults.shared.preferredTabBarLabelDisplay = preferredTabBarLabelDisplay
            }
            .store(in: &disposeBag)
        
        // tabBarTapScrollPreference
        UserDefaults.shared.publisher(for: \.tabBarTapScrollPreference)
            .removeDuplicates()
            .assign(to: &$tabBarTapScrollPreference)
        $tabBarTapScrollPreference
            .sink { tabBarTapScrollPreference in
                UserDefaults.shared.tabBarTapScrollPreference = tabBarTapScrollPreference
            }
            .store(in: &disposeBag)
        
        // preferredTimelineAutoRefresh
        UserDefaults.shared.publisher(for: \.preferredTimelineAutoRefresh)
            .removeDuplicates()
            .assign(to: &$preferredTimelineAutoRefresh)
        $preferredTimelineAutoRefresh
            .sink { preferredTimelineAutoRefresh in
                UserDefaults.shared.preferredTimelineAutoRefresh = preferredTimelineAutoRefresh
            }
            .store(in: &disposeBag)
        
        // timelineRefreshInterval
        UserDefaults.shared.publisher(for: \.timelineRefreshInterval)
            .removeDuplicates()
            .assign(to: &$timelineRefreshInterval)
        $timelineRefreshInterval
            .sink { timelineRefreshInterval in
                UserDefaults.shared.timelineRefreshInterval = timelineRefreshInterval
            }
            .store(in: &disposeBag)
        
        // preferredTimelineResetToTop
        UserDefaults.shared.publisher(for: \.preferredTimelineResetToTop)
            .removeDuplicates()
            .assign(to: &$preferredTimelineResetToTop)
        $preferredTimelineResetToTop
            .sink { preferredTimelineResetToTop in
                UserDefaults.shared.preferredTimelineResetToTop = preferredTimelineResetToTop
            }
            .store(in: &disposeBag)
        
        // preferredEnableHistory
        UserDefaults.shared.publisher(for: \.preferredEnableHistory)
            .removeDuplicates()
            .assign(to: &$preferredEnableHistory)
        $preferredEnableHistory
            .sink { preferredEnableHistory in
                UserDefaults.shared.preferredEnableHistory = preferredEnableHistory
            }
            .store(in: &disposeBag)
    }
    
}

extension UserDefaults.TabBarTapScrollPreference {
    var title: String {
        switch self {
        case .single:       return "Single Tap"
        case .double:       return "Double Tap"
        }
    }
}

extension UserDefaults.TimelineRefreshInterval {
    var title: String {
        switch self {
        case ._30s:         return "30 seconds"
        case ._60s:         return "60 seconds"
        case ._120s:        return "120 seconds"
        case ._300s:        return "300 seconds"
        }
    }
}
