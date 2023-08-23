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
            }   // end if
            HStack(spacing: StatusHeaderView.iconImageTrailingSpacing) {
                VectorImageView(image: viewModel.image)
                    .frame(width: iconImageDimension, height: iconImageDimension)
                    .offset(y: -1)
                if viewModel.isLabelContainsMeta {
                    LabelRepresentable(
                        metaContent: viewModel.label,
                        textStyle: .statusHeader,
                        setupLabel: { label in
                            // do nothing
                        }
                    )
                } else {
                    Text(viewModel.label.string)
                        .font(Font(TextStyle.statusHeader.font))
                        .foregroundColor(Color(uiColor: TextStyle.statusHeader.textColor))
                        .lineLimit(1)
                }
                Spacer()
            }   // HStack
        }   // HStack
        .fixedSize(horizontal: false, vertical: true)
        .onTapGesture {
            // TODO:
        }
    }   // end body
    
}

extension StatusHeaderView {
    public class ViewModel: ObservableObject {
        @Published public var image: UIImage
        @Published public var label: MetaContent
        @Published public var isLabelContainsMeta: Bool
        
        @Published public var hasHangingAvatar: Bool = false
        @Published public var avatarDimension: CGFloat = StatusView.hangingAvatarButtonDimension
        
        public init(
            image: UIImage,
            label: MetaContent
        ) {
            self.image = image
            self.label = label
            self.isLabelContainsMeta = label.entities.contains(where: { entity in
                switch entity.meta {
                case .emoji: return true
                default: return false
                }
            })
        }
    }
}
