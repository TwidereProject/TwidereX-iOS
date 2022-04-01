//
//  AppearanceView.swift
//  TwidereX
//
//  Created by MainasuK on 2022-4-1.
//  Copyright © 2022 Twidere. All rights reserved.
//

import SwiftUI
import TwidereLocalization
import TwidereUI

struct AppearanceView: View {
    
    @ObservedObject var viewModel: AppearanceViewModel
    
    @State private var isTranslateButtonPreferenceSheetPresented = false

    
    var appIconRow: some View {
        Button {
            
        } label: {
            HStack {
                Text(L10n.Scene.Settings.Appearance.appIcon)
                Spacer()
                Image(uiImage: viewModel.appIcon)
                    .cornerRadius(4)
            }
        }
        .tint(Color(uiColor: .label))
    }
    
    var body: some View {
        List {
            Section {
                appIconRow
            } header: {
                Text("")
            }
            Section {
                // Translate Button
                NavigationLink {
                    TranslateButtonPreferenceView(preference: viewModel.translateButtonPreference)
                } label: {
                    Text(L10n.Scene.Settings.Appearance.Translation.translateButton)
                        .tint(Color(uiColor: .label))
                        .badge(viewModel.translateButtonPreference.text)
                }
                // Service
                NavigationLink {
                    TranslationServicePreferenceView(preference: viewModel.translationServicePreference)
                } label: {
                    Text(L10n.Scene.Settings.Appearance.Translation.service)
                        .tint(Color(uiColor: .label))
                        .badge(viewModel.translationServicePreference.text)
                }
            } header: {
                Text(L10n.Scene.Settings.Appearance.SectionHeader.translation)
            }


        }
        .listStyle(InsetGroupedListStyle())
    }
}

#if DEBUG
struct AppearanceView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AppearanceView(viewModel: AppearanceViewModel(context: .shared))
                .navigationBarTitle(Text(L10n.Scene.Settings.Appearance.title))
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}
#endif
