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
    
    @State private var iconImageDimension = CGFloat.zero
    
    public var body: some View {
        HStack(spacing: .zero) {
            if viewModel.hasHangingAvatar {
                let width = viewModel.avatarDimension
                    + StatusView.hangingAvatarButtonTrailingSapcing
                    - iconImageDimension
                    - StatusHeaderView.iconImageTrailingSpacing
                Color.clear
                    .frame(width: max(.zero, width))
            }
            Button {
                
            } label: {
                HStack(spacing: StatusHeaderView.iconImageTrailingSpacing) {
                    Image(uiImage: viewModel.image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: iconImageDimension, height: iconImageDimension)
                        .clipShape(Circle())
                    LabelRepresentable(
                        metaContent: viewModel.label,
                        textStyle: .statusHeader
                    )
                    .background(GeometryReader { proxy in
                        Color.clear.preference(
                            key: ViewHeightKey.self,
                            value: proxy.frame(in: .local).size.height
                        )
                    })
                    .onPreferenceChange(ViewHeightKey.self) { height in
                        self.iconImageDimension = height
                    }
                    .border(.red, width: 1)
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
        
        public init(
            image: UIImage,
            label: MetaContent
        ) {
            self.image = image
            self.label = label
        }
    }
}
