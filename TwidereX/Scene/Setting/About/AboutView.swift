//
//  AboutView.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-12.
//  Copyright © 2020 Twidere. All rights reserved.
//

import SwiftUI
import TwidereAsset
import TwidereUI

enum AboutEntryType: Identifiable, Hashable, CaseIterable {
    
    case github
    case twitter
    case telegram
    case discord
    case license
    case privacyPolicy
    
    var id: AboutEntryType { return self }
    
    public var text: String {
        switch self {
        case .github:           return "GitHub"
        case .twitter:          return "Twitter"
        case .telegram:         return "Telegram"
        case .discord:          return "Discord"
        case .license:          return "License"
        case .privacyPolicy:    return "Privacy Policy"
        }
    }
    
}

struct AboutView: View {
    
    @EnvironmentObject var context: AppContext
    @ObservedObject var manager = MotionManager()
    
    var body: some View {
        VStack {
            HStack {
                Image(Asset.Logo.twidere.name, bundle: TwidereAsset.bundle)    // needs set bundle for package asset
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 48, height: 48)
                Text("Twidere X")
                    .font(.system(size: 32, weight: .medium))
                    .opacity(0.6)
                Spacer()
            }
            .modifier(TextCaseEraseStyle())
            .frame(maxWidth: .infinity)
            .padding()
            // Spacer()
            VStack(alignment: .leading, spacing: 24) {
                Spacer()
                VStack(alignment: .leading, spacing: 16) {
                    Text(UIApplication.versionBuild())
                        .font(.subheadline)
                    Text("Next generation of Twidere for iOS")
                        .font(.headline)
                }
                .foregroundColor(Color(uiColor: .secondaryLabel))
                HStack(alignment: .center, spacing: 24) {
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
                    Button(action: {
                        context.viewStateStore.aboutView.aboutEntryPublisher.send(.telegram)
                    }, label: {
                        Image(Asset.Logo.telegramCircle.name, bundle: TwidereAsset.bundle)
                            .renderingMode(.template)
                            .foregroundColor(.secondary)
                    })
                    Button(action: {
                        context.viewStateStore.aboutView.aboutEntryPublisher.send(.discord)
                    }, label: {
                        Image(Asset.Logo.discordCircle.name, bundle: TwidereAsset.bundle)
                            .renderingMode(.template)
                            .foregroundColor(.secondary)
                    })
                    Spacer()
                }   // end logo stack
                HStack(spacing: 20) {
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
                    Spacer()
                }   // end Button stack
            }   // end VStack
            .padding()
        }
        .background {
            GeometryReader { proxy in
                VStack {
                    ZStack {
                        Image(Asset.Scene.About.backgroundLogo.name, bundle: TwidereAsset.bundle)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .offset(x: proxy.size.width / 3)
                            .modifier(ParallaxMotionModifier(manager: manager, magnitude: 10))
                        Image(Asset.Scene.About.backgroundLogoShadow.name, bundle: TwidereAsset.bundle)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .offset(x: proxy.size.width / 3 - 40, y: 40)
                            .modifier(ParallaxMotionModifier(manager: manager, magnitude: 20))
                    }
                    Spacer()
                }
            }
        }
    }
    
}

#if DEBUG

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AboutView()
            AboutView()
                .preferredColorScheme(.dark)
            AboutView()
                .previewDevice("iPhone SE")
            AboutView()
                .previewDevice("iPhone 13 mini")
            AboutView()
                .previewDevice("iPhone 8")
            AboutView()
                .previewDevice("iPad mini (6th generation)")
        }
    }
}

#endif
