//
//  AttachmentView.swift
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
import AVKit

public struct AttachmentView: View {
    
    static let size = CGSize(width: 56, height: 56)
    static let cornerRadius: CGFloat = 8
    
    @ObservedObject var viewModel: AttachmentViewModel
    
    let action: (Action) -> Void
    
    @State var isCaptionEditorPresented = false
    @State var caption = ""

    public var body: some View {
        Menu {
            menu
        } label: {
            let image = viewModel.thumbnail ?? .placeholder(color: .systemGray3)
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: AttachmentView.size.width, height: AttachmentView.size.height)
                .overlay {
                    ZStack {
                        // spinner
                        if viewModel.output == nil {
                            Color.clear
                                .background(.ultraThinMaterial)
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .foregroundStyle(.regularMaterial)
                        }
                        // border
                        RoundedRectangle(cornerRadius: AttachmentView.cornerRadius)
                            .stroke(Color.black.opacity(0.05))
                    }
                    .transition(.opacity)
                }
                .overlay(alignment: .bottom) {
                    HStack(alignment: .bottom) {
                        // alt
                        VStack(spacing: 2) {
                            switch viewModel.output {
                            case .video:
                                Image(uiImage: Asset.Media.playerRectangle.image)
                                    .resizable()
                                    .frame(width: 16, height: 12)
                            default:
                                EmptyView()
                            }
                            if !viewModel.caption.isEmpty {
                                Image(uiImage: Asset.Media.altRectangle.image)
                                    .resizable()
                                    .frame(width: 16, height: 12)
                            }
                        }
                        Spacer()
                        // option
                        Image(systemName: "ellipsis")
                            .resizable()
                            .frame(width: 12, height: 12)
                            .symbolVariant(.circle)
                            .symbolVariant(.fill)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .black)
                    }
                    .padding(6)
                }
                .cornerRadius(AttachmentView.cornerRadius)
        }   // end Menu
        .sheet(isPresented: $isCaptionEditorPresented) {
            captionSheet
        }   // end sheet

    }   // end body
    
    var menu: some View {
        Group {
            Button(
                action: {
                    action(.preview)
                },
                label: {
                    Label(L10n.Scene.Compose.Media.preview, systemImage: "photo")
                }
            )
            // caption
            Button(
                action: {
                    action(.caption)
                    caption = viewModel.caption
                    isCaptionEditorPresented.toggle()
                },
                label: {
                    let title = viewModel.caption.isEmpty ? L10n.Scene.Compose.Media.Caption.add : L10n.Scene.Compose.Media.Caption.update
                    Label(title, systemImage: "text.bubble")
                    // FIXME: https://stackoverflow.com/questions/72318730/how-to-customize-swiftui-menu
                    // add caption subtitle
                }
            )
            Divider()
            // remove
            Button(
                role: .destructive,
                action: {
                    action(.remove)
                },
                label: {
                    Label(L10n.Scene.Compose.Media.remove, systemImage: "minus.circle")
                }
            )
        }
    }
    
    var captionSheet: some View {
        NavigationView {
            ScrollView(.vertical) {
                VStack {
                    // preview
                    switch viewModel.output {
                    case .image:
                        let image = viewModel.thumbnail ?? .placeholder(color: .systemGray3)
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .video(let url, _):
                        let player = AVPlayer(url: url)
                        VideoPlayer(player: player)
                            .frame(height: 300)
                    case .none:
                        EmptyView()
                    }
                    // caption textField
                    TextField(
                        text: $caption,
                        prompt: Text(L10n.Scene.Compose.Media.Caption.addADescriptionForThisImage)
                    ) {
                        Text(L10n.Scene.Compose.Media.Caption.update)
                    }
                    .padding()
                    .introspectTextField { textField in
                        textField.becomeFirstResponder()
                    }
                }
            }
            .navigationTitle(L10n.Scene.Compose.Media.Caption.update)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        isCaptionEditorPresented.toggle()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .frame(width: 30, height: 30, alignment: .center)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(Color(uiColor: .secondaryLabel), Color(uiColor: .tertiaryLabel))
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.caption = caption.trimmingCharacters(in: .whitespacesAndNewlines)
                        isCaptionEditorPresented.toggle()
                    } label: {
                        Text(L10n.Common.Controls.Actions.save)
                    }
                }
            }
        }   // end NavigationView
    }
    
}

extension AttachmentView {
    public enum Action: Hashable {
        case preview
        case caption
        case remove
    }
}
