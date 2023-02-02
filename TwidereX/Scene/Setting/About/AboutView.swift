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

struct AboutView: View {
    
    @EnvironmentObject var context: AppContext
    @ObservedObject var viewModel: AboutViewModel
    @StateObject var manager = MotionManager()
    
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
                        viewModel.entryPublisher.send(.twitter)
                    }, label: {
                        Image(Asset.Logo.twitterCircle.name, bundle: TwidereAsset.bundle)
                            .renderingMode(.template)
                            .foregroundColor(.secondary)
                    })
                    Button(action: {
                        viewModel.entryPublisher.send(.github)
                    }, label: {
                        Image(Asset.Logo.githubCircle.name, bundle: TwidereAsset.bundle)
                            .renderingMode(.template)
                            .foregroundColor(.secondary)
                    })
                    Button(action: {
                        viewModel.entryPublisher.send(.telegram)
                    }, label: {
                        Image(Asset.Logo.telegramCircle.name, bundle: TwidereAsset.bundle)
                            .renderingMode(.template)
                            .foregroundColor(.secondary)
                    })
                    Button(action: {
                        viewModel.entryPublisher.send(.discord)
                    }, label: {
                        Image(Asset.Logo.discordCircle.name, bundle: TwidereAsset.bundle)
                            .renderingMode(.template)
                            .foregroundColor(.secondary)
                    })
                    Spacer()
                }   // end logo stack
                HStack(spacing: 20) {
                    Button(action: {
                        viewModel.entryPublisher.send(.license)
                    }, label: {
                        Text(AboutViewModel.Entry.license.text)
                    })
                    Button(action: {
                        viewModel.entryPublisher.send(.privacyPolicy)
                    }, label: {
                        Text(AboutViewModel.Entry.privacyPolicy.text)
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
            if let authContext = AuthContext.mock(context: AppContext.shared) {
                AboutView(viewModel: AboutViewModel(authContext: authContext))
                AboutView(viewModel: AboutViewModel(authContext: authContext))
                    .preferredColorScheme(.dark)
                AboutView(viewModel: AboutViewModel(authContext: authContext))
                    .previewDevice("iPhone SE")
                AboutView(viewModel: AboutViewModel(authContext: authContext))
                    .previewDevice("iPhone 13 mini")
                AboutView(viewModel: AboutViewModel(authContext: authContext))
                    .previewDevice("iPhone 8")
                AboutView(viewModel: AboutViewModel(authContext: authContext))
                    .previewDevice("iPad mini (6th generation)")
            }
        }   // end Group
    }
}

#endif
