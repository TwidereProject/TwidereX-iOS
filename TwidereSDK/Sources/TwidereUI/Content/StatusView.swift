//
//  StatusView.swift
//  StatusView
//
//  Created by Cirno MainasuK on 2021-8-19.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import Combine
import UIKit
import SwiftUI
import Kingfisher
import MetaTextKit
import MetaTextArea
import MetaLabel
import TwidereCore

public protocol StatusViewDelegate: AnyObject {
//    func statusView(_ statusView: StatusView, headerDidPressed header: UIView)

    // avatar
    func statusView(_ viewModel: StatusView.ViewModel, userAvatarButtonDidPressed user: UserRecord)

    // spoiler
    func statusView(_ viewModel: StatusView.ViewModel, toggleContentDisplay isReveal: Bool)

    // meta
    func statusView(_ viewModel: StatusView.ViewModel, textViewDidSelectMeta meta: Meta?)

    // media
    func statusView(_ viewModel: StatusView.ViewModel, mediaViewModel: MediaView.ViewModel, action: MediaView.ViewModel.Action)
    func statusView(_ viewModel: StatusView.ViewModel, toggleContentWarningOverlayDisplay isReveal: Bool)

    // poll
    func statusView(_ viewModel: StatusView.ViewModel, pollVoteActionForViewModel pollViewModel: PollView.ViewModel)
    func statusView(_ viewModel: StatusView.ViewModel, pollUpdateIfNeedsForViewModel pollViewModel: PollView.ViewModel)
    func statusView(_ viewModel: StatusView.ViewModel, pollViewModel: PollView.ViewModel, pollOptionDidSelectForViewModel optionViewModel: PollOptionView.ViewModel)
    
    // repost
    func statusView(_ viewModel: StatusView.ViewModel, quoteStatusViewDidPressed quoteViewModel: StatusView.ViewModel)
    
    // metric
    func statusView(_ viewModel: StatusView.ViewModel, statusMetricViewModel: StatusMetricView.ViewModel, statusMetricButtonDidPressed action: StatusMetricView.Action)

    // toolbar
    func statusView(_ viewModel: StatusView.ViewModel, statusToolbarViewModel: StatusToolbarView.ViewModel, statusToolbarButtonDidPressed action: StatusToolbarView.Action)

//    func statusView(_ statusView: StatusView, translateButtonDidPressed button: UIButton)

    func statusView(_ viewModel: StatusView.ViewModel, viewHeightDidChange: Void)

//    // a11y
//    func statusView(_ statusView: StatusView, accessibilityActivate: Void)
}

public struct StatusView: View {
    
    static let logger = Logger(subsystem: "StatusView", category: "View")
    var logger: Logger { StatusView.logger }
    
    static var statusHeaderBottomSpacing: CGFloat { 6.0 }
    static var hangingAvatarButtonDimension: CGFloat { 44.0 }
    static var hangingAvatarButtonTrailingSpacing: CGFloat { 10.0 }
    
    @ObservedObject public private(set) var viewModel: ViewModel
    
    @Environment(\.displayScale) var displayScale
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @ScaledMetric(relativeTo: .subheadline) private var visibilityIconImageDimension: CGFloat = 16
    @ScaledMetric(relativeTo: .headline) private var inlineAvatarButtonDimension: CGFloat = 20
    @ScaledMetric(relativeTo: .headline) private var lockImageDimension: CGFloat = 16

    public init(viewModel: StatusView.ViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(spacing: .zero) {
            if let repostViewModel = viewModel.repostViewModel {
                // cell top margin
                Color.clear.frame(height: viewModel.cellTopMargin)
                // header
                if let statusHeaderViewModel = repostViewModel.statusHeaderViewModel {
                    StatusHeaderView(viewModel: statusHeaderViewModel)
                    Color.clear.frame(height: StatusView.statusHeaderBottomSpacing)
                }
                // post
                StatusView(viewModel: repostViewModel)
            } else {
                // cell top margin
                Color.clear.frame(height: viewModel.cellTopMargin)
                    .overlay {
                        Group {
                            // top conversation link
                            switch viewModel.kind {
                            case .conversationThread, .conversationRoot:
                                HStack(spacing: .zero) {
                                    VStack(alignment: .center, spacing: .zero) {
                                        Rectangle()
                                            .foregroundColor(Color(uiColor: .separator))
                                            .background(.clear)
                                            .frame(width: 1)
                                            .frame(maxHeight: .infinity)
                                            .opacity(viewModel.isTopConversationLinkLineViewDisplay ? 1 : 0)
                                    }
                                    .frame(width: Self.hangingAvatarButtonDimension) // avatar button width
                                    .frame(maxHeight: .infinity)
                                    Spacer()
                                }
                            default:
                                EmptyView()
                            }
                        }
                    }
                HStack(alignment: .top, spacing: .zero) {
                    if viewModel.hasHangingAvatar {
                        avatarButton
                            .padding(.trailing, Self.hangingAvatarButtonTrailingSpacing)
                    }
                    let contentSpacing: CGFloat = 4
                    VStack(spacing: contentSpacing) {
                        // authorView
                        authorView
                        // spoiler content (Mastodon)
                        if viewModel.spoilerContent != nil {
                            spoilerContentView
                            if !viewModel.isContentEmpty {
                                Button {
                                    // force to trigger view update without animation
                                    withAnimation(.none) {
                                        viewModel.isContentSensitiveToggled.toggle()
                                    }
                                    viewModel.delegate?.statusView(viewModel, toggleContentDisplay: !viewModel.isContentReveal)
                                } label: {
                                    HStack {
                                        Image(uiImage: Asset.Editing.ellipsisLarge.image.withRenderingMode(.alwaysTemplate))
                                            .background(Color(uiColor: .tertiarySystemFill))
                                            .clipShape(Capsule())
                                        Spacer()
                                    }
                                }
                                .buttonStyle(.borderless)
                                .id(UUID())     // fix animation issue
                            }
                        }
                        // content
                        if viewModel.isContentReveal {
                            contentView
                            
                            if viewModel.isTranslateButtonDisplay {
                                translateButton
                            }
                        }
                        // media
                        if !viewModel.mediaViewModels.isEmpty {
                            MediaGridContainerView(
                                viewModels: viewModel.mediaViewModels,
                                idealWidth: viewModel.contentWidth,
                                idealHeight: 280,
                                handler: { mediaViewModel, action in
                                    viewModel.delegate?.statusView(viewModel, mediaViewModel: mediaViewModel, action: action)
                                }
                            )
                            .id(viewModel.identifier)
                            .overlay {
                                if viewModel.isMediaContentWarningOverlayToggleButtonDisplay {
                                    ContentWarningOverlayView(isReveal: viewModel.isMediaContentWarningOverlayReveal) {
                                        viewModel.delegate?.statusView(viewModel, toggleContentWarningOverlayDisplay: !viewModel.isMediaContentWarningOverlayReveal)
                                    }
                                    .cornerRadius(MediaGridContainerView.cornerRadius)
                                }
                            }
                        }
                        // poll
                        if let pollViewModel = viewModel.pollViewModel {
                            PollView(
                                viewModel: pollViewModel,
                                selectAction: { optionViewModel in
                                    viewModel.delegate?.statusView(viewModel, pollViewModel: pollViewModel, pollOptionDidSelectForViewModel: optionViewModel)
                                }, voteAction: { pollViewModel in
                                    viewModel.delegate?.statusView(viewModel, pollVoteActionForViewModel: pollViewModel)
                                }
                            )
                            .onAppear {
                                viewModel.delegate?.statusView(viewModel, pollUpdateIfNeedsForViewModel: pollViewModel)
                            }
                        }
                        // quote
                        if let quoteViewModel = viewModel.quoteViewModel {
                            StatusView(viewModel: quoteViewModel)
                                .background {
                                    Color(uiColor: .label.withAlphaComponent(0.04))
                                }
                                .cornerRadius(12)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    viewModel.delegate?.statusView(viewModel, quoteStatusViewDidPressed: quoteViewModel)
                                }
                        }
                        // location (inline)
                        if let location = viewModel.location {
                            HStack {
                                Image(uiImage: Asset.ObjectTools.mappinMini.image.withRenderingMode(.alwaysTemplate))
                                Text(location)
                                Spacer()
                            }
                            .foregroundColor(.secondary)
                            .font(Font(TextStyle.statusLocation.font))
                            .frame(alignment: .leading)
                        }
                        // metric
                        if let metricViewModel = viewModel.metricViewModel {
                            StatusMetricView(viewModel: metricViewModel) { action in
                                // TODO:
                            }
                            .padding(.vertical, 8)
                        }
                        // toolbar
                        if viewModel.hasToolbar {
                            VStack(spacing: .zero) {
                                toolbarView
                                    .overlay(alignment: .top) {
                                        switch viewModel.kind {
                                        case .conversationRoot:
                                            // toolbar top divider
                                            VStack(spacing: .zero) {
                                                Color.clear
                                                    .frame(height: 1)
                                                Divider()
                                                    .frame(width: viewModel.viewLayoutFrame.safeAreaLayoutFrame.width)
                                                    .fixedSize()
                                                Spacer()
                                            }
                                        default:
                                            EmptyView()
                                        }
                                    }
                                if viewModel.kind == .conversationRoot,
                                   let replySettingBannerViewModel = viewModel.replySettingBannerViewModel,
                                   !replySettingBannerViewModel.shouldHidden
                                {
                                    HStack {
                                        ReplySettingBannerView(viewModel: replySettingBannerViewModel)
                                        Spacer()
                                    }
                                    .background {
                                        Color(uiColor: Asset.Colors.hightLight.color.withAlphaComponent(0.6))
                                            .frame(width: viewModel.viewLayoutFrame.safeAreaLayoutFrame.width)
                                            .overlay(alignment: .top) {
                                                // reply settings banner top divider
                                                VStack(spacing: .zero) {
                                                    Divider()
                                                }
                                            }
                                    }
                                }
                            }   // end VStack
                        }
                    }   // end VStack
                    .padding(.top, viewModel.margin)                                    // container margin
                    .padding(.horizontal, viewModel.margin)                             // container margin
                    .padding(.bottom, viewModel.hasToolbar ? .zero : viewModel.margin)  // container margin
                    .frame(width: viewModel.containerWidth)
                    .overlay(alignment: .bottom) {
                        switch viewModel.kind {
                        case .timeline, .repost, .conversationThread:
                            VStack(spacing: .zero) {
                                Spacer()
                                Divider()
                                Color.clear
                                    .frame(height: 1)
                            }
                        case .conversationRoot:
                            // cell bottom divider
                            VStack(spacing: .zero) {
                                Spacer()
                                Divider()
                                    .frame(width: viewModel.viewLayoutFrame.safeAreaLayoutFrame.width)
                                    .fixedSize()
                            }
                        default:
                            EmptyView()
                        }
                    }
                }   // end HStack
                .overlay {
                    // bottom conversation link
                    HStack(alignment: .top, spacing: .zero) {
                        VStack(alignment: .center, spacing: 0) {
                            Color.clear
                                .frame(width: StatusView.hangingAvatarButtonDimension, height: StatusView.hangingAvatarButtonDimension)
                            Rectangle()
                                .foregroundColor(Color(uiColor: .separator))
                                .background(.clear)
                                .frame(width: 1)
                                .opacity(viewModel.isBottomConversationLinkLineViewDisplay ? 1 : 0)
                        }
                        Spacer()
                    }   // end HStack
                }   // end overlay
            }   // end if … else …
        }   // end VStack
        .onReceive(viewModel.$isContentSensitiveToggled) { _ in
            // trigger tableView reload to update the cell height
            viewModel.delegate?.statusView(viewModel, viewHeightDidChange: Void())
        }
    }

}

extension StatusView {
    @ViewBuilder
    var authorView: some View {
        HStack(alignment: .center) {
            if !viewModel.hasHangingAvatar {
                // avatar
                avatarButton
            }
            VStack(alignment: .leading, spacing: .zero) {
                let isAdaptiveLayout: Bool = dynamicTypeSize >= .accessibility1
                HStack(spacing: .zero) {
                    // name
                    nameView
                    // lock
                    if viewModel.protected {
                        VectorImageView(
                            image: Asset.ObjectTools.lockMini.image.withRenderingMode(.alwaysTemplate),
                            tintColor: .secondaryLabel
                        )
                        .frame(width: lockImageDimension, height: lockImageDimension)
                    }
                    Spacer()
                    if !isAdaptiveLayout {
                        timestampLabelView
                    }
                }   // end HStack
                HStack(spacing: .zero) {
                    // username
                    Text(verbatim: "@\(viewModel.authorUsernme)")
                        .font(Font(TextStyle.statusAuthorUsername.font))
                        .foregroundColor(Color(uiColor: TextStyle.statusAuthorUsername.textColor))
                        .lineLimit(1)
                    Spacer()
                    if !isAdaptiveLayout {
                        mastodonVisibilityIconView
                    }
                }
                if isAdaptiveLayout {
                    HStack {
                        timestampLabelView
                        mastodonVisibilityIconView
                    }
                }
            }   // end VStack
        }   // end HStack
    }
    
    @ViewBuilder
    var nameView: some View {
        if viewModel.isAuthorNameContainsMeta {
            LabelRepresentable(
                metaContent: viewModel.authorName,
                textStyle: .statusAuthorName,
                setupLabel: { label in
                    label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
                    label.setContentHuggingPriority(.defaultHigh, for: .vertical)
                    label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
                    label.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
                }
            )
        } else {
            Text(verbatim: viewModel.authorName.string)
                .font(Font(TextStyle.statusAuthorName.font))
                .foregroundColor(Color(uiColor: TextStyle.statusAuthorName.textColor))
                .lineLimit(1)
        }
    }
    
    @ViewBuilder
    var timestampLabelView: some View {
        if let timestampLabelViewModel = viewModel.timestampLabelViewModel {
            TimestampLabelView(viewModel: timestampLabelViewModel)
        }
    }
    
    @ViewBuilder
    var mastodonVisibilityIconView: some View {
        if let visibilityIconImage = viewModel.visibilityIconImage {
            let dimension = visibilityIconImageDimension
            VectorImageView(image: visibilityIconImage, tintColor: TextStyle.statusTimestamp.textColor)
                .frame(width: dimension, height: dimension)
        }
    }
    
    var avatarButtonClipShape: any Shape {
        switch viewModel.avatarStyle {
        case .circle:
            return Circle()
        case .roundedSquare:
            return RoundedRectangle(cornerRadius: avatarButtonDimension / 4)
        }
    }
    
    var avatarButtonDimension: CGFloat {
        switch viewModel.kind {
        case .quote:
            return inlineAvatarButtonDimension
        default:
            return StatusView.hangingAvatarButtonDimension
        }
    }
    
    @ViewBuilder
    var avatarButton: some View {
        Button {
            guard let author = viewModel.author?.asRecord else { return }
            viewModel.delegate?.statusView(viewModel, userAvatarButtonDidPressed: author)
        } label: {
            KFImage(viewModel.avatarURL)
                .resizable()
                .downsampling(size: CGSize(width: avatarButtonDimension * displayScale, height: avatarButtonDimension * displayScale))
                .backgroundDecode()
                .cancelOnDisappear(true)
                .placeholder { _ in
                    Color(uiColor: .placeholderText)
                }
                .aspectRatio(contentMode: .fill)
                .frame(width: avatarButtonDimension, height: avatarButtonDimension)
        }
        .buttonStyle(.borderless)
        .clipShape(AvatarClipShape(avatarStyle: viewModel.avatarStyle))
        .animation(.easeInOut, value: viewModel.avatarStyle)
    }
    
    @ViewBuilder
    var spoilerContentView: some View {
        if viewModel.isSpoilerContentContainsMeta {
            TextViewRepresentable(
                metaContent: viewModel.spoilerContent ?? PlaintextMetaContent(string: ""),
                textStyle: .statusContent,
                isSelectable: viewModel.kind == .conversationRoot,
                handler: { meta in
                    viewModel.delegate?.statusView(viewModel, textViewDidSelectMeta: meta)
                }
            )
            .frame(width: viewModel.contentWidth)
            .onTapGesture {
                // ignore tap
            }
        } else {
            let metaContent = viewModel.spoilerContentAttributedString ?? AttributedString("")
            Text(metaContent)
                .multilineTextAlignment(.leading)
                .font(Font(TextStyle.statusContent.font))
                .foregroundColor(Color(uiColor: TextStyle.statusContent.textColor))
                .frame(width: viewModel.contentWidth, alignment: .leading)
        }
    }
    
    @ViewBuilder
    var contentView: some View {
        if viewModel.isContentContainsMeta {
            TextViewRepresentable(
                metaContent: viewModel.content,
                textStyle: .statusContent,
                isSelectable: viewModel.kind == .conversationRoot,
                handler: { meta in
                    viewModel.delegate?.statusView(viewModel, textViewDidSelectMeta: meta)
                }
            )
            .frame(width: viewModel.contentWidth)
            .onTapGesture {
                // ignore tap
            }
        } else {
            Text(viewModel.contentAttributedString)
                .multilineTextAlignment(.leading)
                .font(Font(TextStyle.statusContent.font))
                .foregroundColor(Color(uiColor: TextStyle.statusContent.textColor))
                .frame(width: viewModel.contentWidth, alignment: .leading)
        }
    }
    
    var translateButton: some View {
        Button {
            viewModel.delegate?.statusView(viewModel, statusToolbarViewModel: viewModel.toolbarViewModel, statusToolbarButtonDidPressed: .translate)
        } label: {
            HStack {
                Text(L10n.Common.Controls.Status.Actions.translate)
                    .font(Font(TextStyle.statusTranslateButton.font))
                    .foregroundColor(Color(uiColor: TextStyle.statusTranslateButton.textColor))
                Spacer()
            }
            .padding(.vertical)
        }
    }
    
    var toolbarView: some View {
        StatusToolbarView(
            viewModel: viewModel.toolbarViewModel,
            menuActions: {
                var actions: [StatusToolbarView.Action] = []
                // copyText
                actions.append(.copyText)
                // copyLink
                actions.append(.copyLink)
                // shareLink
                actions.append(.shareLink)
                // save media
                if !viewModel.mediaViewModels.isEmpty {
                    actions.append(.saveMedia)
                }
                // translate
                actions.append(.translate)
                if viewModel.canDelete {
                    actions.append(.delete)
                }
                return actions
            }(),
            handler: { action in
                viewModel.delegate?.statusView(
                    viewModel,
                    statusToolbarViewModel: viewModel.toolbarViewModel,
                    statusToolbarButtonDidPressed: action
                )
            }
        )
        .frame(height: 48)
    }
}
