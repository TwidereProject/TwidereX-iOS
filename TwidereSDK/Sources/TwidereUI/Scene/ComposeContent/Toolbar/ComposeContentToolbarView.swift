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

public struct ComposeContentToolbarView: View {
    
    static let toolbarMargin: CGFloat = 4
    
    @ObservedObject var viewModel: ComposeContentViewModel
            
    public var body: some View {
        VStack(spacing: .zero) {
            HStack(spacing: .zero) {
                // iput limit indicator
                let value = Double(viewModel.currentTextInputWeightedLength)
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
                .padding(.leading, 3)
                .padding(.horizontal, 12)
                .animation(.easeInOut, value: progress)
                    // overflow count label
                let isOverflowLabelDisplay = viewModel.maxTextInputLimit > 0 && viewModel.currentTextInputWeightedLength > viewModel.maxTextInputLimit
                if isOverflowLabelDisplay {
                    Text("\(viewModel.maxTextInputLimit - viewModel.currentTextInputWeightedLength)")
                        .font(.system(size: 14, weight: .regular, design: .monospaced))
                        .foregroundColor(.red)
                        .padding(.trailing, 4)
                }
                Divider()
                    .frame(width: 1, height: 24)
                // visibility button
                Button {
                    
                } label: {
                    HStack {
                        VectorImageView(
                            image: Asset.ObjectTools.globeMini.image.withRenderingMode(.alwaysTemplate),
                            tintColor: .tintColor
                        )
                        .frame(width: 24, height: 24)
                        Text("Public")
                            .font(.system(size: 12, weight: .regular))
                    }
                    .padding(12)
                }
                Spacer()
                // content warning
                Button {
                    viewModel.isContentWarningComposing.toggle()
                } label: {
                    VectorImageView(
                        image: ComposeContentToolbarView.Action.contentWarning.image(of: .normal).withRenderingMode(.alwaysTemplate),
                        tintColor: viewModel.isContentWarningComposing ? .tintColor : .secondaryLabel
                    )
                    .frame(width: 24, height: 24)
                    .padding(12)
                }
            }
            .padding(.horizontal, ComposeContentToolbarView.toolbarMargin)
            Divider()
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: .zero) {
                    ForEach(ComposeContentToolbarView.Action.allCases, id: \.self) { action in
                        if viewModel.availableActions.contains(action) {
                            switch action {
                            case .media:
                                mediaMenuButton
                            default:
                                Button {
                                    
                                } label: {
                                    let image = action.image(of: .normal).withRenderingMode(.alwaysTemplate)
                                    ComposeContentToolbarActionImage(
                                        image: image,
                                        tintColor: .secondaryLabel
                                    )
                                }
                            }   // end switch
                            
                            if case .location = action {
                                Text("Mu, Atlantis")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }   // end if
                    }   // end ForEach
                }   // end HStack
                .padding(.horizontal, ComposeContentToolbarView.toolbarMargin)
            }   // end ScrollView
            .introspectScrollView { scrollView in
                scrollView.alwaysBounceHorizontal = false
            }
        }
        .background(Color(uiColor: .systemBackground))
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
        }
    }
}

private struct ComposeContentToolbarActionImage: View {
    
    let image: UIImage
    let tintColor: UIColor
    
    var body: some View {
        VectorImageView(
            image: image,
            tintColor: tintColor
        )
        .frame(width: 24, height: 24)
        .padding(12)
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
    
    public enum MediaAction: String {
        case photoLibrary
        case camera
        case browse
    }
}

extension ComposeContentToolbarView.Action {
    public func image(of state: UIControl.State) -> UIImage {
        switch self {
        case .media:
            return Asset.ObjectTools.photo.image
        case .emoji:
            return state.contains(.selected) ? Asset.Keyboard.keyboard.image : Asset.Human.faceSmiling.image
        case .poll:
            return Asset.ObjectTools.poll.image
        case .mention:
            return Asset.Symbol.at.image
        case .hashtag:
            return Asset.Symbol.number.image
        case .location:
            return Asset.ObjectTools.mappin.image
        case .contentWarning:
            return Asset.Indices.exclamationmarkOctagon.image
        case .mediaSensitive:
            return Asset.Human.eyeSlash.image
        }
    }
}
