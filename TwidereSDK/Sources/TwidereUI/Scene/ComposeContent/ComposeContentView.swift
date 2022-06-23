//
//  ComposeContentView.swift
//  
//
//  Created by MainasuK on 2022-5-18.
//

import os.log
import UIKit
import SwiftUI
import Popovers
import Introspect
import TwidereCore

public struct ComposeContentView: View {
    
    static let contentMargin: CGFloat = 16
    static let contentRowTopPadding: CGFloat = 8
    static let contentMetaTextViewHStackSpacing: CGFloat = 10
    static let avatarSize = CGSize(width: 44, height: 44)
    
    @ObservedObject var viewModel: ComposeContentViewModel
    
    @State var mentionTextHeight: CGFloat = 0
    @State var toolbarHeight: CGFloat = 0
    @State var isPollExpireConfigurationPopoverPresent = false
    
    struct PollField: Hashable {
        let index: Int
    }
    @FocusState var pollField: PollField?
            
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: .zero) {
                // reply
                switch viewModel.kind {
                case .reply(let status):
                    ReplyStatusViewRepresentable(
                        statusObject: status,
                        configurationContext: viewModel.configurationContext.statusViewConfigureContext,
                        width: viewModel.viewSize.width - 2 * ComposeContentView.contentMargin
                    )
                    .padding(.top, 8)
                    .padding(.horizontal, ComposeContentView.contentMargin)
                    .frame(width: viewModel.viewSize.width)
                default:
                    EmptyView()
                }
                // content
                HStack(alignment: .top, spacing: ComposeContentView.contentMetaTextViewHStackSpacing) {
                    // avatar
                    AvatarButtonRepresentable(configuration: .init(url: viewModel.author?.avatarURL))
                        .frame(width: ComposeContentView.avatarSize.width, height: ComposeContentView.avatarSize.height)
                        .overlay(alignment: .top) {
                            // draw conversation link line
                            switch viewModel.kind {
                            case .reply:
                                Rectangle()
                                    .foregroundColor(Color(uiColor: .separator))
                                    .background(.clear)
                                    .frame(width: 1, height: ComposeContentView.contentRowTopPadding)
                                    .offset(x: 0, y: -ComposeContentView.contentRowTopPadding)
                            default:
                                EmptyView()
                            }
                        }
                    VStack {
                        // mention
                        if viewModel.isMentionPickDisplay {
                            Button {
                                viewModel.mentionPickPublisher.send()
                            } label: {
                                HStack(spacing: .zero) {
                                    VectorImageView(
                                        image: Asset.Communication.textBubbleSmall.image.withRenderingMode(.alwaysTemplate),
                                        tintColor: .tintColor
                                    )
                                    .frame(width: mentionTextHeight, height: mentionTextHeight, alignment: .center)
                                    Text(viewModel.mentionPickButtonTitle)
                                        .font(.footnote)
                                        .background(GeometryReader { geometry in
                                            Color.clear.preference(
                                                key: SizeDimensionPreferenceKey.self,
                                                value: geometry.size.height
                                            )
                                        })
                                        .onPreferenceChange(SizeDimensionPreferenceKey.self) {
                                            mentionTextHeight = $0
                                        }
                                    Spacer()
                                }
                            }
                        }   // end if
                        // content warning
                        if viewModel.isContentWarningComposing {
                            let contentWarningIconSize = CGSize(width: 24, height: 24)
                            let contentWarningStackSpacing: CGFloat = 8
                            VStack {
                                HStack(spacing: contentWarningStackSpacing) {
                                    VectorImageView(
                                        image: Asset.Indices.exclamationmarkOctagon.image.withRenderingMode(.alwaysTemplate),
                                        tintColor: viewModel.isContentWarningEditing ? .tintColor : .secondaryLabel
                                    )
                                    .frame(width: contentWarningIconSize.width, height: contentWarningIconSize.height)
                                    MetaTextViewRepresentable(
                                        string: $viewModel.contentWarning,
                                        width: {
                                            var textViewWidth = viewModel.viewSize.width
                                            textViewWidth -= ComposeContentView.contentMargin * 2
                                            textViewWidth -= ComposeContentView.contentMetaTextViewHStackSpacing
                                            textViewWidth -= ComposeContentView.avatarSize.width
                                            textViewWidth -= contentWarningIconSize.width
                                            textViewWidth -= contentWarningStackSpacing
                                            return textViewWidth
                                        }(),
                                        configurationHandler: { metaText in
                                            viewModel.contentWarningMetaText = metaText
                                            metaText.textView.attributedPlaceholder = {
                                                var attributes = metaText.textAttributes
                                                attributes[.foregroundColor] = UIColor.secondaryLabel
                                                return NSAttributedString(
                                                    string: L10n.Scene.Compose.cwPlaceholder,
                                                    attributes: attributes
                                                )
                                            }()
                                            metaText.textView.tag = ComposeContentViewModel.MetaTextViewKind.contentWarning.rawValue
                                            metaText.textView.returnKeyType = .next
                                            metaText.textView.delegate = viewModel
                                            metaText.textView.setContentHuggingPriority(.required - 1, for: .vertical)
                                            metaText.delegate = viewModel
                                        }
                                    )
                                }
                                Divider()
                                    .background(viewModel.isContentWarningEditing ? .accentColor : Color(uiColor: .separator))
                            }   // end VStack
                        } // end if viewModel.isContentWarningComposing
                        // contentTextEditor
                        MetaTextViewRepresentable(
                            string: $viewModel.content,
                            width: {
                                var textViewWidth = viewModel.viewSize.width
                                textViewWidth -= ComposeContentView.contentMargin * 2
                                textViewWidth -= ComposeContentView.contentMetaTextViewHStackSpacing
                                textViewWidth -= ComposeContentView.avatarSize.width
                                return textViewWidth
                            }(),
                            configurationHandler: { metaText in
                                viewModel.contentMetaText = metaText
                                metaText.textView.attributedPlaceholder = {
                                    var attributes = metaText.textAttributes
                                    attributes[.foregroundColor] = UIColor.secondaryLabel
                                    return NSAttributedString(
                                        string: L10n.Scene.Compose.placeholder,
                                        attributes: attributes
                                    )
                                }()
                                metaText.textView.tag = ComposeContentViewModel.MetaTextViewKind.content.rawValue
                                metaText.textView.keyboardType = .twitter
                                metaText.textView.delegate = viewModel
                                metaText.delegate = viewModel
                                metaText.textView.becomeFirstResponder()
                            }
                        )
                        .frame(minHeight: ComposeContentView.avatarSize.height)
                        // poll
                        pollView
                    }
                }   // end content
                .padding(.top, ComposeContentView.contentRowTopPadding)
                .padding(.horizontal, ComposeContentView.contentMargin)
                
                // mediaAttachment
                mediaAttachmentView
                    .padding(ComposeContentView.contentMargin)

                Spacer()
            }   // end VStack
        }   // end ScrollView
        .frame(width: viewModel.viewSize.width)
        .frame(maxHeight: .infinity)
        .padding(.bottom, toolbarHeight)
        .contentShape(Rectangle())
        .onDrop(
            of: AttachmentViewModel.writableTypeIdentifiersForItemProvider,
            delegate: AttachmentDropDelegate(
                isAttachmentViewModelAppendable: {
                    viewModel.attachmentViewModels.count < viewModel.maxMediaAttachmentLimit
                }(),
                addAttachmentViewModel: { attachmentViewModel in
                    viewModel.attachmentViewModels.append(attachmentViewModel)
                }
            )
        )
        .overlay(alignment: .bottom, content: {
            ComposeContentToolbarView(
                viewModel: viewModel
            )
            .background(GeometryReader { geometry in
                Color.clear.preference(
                    key: SizeDimensionPreferenceKey.self,
                    value: geometry.size.height
                )
            })
            .onPreferenceChange(SizeDimensionPreferenceKey.self) {
                toolbarHeight = $0
            }
        })
    }
    
}

extension ComposeContentView {
    // MARK: - attachment
    var mediaAttachmentView: some View {
        Group {
            if !viewModel.attachmentViewModels.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ReorderableForEach(items: $viewModel.attachmentViewModels) { $attachmentViewModel in
                            AttachmentView(
                                viewModel: attachmentViewModel,
                                action: { action in
                                    switch action {
                                    case .preview:
                                        viewModel.mediaPreviewPublisher.send(attachmentViewModel)
                                    case .caption:
                                        break
                                    case .remove:
                                        viewModel.attachmentViewModels.removeAll(where: { $0 === attachmentViewModel })
                                    }
                                }
                            )
                        }
                        Spacer()
                    }   // end HStack
                }
                .introspectScrollView { scrollView in
                    scrollView.alwaysBounceHorizontal = false
                }
            }   // end if
        }   // end Group
    }
    
    // MARK: - poll
    var pollView: some View {
        VStack {
            if viewModel.isPollComposing {
                // poll option TextField
                ReorderableForEach(
                    items: $viewModel.pollOptions
                ) { $pollOption in
                    let _index = viewModel.pollOptions.firstIndex(of: pollOption)
                    PollOptionRow(
                        viewModel: pollOption,
                        index: _index,
                        deleteBackwardResponseTextFieldRelayDelegate: viewModel
                    ) { textField in
                        viewModel.customEmojiPickerInputViewModel.configure(textInput: textField)
                    }
                }
            }
            switch viewModel.author {
            case .twitter where viewModel.isPollComposing:
                // expire configuration
                Button {
                    isPollExpireConfigurationPopoverPresent.toggle()
                    if isPollExpireConfigurationPopoverPresent {
                        UIApplication.shared.keyWindowScene?.keyWindow?.endEditing(true)
                    }
                } label: {
                    HStack {
                        VectorImageView(
                            image: Asset.ObjectTools.clock.image.withRenderingMode(.alwaysTemplate),
                            tintColor: .secondaryLabel
                        )
                        .frame(width: 24, height: 24)
                        .padding(.vertical, 12)
                        let text = viewModel.pollExpireConfigurationFormatter.string(from: viewModel.pollExpireConfiguration.countdown) ?? "-"
                        Text(text)
                            .font(.callout)
                            .foregroundColor(.primary)
                        Spacer()
                        VectorImageView(
                            image: Asset.Arrows.tablerChevronDown.image.withRenderingMode(.alwaysTemplate),
                            tintColor: .secondaryLabel
                        )
                        .frame(width: 24, height: 24)
                        .padding(.vertical, 12)
                    }
                }
                .popover(
                    present: $isPollExpireConfigurationPopoverPresent,
                    attributes: {
                        // disable rubber to allow Picker interaction
                        $0.rubberBandingMode = .none
                        // layout popover center to button center
                        $0.position = .absolute(originAnchor: .bottomLeft, popoverAnchor: .topLeft)
                        $0.dismissal.mode = [.tapOutside]
                    }
                ) {
                    TimeIntervalPicker(dateComponents: $viewModel.pollExpireConfiguration.countdown)
                        .background(.regularMaterial)
                        .cornerRadius(16)
                        .popoverShadow(shadow: {
                            var shadow = Templates.Shadow.system
                            shadow.color = Color(.black.withAlphaComponent(0.3))
                            return shadow
                        }())
                }
                .clipped()
            case .mastodon where viewModel.isPollComposing:
                VStack(spacing: .zero) {
                    // expire configuration
                    Menu {
                        ForEach(PollComposeItem.ExpireConfiguration.Option.allCases, id: \.self) { option in
                            Button {
                                viewModel.pollExpireConfiguration.option = option
                                viewModel.pollExpireConfiguration = viewModel.pollExpireConfiguration
                            } label: {
                                Text(option.title)
                            }
                        }
                    } label: {
                        HStack {
                            VectorImageView(
                                image: Asset.ObjectTools.clock.image.withRenderingMode(.alwaysTemplate),
                                tintColor: .secondaryLabel
                            )
                            .frame(width: 24, height: 24)
                            .padding(.vertical, 12)
                            let text = viewModel.pollExpireConfigurationFormatter.string(from: TimeInterval(viewModel.pollExpireConfiguration.option.seconds)) ?? "-"
                            Text(text)
                                .font(.callout)
                                .foregroundColor(.primary)
                            Spacer()
                            VectorImageView(
                                image: Asset.Arrows.tablerChevronDown.image.withRenderingMode(.alwaysTemplate),
                                tintColor: .secondaryLabel
                            )
                            .frame(width: 24, height: 24)
                            .padding(.vertical, 12)
                        }
                    }
                    // multi-selection configuration
                    Button {
                        viewModel.pollMultipleConfiguration.isMultiple.toggle()
                        viewModel.pollMultipleConfiguration = viewModel.pollMultipleConfiguration
                    } label: {
                        HStack {
                            let selectionImage = viewModel.pollMultipleConfiguration.isMultiple ? Asset.Indices.checkmarkSquare.image.withRenderingMode(.alwaysTemplate) : Asset.Indices.square.image.withRenderingMode(.alwaysTemplate)
                            VectorImageView(
                                image: selectionImage,
                                tintColor: .secondaryLabel
                            )
                            .frame(width: 24, height: 24)
                            .padding(.vertical, 12)
                            Text(L10n.Scene.Compose.Vote.multiple)
                                .font(.callout)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                    }
                }

            default:
                EmptyView()
            }   // end switch viewModel.author
        }   // end VStack
    }
    
}

private extension ComposeContentView {
    struct SizeDimensionPreferenceKey: PreferenceKey {
        static let defaultValue: CGFloat = 0

        static func reduce(
            value: inout CGFloat,
            nextValue: () -> CGFloat
        ) {
            value = max(value, nextValue())
        }
    }
}

// MARK: - TypeIdentifiedItemProvider
extension PollComposeItem.Option: TypeIdentifiedItemProvider {
    public static var typeIdentifier: String {
        return Bundle(for: PollComposeItem.Option.self).bundleIdentifier! + String(describing: type(of: PollComposeItem.Option.self))
    }
}

// MARK: - NSItemProviderWriting
extension PollComposeItem.Option: NSItemProviderWriting {
    public func loadData(
        withTypeIdentifier typeIdentifier: String,
        forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void
    ) -> Progress? {
        completionHandler(nil, nil)
        return nil
    }
    
    public static var writableTypeIdentifiersForItemProvider: [String] {
        return [Self.typeIdentifier]
    }
}
