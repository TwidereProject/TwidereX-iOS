//
//  MediaMetaIndicatorView.swift
//  
//
//  Created by MainasuK on 2023/4/19.
//

import SwiftUI

public struct MediaMetaIndicatorView: View {
    
    @ObservedObject public var viewModel: MediaView.ViewModel
    
    public init(viewModel: MediaView.ViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        HStack {
            Spacer()
            Group {
                if viewModel.mediaKind == .animatedGIF {
                    Text("GIF")
                } else if let durationText = viewModel.durationText {
                    Text("\(Image(systemName: "play.fill")) \(durationText)")
                }
            }
            .foregroundColor(Color(uiColor: .label))
            .font(.system(.footnote, design: .default, weight: .medium))
            .padding(.horizontal, 5)
            .padding(.vertical, 3)
            .background(.thinMaterial)
            .cornerRadius(4)
        }
        .padding(EdgeInsets(top: 0, leading: 11, bottom: 8, trailing: 11))
        .allowsHitTesting(false)
    }
}
