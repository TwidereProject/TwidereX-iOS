//
//  UserContentView.swift
//  
//
//  Created by MainasuK on 2022-7-12.
//

import SwiftUI

public struct UserContentView: View {
    
    @ObservedObject public var viewModel: ViewModel
    
    public init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        HStack {
            let dimension = ProfileAvatarView.Dimension.inline
            ProfileAvatarViewRepresentable(
                configuration: .init(url: viewModel.avatarImageURL),
                dimension: dimension,
                badge: .none
            )
            .frame(
                width: dimension.primitiveAvatarButtonSize.width,
                height: dimension.primitiveAvatarButtonSize.height
            )
            VStack(alignment: .leading, spacing: .zero) {
                Spacer()
                MetaLabelRepresentable(
                    textStyle: .userAuthorName,
                    metaContent: viewModel.name
                )
                MetaLabelRepresentable(
                    textStyle: .userAuthorUsername,
                    metaContent: viewModel.acct
                )
                Spacer()
            }
            Spacer()
            switch viewModel.accessoryType {
            case .none:
                EmptyView()
            case .disclosureIndicator:
                Image(systemName: "chevron.right")
                    .foregroundColor(Color(.secondaryLabel))
            }   // end switch
        }   // end HStack
    }   // end body
    
}
