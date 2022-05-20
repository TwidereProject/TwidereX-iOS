//
//  ComposeContentView.swift
//  
//
//  Created by MainasuK on 2022-5-18.
//

import os.log
import UIKit
import SwiftUI
import TwidereCore
import Introspect

public struct ComposeContentView: View {
    
    static let contentMargin: CGFloat = 16
    static let contentRowTopPadding: CGFloat = 8
    static let contentMetaTextViewHStackSpacing: CGFloat = 10
    static let avatarSize = CGSize(width: 44, height: 44)
    
    @ObservedObject var viewModel: ComposeContentViewModel
    
    @State var toolbarHeight: CGFloat = 0
            
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
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
                                metaText.textView.tag = ComposeContentViewModel.MetaTextViewKind.content.rawValue
                                metaText.delegate = viewModel
                            }
                        )
                        .frame(minHeight: ComposeContentView.avatarSize.height)
                        .border(.red, width: 1)
                    }
                }
                .padding(.top, ComposeContentView.contentRowTopPadding)
                .padding(.horizontal, ComposeContentView.contentMargin)
                // attachments
                if !viewModel.attachmentViewModels.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(viewModel.attachmentViewModels, id: \.self) { attachmentViewModel in
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
                        }
                        Spacer()
                    }
                    .padding(ComposeContentView.contentMargin)
                    .border(.blue, width: 1)
                    .introspectScrollView { scrollView in
                        scrollView.alwaysBounceHorizontal = false
                    }
                }

                Spacer()
            }
        }
        .frame(width: viewModel.viewSize.width)
        .frame(maxHeight: .infinity)
        .padding(.bottom, toolbarHeight)
        .overlay(alignment: .bottom, content: {
            ComposeContentToolbarView(viewModel: viewModel)
                .background(GeometryReader { geometry in
                    Color.clear.preference(
                        key: ToolbarHeightPreferenceKey.self,
                        value: geometry.size.height
                    )
                })
                .onPreferenceChange(ToolbarHeightPreferenceKey.self) {
                    toolbarHeight = $0
                    print(toolbarHeight)
                }
        })
    }
    
}

private extension ComposeContentView {
    struct ToolbarHeightPreferenceKey: PreferenceKey {
        static let defaultValue: CGFloat = 0

        static func reduce(value: inout CGFloat,
                           nextValue: () -> CGFloat) {
            value = max(value, nextValue())
        }
    }
}
