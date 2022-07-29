//
//  BehaviorsPreferenceView.swift
//  TwidereX
//
//  Created by MainasuK on 2022-7-27.
//  Copyright © 2022 Twidere. All rights reserved.
//

import SwiftUI
import TwidereLocalization
import TwidereUI

struct BehaviorsPreferenceView: View {
    
    @ObservedObject var viewModel: BehaviorsPreferenceViewModel
    
    var body: some View {
        List {
            // Tab Bar
            Section {
                Toggle(isOn: $viewModel.preferredTabBarLabelDisplay) {
                    Text(verbatim: "Show tab bar labels")       // TODO: i18n
                }
                Picker(selection: $viewModel.tabBarTapScrollPreference) {
                    ForEach(UserDefaults.TabBarTapScrollPreference.allCases, id: \.self) { preference in
                        Text(preference.title)
                    }
                } label: {
                    Text(verbatim: "Tap tab bar scroll to top")     // TODO: i18n
                }
            } header: {
                Text(verbatim: "Tab Bar")       // TODO: i18n
                    .textCase(nil)
            }
            // Timeline Refreshing
            Section {
                Toggle(isOn: $viewModel.preferredTimelineAutoRefresh) {
                    Text(verbatim: "Automatically refresh timeline")        // TODO: i18n
                }
                Picker(selection: $viewModel.timelineRefreshInterval) {
                    ForEach(UserDefaults.TimelineRefreshInterval.allCases, id: \.self) { preference in
                        Text(preference.title)
                    }
                } label: {
                    Text(verbatim: "Refresh Interval")        // TODO: i18n

                }
                Toggle(isOn: $viewModel.preferredTimelineResetToTop) {
                    Text(verbatim: "Reset to top")       // TODO: i18n
                }
            } header: {
                Text(verbatim: "Timeline Refreshing")       // TODO: i18n
                    .textCase(nil)
            }
        }
    }

}
