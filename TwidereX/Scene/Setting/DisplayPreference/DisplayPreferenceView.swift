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

struct DisplayPreferenceView: View {
    
    @ObservedObject var viewModel: DisplayPreferenceViewModel
    
    @State var threadStatusViewHeight: CGFloat = .zero
    
    var body: some View {
        List {
            Section {
                StatusView(viewModel: StatusView.ViewModel.prototype(
                    viewLayoutFramePublisher: viewModel.$viewLayoutFrame
                ))
//                PrototypeStatusViewRepresentable(
//                    style: .timeline,
//                    configurationContext: StatusView.ConfigurationContext(
//                        authContext: viewModel.authContext,
//                        dateTimeProvider: DateTimeSwiftProvider(),
//                        twitterTextProvider: OfficialTwitterTextProvider()
//                    ),
//                    height: $timelineStatusViewHeight
//                )
            } header: {
                Text(verbatim: L10n.Scene.Settings.Display.SectionHeader.preview)
                    .textCase(nil)
            }
            
            // Avatar
            Section {
                avatarStylePicker
            } header: {
                Text(verbatim: L10n.Scene.Settings.Display.SectionHeader.avatar)
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
