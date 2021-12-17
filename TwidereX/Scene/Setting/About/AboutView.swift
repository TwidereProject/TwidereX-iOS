//
//  AboutView.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-12.
//  Copyright © 2020 Twidere. All rights reserved.
//

import SwiftUI
import TwidereAsset

enum AboutEntryType: Identifiable, Hashable, CaseIterable {
    
    case github
    case twitter
    case license
    case privacyPolicy
    
    var id: AboutEntryType { return self }
    
    public var text: String {
        switch self {
        case .github:           return "GitHub"
        case .twitter:          return "Twitter"
        case .license:          return "License"
        case .privacyPolicy:    return "Privacy Policy"
        }
    }
    
}

struct AboutView: View {
    
    @EnvironmentObject var context: AppContext
    
    var body: some View {
        VStack {
            VStack {
                Image(Asset.Scene.About.twidereLarge.name, bundle: TwidereAsset.bundle)    // needs set bundle for package asset
                    .renderingMode(.original)
                    .padding(44)
                Text("Twidere X")
                    .font(.headline)
                Text(UIApplication.versionBuild())
                    .font(.subheadline)
            }
            .modifier(TextCaseEraseStyle())
            .frame(maxWidth: .infinity)
            .padding(EdgeInsets(top: 0, leading: 0, bottom: 20, trailing: 0))
            Divider()
                .padding(EdgeInsets(top: 44, leading: 44, bottom: 44, trailing: 44))
            HStack(alignment: .center, spacing: 36) {
                Button(action: {
                    context.viewStateStore.aboutView.aboutEntryPublisher.send(.twitter)
                }, label: {
                    Image(Asset.Logo.twitterCircle.name, bundle: TwidereAsset.bundle)
                        .renderingMode(.template)
                        .foregroundColor(.secondary)
                })
                Button(action: {
                    context.viewStateStore.aboutView.aboutEntryPublisher.send(.github)
                }, label: {
                    Image(Asset.Logo.githubCircle.name, bundle: TwidereAsset.bundle)
                        .renderingMode(.template)
                        .foregroundColor(.secondary)
                })
            }
            Spacer()
            Spacer()
            Spacer()
            VStack(alignment: .center, spacing: 16) {
                Button(action: {
                    context.viewStateStore.aboutView.aboutEntryPublisher.send(.license)
                }, label: {
                    Text(AboutEntryType.license.text)
                })
                Button(action: {
                    context.viewStateStore.aboutView.aboutEntryPublisher.send(.privacyPolicy)
                }, label: {
                    Text(AboutEntryType.privacyPolicy.text)
                })
            }
            Spacer()
        }
    }
    
}

#if DEBUG

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AboutView()
            AboutView()
                .previewDevice("iPhone SE")
            AboutView()
                .preferredColorScheme(.dark)
        }
    }
}

#endif
