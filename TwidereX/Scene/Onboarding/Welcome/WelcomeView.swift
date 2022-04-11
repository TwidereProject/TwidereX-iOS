//
//  WelcomeView.swift
//  WelcomeView
//
//  Created by Cirno MainasuK on 2021-8-11.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import SwiftUI
import Introspect
import TwidereAsset
import TwidereLocalization

struct WelcomeView: View {
    
    let logger = Logger(subsystem: "WelcomeView", category: "UI")

    let logoTextColor = UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .dark:     return .lightGray
        default:        return .darkGray
        }
    }
    
    @EnvironmentObject var viewModel: WelcomeViewModel
    
    // Not works in iOS Beta 5
    // @FocusState private var isMastodonDomainFieldFocused: Bool
    
    var body: some View {
        VStack {
            HStack {
                // not use UIImage init method here
                // only .init(_:bundle:) works with the dynamic Dark Mode asset
                Image(decorative: Asset.Logo.twidere.name, bundle: TwidereAsset.bundle)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 48, height: 48)
                Text("Twidere X")
                    .font(.system(size: 32, weight: .medium, design: .default))
                    .foregroundColor(Color(uiColor: logoTextColor))
                Spacer()
            }
            Spacer()
            Text(L10n.Scene.SignIn.helloSignInToGetStarted)
                .foregroundColor(Color(Asset.Colors.Theme.daylight.color))
                .font(.system(size: 48, weight: .bold, design: .default))
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()
            Spacer()
            VStack(spacing: 20) {
                switch viewModel.authenticateMode {
                case .normal:
                    TwitterAuthenticateButton(
                        isBusy: viewModel.isAuthenticateTwitter,
                        primaryAction: {
                            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): TwitterAuthenticateButton.primaryAction: authenticate Twitter…")
                            Task {
                                await viewModel.authenticateTwitter()
                            }
                        }, secondaryAction: {
                            viewModel.delegate?.presentTwitterAuthenticationOption()
                        }
                    )
                    .disabled(viewModel.isBusy)
                case .mastodon:
                    TextField(
                        "example.com",
                        text: $viewModel.mastodonDomain,
                        onCommit: {
                            Task {
                                await viewModel.authenticateMastodon()
                            }
                        }
                    )
                    .accessibilityHint(L10n.Accessibility.Scene.SignIn.pleaseEnterMastodonDomainToSignIn)
                    .textFieldStyle(PlainTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .keyboardType(.URL)
                    .submitLabel(.go)
                    .frame(height: 48)
                    .padding(.horizontal, 18 + 2)   // extra 2pt overshoot
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(lineWidth: 1)
                            .foregroundColor(Color(Asset.Colors.Theme.daylight.color))
                    )
                    .cornerRadius(10)
                    .introspectTextField { textField in
                        DispatchQueue.main.async {
                            textField.becomeFirstResponder()
                        }
                    }
                }
                MastodonAuthenticateButton(
                    isBusy: viewModel.isAuthenticateMastodon,
                    isFocus: viewModel.authenticateMode == .mastodon,
                    primaryAction: {
                        Task {
                            await viewModel.authenticateMastodon()
                        }
                    }
                )
                .disabled(viewModel.isBusy)
            }
            .padding(.bottom, 20)
        }
        .modifier(ReadabilityPadding(isEnabled: true))
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        let configuration = WelcomeViewModel.Configuration(allowDismissModal: false)
        WelcomeView().environmentObject(WelcomeViewModel(context: AppContext.shared, configuration: configuration))
    }
}

struct TwitterAuthenticateButton: View {
    
    let isBusy: Bool
    let primaryAction: () -> Void
    let secondaryAction: () -> Void
    
    var body: some View {
        HStack {
            Button {
                primaryAction()
            } label: {
                HStack {
                    Image(decorative: Asset.Logo.twitter.name, bundle: TwidereAsset.bundle)
                        .renderingMode(.template)
                    Spacer()
                    if isBusy {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(L10n.Scene.SignIn.signInWithTwitter)
                            .font(.system(size: 16, weight: .regular, design: .default))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Spacer()
                }
                .padding(.leading, 18)
            }
            Button {
                secondaryAction()
            } label: {
                Image(
                    Asset.Editing.ellipsis.name, bundle: TwidereAsset.bundle,
                    label: Text(L10n.Accessibility.Scene.SignIn.twitterClientAuthenticationKeySetting)
                )
                .renderingMode(.template)
                .padding(.horizontal, 18)
            }
        }
        .frame(height: 48)
        .foregroundColor(.white)
        .background(Color(Asset.Colors.Theme.daylight.color))
        .cornerRadius(10)
    }
}

struct MastodonAuthenticateButton: View {
    
    let isBusy: Bool
    let isFocus: Bool
    let primaryAction: () -> Void

    var body: some View {
        let foregroundColor: Color = isFocus ? .white : Color(Asset.Colors.Theme.daylight.color)
        Button {
            primaryAction()
        } label: {
            HStack {
                Image(decorative: Asset.Logo.mastodon.name, bundle: TwidereAsset.bundle)
                    .renderingMode(.template)
                Spacer()
                if isBusy {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: foregroundColor))
                } else {
                    Text(L10n.Scene.SignIn.signInWithMastodon)
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Spacer()
                Image(decorative: Asset.Arrows.arrowRight.name, bundle: TwidereAsset.bundle)
                    .renderingMode(.template)
            }
            .padding(.horizontal, 18)
        }
        .frame(height: 48)
        .foregroundColor(foregroundColor)
        .background(buttonBackground.foregroundColor(Color(Asset.Colors.Theme.daylight.color)))
        .cornerRadius(10)
    }
    
    @ViewBuilder
    var buttonBackground: some View {
        let background = RoundedRectangle(cornerRadius: 10)

        if isFocus {
            background
        } else {
            background
                .stroke(lineWidth: 1)
        }
    }
}
