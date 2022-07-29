//
//  DisplayPreferenceView.swift
//  TwidereX
//
//  Created by MainasuK on 2022-7-25.
//  Copyright © 2022 Twidere. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import TwidereCore
import TwidereUI
import TwidereLocalization
import AppShared

struct DisplayPreferenceView: View {
    
    @ObservedObject var viewModel: DisplayPreferenceViewModel
    
    @State var timelineStatusViewHeight: CGFloat = .zero
    @State var threadStatusViewHeight: CGFloat = .zero
    
    var body: some View {
        List {
            Section {
                PrototypeStatusViewRepresentable(
                    style: .timeline,
                    configurationContext: StatusView.ConfigurationContext(
                        dateTimeProvider: DateTimeSwiftProvider(),
                        twitterTextProvider: OfficialTwitterTextProvider(),
                        authenticationContext: viewModel.$authenticationContext
                    ),
                    height: $timelineStatusViewHeight
                )
                .frame(height: timelineStatusViewHeight)
            } header: {
                Text(verbatim: L10n.Scene.Settings.Display.SectionHeader.preview)
                    .textCase(nil)
            }
            
            // Avatar
            Section {
                avatarStylePicker
            } header: {
                Text(verbatim: "Avatar")        // TODO: i18n
            }   // end Section

            // Translation
            Section {
                // Translate Button
                Picker(selection: $viewModel.translateButtonPreference) {
                    ForEach(UserDefaults.TranslateButtonPreference.allCases, id: \.self) { preference in
                        Text(preference.text)
                    }
                } label: {
                    Text(L10n.Scene.Settings.Appearance.Translation.translateButton)
                }
                // Translate Service
                Picker(selection: $viewModel.translationServicePreference) {
                    ForEach(UserDefaults.TranslationServicePreference.allCases, id: \.self) { preference in
                        Text(preference.text)
                    }
                } label: {
                    Text(L10n.Scene.Settings.Appearance.Translation.service)
                }
            } header: {
                Text(verbatim: L10n.Scene.Settings.Appearance.SectionHeader.translation)
                    .textCase(nil)
            }
        }
    }
    
}

extension DisplayPreferenceView {
    
    var avatarStylePicker: some View {
        Picker(selection: $viewModel.avatarStyle) {
            ForEach(UserDefaults.AvatarStyle.allCases, id: \.self) { preference in
                Text(preference.text)
            }
        } label: {
            Text(L10n.Scene.Settings.Display.Text.avatarStyle)
        }
    }
    
}
