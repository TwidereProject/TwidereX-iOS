//
//  ComposeContentToolbarView.swift
//  
//
//  Created by MainasuK on 2022-5-20.
//

import os.log
import UIKit
import SwiftUI
import TwidereCore
import TwidereAsset
import TwidereLocalization
import Introspect
import TwitterSDK
import MastodonSDK

public struct ComposeContentToolbarView: View {
    
    static let toolbarMargin: CGFloat = 12
    
    @ObservedObject var viewModel: ComposeContentViewModel
            
    public var body: some View {
        VStack(spacing: .zero) {
            HStack(spacing: .zero) {
                // iput limit indicator
                inputLimitIndicatorView
                Divider()
                    .frame(width: 1, height: 24)
                // replySettings | visibility menu button
                switch viewModel.author {
                case .twitter:
                    twitterReplySettingsMenuButton
                case .mastodon:
                    mastodonVisibilityMenuButton
                case .none:
                    EmptyView()
                }
                Spacer()
                // content warning
                switch viewModel.author {
                case .twitter:
                    EmptyView()
                case .mastodon:
                    Button {
                        viewModel.isContentWarningComposing.toggle()
                        if viewModel.isContentWarningComposing {
                            Task { @MainActor in
                                try? await Task.sleep(nanoseconds: .second / 20)     // 0.05s
                                viewModel.setContentWarningTextViewFirstResponderIfNeeds()
                            }   // end Task
                        } else {
                            if viewModel.contentWarningMetaText?.textView.isFirstResponder == true {
                                viewModel.setContentTextViewFirstResponderIfNeeds()
                            }
                        }
                    } label: {
                        VectorImageView(
                            image: ComposeContentToolbarView.Action.contentWarning.image(of: .normal).withRenderingMode(.alwaysTemplate),
                            tintColor: viewModel.isContentWarningComposing ? .tintColor : .secondaryLabel
                        )
                        .frame(width: 24, height: 24)
                        .padding(12)
                    }
                case .none:
                    EmptyView()
                }
            }
            .padding(.horizontal, ComposeContentToolbarView.toolbarMargin)
            .frame(height: 48, alignment: .center)
            Divider()
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: .zero) {
                    ForEach(ComposeContentToolbarView.Action.allCases, id: \.self) { action in
                        if viewModel.availableActions.contains(action) {
                            view(for: action)
                        }   // end if
                    }   // end ForEach
                    Spacer()
                }   // end HStack
                .padding(.horizontal, ComposeContentToolbarView.toolbarMargin)
            }   // end ScrollView
            .zIndex(999)
            .introspectScrollView { scrollView in
                Task {
                    scrollView.alwaysBounceHorizontal = false
                    scrollView.delaysContentTouches = false
                }
            }
        }
        .background(Color(uiColor: .systemBackground))
    }
    
    var inputLimitIndicatorView: some View {
        HStack {
            let textWeightedLength = viewModel.isContentWarningComposing ? (viewModel.contentWeightedLength + viewModel.contentWarningWeightedLength) : viewModel.contentWeightedLength
            let value = Double(textWeightedLength)
            let total = Double(viewModel.maxTextInputLimit)
            let progress = total == .zero ? 0 : value / total
            ProgressView(
                value: min(value, total),       // clump to 1.0
                total: total
            )
            .progressViewStyle(GaugeProgressStyle(
                strokeColor: {
                    if progress > 1.0 {
                        return Color(uiColor: .systemRed)
                    } else if progress > 0.9 {
                        return Color(uiColor: .systemOrange)
                    } else {
                        return Color.accentColor
                    }
                }(),
                strokeWidth: 2
            ))
            .frame(width: 18, height: 18)
            .padding(.horizontal, 12)
            .animation(.easeInOut, value: progress)
            // overflow count label
            let isOverflowLabelDisplay = viewModel.maxTextInputLimit > 0 && textWeightedLength > viewModel.maxTextInputLimit
            if isOverflowLabelDisplay {
                Text("\(viewModel.maxTextInputLimit - textWeightedLength)")
                    .font(.system(size: 14, weight: .regular, design: .monospaced))
                    .foregroundColor(.red)
                    .padding(.trailing, 4)
            }
        }
    }
    
    var twitterReplySettingsMenuButton: some View {
        Menu {
            Picker(selection: $viewModel.twitterReplySettings) {
                ForEach(Twitter.Entity.V2.Tweet.ReplySettings.allCases, id: \.self) { replySetting in
                    Label {
                        Text(replySetting.title)
                    } icon: {
                        Image(uiImage: replySetting.image)
                    }
                }
            } label: {
                Text(viewModel.twitterReplySettings.title)
            }
        } label: {
            HStack {
                VectorImageView(
                    image: viewModel.twitterReplySettings.image.withRenderingMode(.alwaysTemplate),
                    tintColor: .tintColor
                )
                .frame(width: 24, height: 24)
                Text(viewModel.twitterReplySettings.title)
                    .font(.system(size: 12, weight: .regular))
                Spacer()
            }
            .padding(.horizontal, 12)
            .contentShape(Rectangle())
            .ignoresSafeArea(.all, edges: .all) // fix label position jumping issue
        }
    }
    
    var mastodonVisibilityMenuButton: some View {
        Menu {
            let visibilities: [Mastodon.Entity.Status.Visibility] = [
                .public,
                .unlisted,
                .private,
                .direct,
            ]
            Picker(selection: $viewModel.mastodonVisibility) {
                ForEach(visibilities, id: \.self) { visibility in
                    Label {
                        Text(visibility.title)
                    } icon: {
                        Image(uiImage: visibility.image)
                    }
                }
            } label: {
                Text(viewModel.mastodonVisibility.title)
            }
        } label: {
            HStack {
                VectorImageView(
                    image: viewModel.mastodonVisibility.image.withRenderingMode(.alwaysTemplate),
                    tintColor: .tintColor
                )
                .frame(width: 24, height: 24)
                Text(viewModel.mastodonVisibility.title)
                    .font(.system(size: 12, weight: .regular))
                Spacer()
            }
            .padding(.horizontal, 12)
            .contentShape(Rectangle())
            .ignoresSafeArea(.all, edges: .all) // fix label position jumping issue
        }
    }
    
}

extension ComposeContentToolbarView {
    
    public enum Action: Hashable, CaseIterable {
        case media
        case emoji
        case poll
        case mention
        case hashtag
        case location
        case contentWarning
        case mediaSensitive
    }
    
    func view(for action: Action) -> some View {
        Group {
            switch action {
            case .media:
                mediaMenuButton
            case .emoji:
                Button {
                    viewModel.isCustomEmojiComposing.toggle()
                } label: {
                    imageView(for: action, state: viewModel.isCustomEmojiComposing ? .selected : .normal)
                }
                .buttonStyle(HighlightDimmableButtonStyle())
            case .poll:
                Button {
                    viewModel.isPollComposing.toggle()
                } label: {
                    imageView(for: action)
                }
                .buttonStyle(HighlightDimmableButtonStyle())
                .disabled(!viewModel.isPollToolBarButtonEnabled)
                .opacity(viewModel.isPollToolBarButtonEnabled ? 1 : 0.5)
            case .mention:
                Button {
                    viewModel.insertContentText(text: "@")
                    viewModel.setContentTextViewFirstResponderIfNeeds()
                } label: {
                    imageView(for: action)
                }
                .buttonStyle(HighlightDimmableButtonStyle())
            case .hashtag:
                Button {
                    viewModel.insertContentText(text: "#")
                    viewModel.setContentTextViewFirstResponderIfNeeds()
                } label: {
                    imageView(for: action)
                }
                .buttonStyle(HighlightDimmableButtonStyle())
            case .location:
                locationButton
            default:
                EmptyView()
            }
        }   // end Group
    }
    
    func imageView(for action: Action, state: UIControl.State = .normal) -> some View {
        ComposeContentToolbarActionImage(
            image: action.image(of: state).withRenderingMode(.alwaysTemplate),
            tintColor: .secondaryLabel
        )
    }
    
    public enum MediaAction: String {
        case photoLibrary
        case camera
        case browse
    }
    
    var mediaMenuButton: some View {
        Menu {
            // photo library
            Button {
                viewModel.mediaActionPublisher.send(.photoLibrary)
            } label: {
                Label(L10n.Common.Controls.Ios.photoLibrary, systemImage: "rectangle.on.rectangle")
            }
            // camera
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button {
                    viewModel.mediaActionPublisher.send(.camera)
                } label: {
                    Label(L10n.Common.Controls.Actions.takePhoto, systemImage: "camera")
                }
            }
            // browse
            Button {
                viewModel.mediaActionPublisher.send(.browse)
            } label: {
                Label(L10n.Common.Controls.Actions.browse, systemImage: "ellipsis")
            }
        } label: {
            ComposeContentToolbarActionImage(
                image: ComposeContentToolbarView.Action.media.image(of: .normal).withRenderingMode(.alwaysTemplate),
                tintColor: .secondaryLabel
            )
            // Cannot set highlight button state for Menu's label
        }
        .disabled(!viewModel.isMediaToolBarButtonEnabled)
        .opacity(viewModel.isMediaToolBarButtonEnabled ? 1 : 0.5)
    }
    
    var locationButton: some View {
        HStack {
            Button {
                guard let presentingViewController = UIViewController.top,
                      viewModel.requestLocationAuthorizationIfNeeds(presentingViewController: presentingViewController)
                else { return }
                viewModel.isRequestLocation.toggle()
            } label: {
                ComposeContentToolbarActionImage(
                    image: ComposeContentToolbarView.Action.location.image(of: .normal).withRenderingMode(.alwaysTemplate),
                    tintColor: viewModel.isRequestLocation ? .tintColor : .secondaryLabel
                )
            }
            .buttonStyle(HighlightDimmableButtonStyle())
            if viewModel.isRequestLocation, let place = viewModel.currentPlace, let fullName = place.fullName {
                Text(fullName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }   // end HStack
    }
    
}

private struct ComposeContentToolbarActionImage: View {
    static var padding: CGFloat { 12 }
    static var dimension: CGFloat { 48 - 2 * padding }
    
    let image: UIImage
    let tintColor: UIColor
    
    var body: some View {
        VectorImageView(
            image: image,
            tintColor: tintColor
        )
        .frame(width: ComposeContentToolbarActionImage.dimension, height: ComposeContentToolbarActionImage.dimension)
        .padding(ComposeContentToolbarActionImage.padding)
        .contentShape(Rectangle())
        // size: 48 x 48
    }
    
}

extension ComposeContentToolbarView.Action {
    public func image(of state: UIControl.State) -> UIImage {
        switch self {
        case .media:
            return Asset.ObjectTools.photo.image.withRenderingMode(.alwaysTemplate)
        case .emoji:
            return state.contains(.selected) ? Asset.Keyboard.keyboard.image.withRenderingMode(.alwaysTemplate) : Asset.Human.faceSmiling.image.withRenderingMode(.alwaysTemplate)
        case .poll:
            return Asset.ObjectTools.poll.image.withRenderingMode(.alwaysTemplate)
        case .mention:
            return Asset.Symbol.at.image.withRenderingMode(.alwaysTemplate)
        case .hashtag:
            return Asset.Symbol.number.image.withRenderingMode(.alwaysTemplate)
        case .location:
            return Asset.ObjectTools.mappin.image.withRenderingMode(.alwaysTemplate)
        case .contentWarning:
            return Asset.Indices.exclamationmarkOctagon.image.withRenderingMode(.alwaysTemplate)
        case .mediaSensitive:
            return Asset.Human.eyeSlash.image.withRenderingMode(.alwaysTemplate)
        }
    }
}

extension Twitter.Entity.V2.Tweet.ReplySettings {
    
    var image: UIImage {
        switch self {
        case .everyone:         return Asset.ObjectTools.globe.image.withRenderingMode(.alwaysTemplate)
        case .following:        return Asset.Human.person2.image.withRenderingMode(.alwaysTemplate)
        case .mentionedUsers:   return Asset.Communication.at.image.withRenderingMode(.alwaysTemplate)
        }
    }
    
    var title: String {
        switch self {
        case .everyone:         return L10n.Scene.Compose.ReplySettings.everyoneCanReply
        case .following:        return L10n.Scene.Compose.ReplySettings.peopleYouFollowCanReply
        case .mentionedUsers:   return L10n.Scene.Compose.ReplySettings.onlyPeopleYouMentionCanReply
        }
    }
    
}

extension Mastodon.Entity.Status.Visibility {
    
    var image: UIImage {
        switch self {
        case .public:       return Asset.ObjectTools.globe.image.withRenderingMode(.alwaysTemplate)
        case .unlisted:     return Asset.ObjectTools.lockOpen.image.withRenderingMode(.alwaysTemplate)
        case .private:      return Asset.ObjectTools.lock.image.withRenderingMode(.alwaysTemplate)
        case .direct:       return Asset.Communication.mail.image.withRenderingMode(.alwaysTemplate)
        case ._other:       return UIImage(systemName: "square.dashed")!
        }
    }
    
    var title: String {
        switch self {
        case .public:       return L10n.Scene.Compose.Visibility.public
        case .unlisted:     return L10n.Scene.Compose.Visibility.unlisted
        case .private:      return L10n.Scene.Compose.Visibility.private
        case .direct:       return L10n.Scene.Compose.Visibility.direct
        case ._other:       return ""
        }
    }
    
    var subtitle: String {
        switch self {
        case .public:       return L10n.Scene.Compose.VisibilityDescription.public
        case .unlisted:     return L10n.Scene.Compose.VisibilityDescription.unlisted
        case .private:      return L10n.Scene.Compose.VisibilityDescription.private
        case .direct:       return L10n.Scene.Compose.VisibilityDescription.direct
        case ._other:       return ""
        }
    }
    
}
