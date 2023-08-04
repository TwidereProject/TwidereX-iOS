//
//  TranslateButtonPreferenceView.swift
//  TwidereX
//
//  Created by MainasuK on 2022-4-1.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import Foundation
import SwiftUI

struct TranslateButtonPreferenceView: View {
    
    let logger = Logger(subsystem: "TranslateButtonPreferenceView", category: "View")
    
    var preference: UserDefaults.TranslateButtonPreference
        
    var body: some View {
        List {
            ForEach(UserDefaults.TranslateButtonPreference.allCases, id: \.rawValue) { preference in
                Button {
                    UserDefaults.shared.translateButtonPreference = preference
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): update TranslateButtonPreference: \(preference.text)")
                } label: {
                    HStack {
                        Text(preference.text)
                        if self.preference == preference {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
                .tint(Color(uiColor: .label))
            }   // end ForEach
        }
        .navigationBarTitle(Text(L10n.Scene.Settings.Appearance.Translation.translateButton))
    }   // end body
    
}

#if DEBUG
// Note:
// Preview cannot update the selection due to the UserDefaults value not bind to the Preference
struct TranslateButtonPreferenceView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TranslateButtonPreferenceView(preference: .auto)
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}
#endif
