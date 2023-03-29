//
//  StatusHeaderView.swift
//  
//
//  Created by MainasuK on 2023/2/3.
//

import SwiftUI
import TwidereAsset
import TwidereLocalization
import Meta
import Kingfisher

protocol StatusHeaderViewDelegate: AnyObject {
    func viewDidPressed(_ viewModel: StatusHeaderView.ViewModel)
}

public struct StatusHeaderView: View {
    
    static var iconImageTrailingSpacing: CGFloat { 4.0 }
    
    @ObservedObject public var viewModel: ViewModel
    
    @ScaledMetric(relativeTo: .footnote) private var iconImageDimension: CGFloat = 16

    public var body: some View {
        HStack(spacing: .zero) {
            if viewModel.hasHangingAvatar {
                let width = viewModel.avatarDimension
                    + StatusView.hangingAvatarButtonTrailingSpacing
                    - iconImageDimension
                    - StatusHeaderView.iconImageTrailingSpacing
                Color.clear
                    .frame(width: max(.leastNonzeroMagnitude, width))
            }
            Button {
                
            } label: {
                HStack(spacing: StatusHeaderView.iconImageTrailingSpacing) {
                    Color.clear
                        .frame(width: iconImageDimension)
                    LabelRepresentable(
                        metaContent: viewModel.label,
                        textStyle: .statusHeader,
                        setupLabel: { label in
                            // do nothing
                        }
                    )
                    .overlay(alignment: .leading) {
                        VectorImageView(image: viewModel.image)
                            .frame(width: iconImageDimension, height: iconImageDimension)
                            .offset(x: -(StatusHeaderView.iconImageTrailingSpacing + iconImageDimension), y: 0)
                    }
                    Spacer()
                }
            }   // end Button
        }
    }
    
}

extension StatusHeaderView {
    public class ViewModel: ObservableObject {
        @Published public var image: UIImage
        @Published public var label: MetaContent
        
        @Published public var hasHangingAvatar: Bool = false
        @Published public var avatarDimension: CGFloat = StatusView.hangingAvatarButtonDimension
        
        // output
        public var viewSize: CGSize = .zero
        
        public init(
            image: UIImage,
            label: MetaContent
        ) {
            self.image = image
            self.label = label
        }
    }
}
