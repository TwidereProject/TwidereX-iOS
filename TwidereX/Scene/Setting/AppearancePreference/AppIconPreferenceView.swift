//
//  AppIconPreferenceView.swift
//  TwidereX
//
//  Created by MainasuK on 2022-4-2.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import Foundation
import SwiftUI
import TwidereCommon

struct AppIconPreferenceView: View {
    
    let logger = Logger(subsystem: "AppIconPreferenceView", category: "View")
        
    var items: [GridItem] {
        return [
            GridItem(.adaptive(minimum: 88, maximum: 88), spacing: 16)
        ]
    }
        
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            Color.clear
                .frame(height: 20)
            LazyVGrid(columns: items, spacing: 20) {
                ForEach(AppIcon.allCases, id: \.rawValue) { appIcon in
                    Button {
                        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): update alternateIconNamePreference: \(appIcon.text)")
                        // configure alternative app icon
                        UserDefaults.shared.alternateIconNamePreference = appIcon
                        UIApplication.shared.setAlternateIconName(appIcon == .twidere ? nil : appIcon.iconName)
                    } label: {
                        VStack {
                            let assetName = "icons/\(appIcon.iconName)"
                            Image(uiImage: UIImage(named: assetName) ?? UIImage())
                                .resizable()
                                .frame(width: 88, height: 88, alignment: .center)
                                .cornerRadius(10)
                            Text(appIcon.text)
                                .font(.system(.footnote, design: .default))
                        }
                    }
                    .tint(Color(uiColor: .label))
                }   // end ForEach
            }
        }
        .background(Color(uiColor: .secondarySystemBackground))
        .navigationTitle(L10n.Scene.Settings.Appearance.appIcon)
    }   // end body
    
}

#if DEBUG
struct AppIconPreferenceView_Previews: PreviewProvider {
    
    static var contentView: some View {
        AppIconPreferenceView()
    }
    
    static var previews: some View {
        Group {
            contentView.previewDevice("iPhone X")
            contentView.previewDevice("iPhone 8")
            contentView.previewDevice("iPhone 8 Plus")
            contentView.previewDevice("iPhone 13 mini")
            contentView.previewDevice("iPhone 13")
            contentView.previewDevice("iPhone 13 Pro")
            contentView.previewDevice("iPhone 13 Pro Max")
            contentView.previewDevice("iPad Air (4th generation)")
        }
    }
}
#endif
