//
//  BehaviorsPreferenceView.swift
//  TwidereX
//
//  Created by MainasuK on 2022-7-27.
//  Copyright © 2022 Twidere. All rights reserved.
//

import SwiftUI
import TwidereLocalization

struct BehaviorsPreferenceView: View {
    
    @ObservedObject var viewModel: BehaviorsPreferenceViewModel
    
    var body: some View {
        List {
            // Tab Bar
            Section {
                Toggle(isOn: $viewModel.preferredTabBarLabelDisplay) {
                    Text(verbatim: L10n.Scene.Settings.Behaviors.TabBarSection.showTabBarLabels)
                }
                Picker(selection: $viewModel.tabBarTapScrollPreference) {
                    ForEach(UserDefaults.TabBarTapScrollPreference.allCases, id: \.self) { preference in
                        Text(preference.title)
                    }
                } label: {
                    Text(verbatim: L10n.Scene.Settings.Behaviors.TabBarSection.tapTabBarScrollToTop)
                }
            } header: {
                Text(verbatim: L10n.Scene.Settings.Behaviors.TabBarSection.tabBar)
                    .textCase(nil)
            }
            // Timeline Refreshing
            Section {
                Toggle(isOn: $viewModel.preferredTimelineAutoRefresh) {
                    Text(verbatim: L10n.Scene.Settings.Behaviors.TimelineRefreshingSection.automaticallyRefreshTimeline)
                }
                if viewModel.preferredTimelineAutoRefresh {
                    Picker(selection: $viewModel.timelineRefreshInterval) {
                        ForEach(UserDefaults.TimelineRefreshInterval.allCases, id: \.self) { preference in
                            Text(preference.title)
                        }
                    } label: {
                        Text(verbatim: L10n.Scene.Settings.Behaviors.TimelineRefreshingSection.refreshInterval)
                    }
                }
                Toggle(isOn: $viewModel.preferredTimelineResetToTop) {
                    Text(verbatim: L10n.Scene.Settings.Behaviors.TimelineRefreshingSection.resetToTop)
                }
            } header: {
                Text(verbatim: L10n.Scene.Settings.Behaviors.TimelineRefreshingSection.timelineRefreshing)
                    .textCase(nil)
            }
            // History
            Section {
                Toggle(isOn: $viewModel.preferredEnableHistory) {
                    Text(verbatim: L10n.Scene.Settings.Behaviors.HistorySection.enableHistoryRecord)
                }
            } header: {
                Text(verbatim: L10n.Scene.Settings.Behaviors.HistorySection.history)
                    .textCase(nil)
            }
        }
    }

}
