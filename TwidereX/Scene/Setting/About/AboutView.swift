//
//  AboutView.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-12.
//  Copyright © 2020 Twidere. All rights reserved.
//

import SwiftUI

enum AboutEntryType: Identifiable, Hashable, CaseIterable {
    
    case github
    case twitter
    case license
    case privacyyPolicy
    
    var id: AboutEntryType { return self }
    
    var text: String {
        switch self {
        case .github:           return "GitHub"
        case .twitter:          return "Twitter"
        case .license:          return "License"
        case .privacyyPolicy:   return "Privacy Policy"
        }
    }
    
}

struct AboutView: View {
    
    @EnvironmentObject var context: AppContext
    
    var body: some View {
        VStack {
            VStack {
                Image(uiImage: Asset.Logo.twidere.image)
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
                    Image(uiImage: Asset.Logo.twitterCircle.image.withRenderingMode(.alwaysTemplate))
                        .foregroundColor(.secondary)
                })
                Button(action: {
                    context.viewStateStore.aboutView.aboutEntryPublisher.send(.github)
                }, label: {
                    Image(uiImage: Asset.Logo.githubCircle.image.withRenderingMode(.alwaysTemplate))
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
                    context.viewStateStore.aboutView.aboutEntryPublisher.send(.privacyyPolicy)
                }, label: {
                    Text(AboutEntryType.privacyyPolicy.text)
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
