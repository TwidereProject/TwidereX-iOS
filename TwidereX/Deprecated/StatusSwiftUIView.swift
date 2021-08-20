//
//  StatusSwiftUIView.swift
//  TwidereX
//
//  Created by MainasuK Cirno on 2021-7-12.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import SwiftUI

struct StatusSwiftUIView: View {

    let status: Status

    var body: some View {
        HStack(alignment: .top) {
            let primaryStatus = (status.repost ?? status)
            let avatarImageURL = primaryStatus.account.avatarImageURL
            // AvatarImageView(imageURL: avatarImageURL)
            VStack(alignment: .leading, spacing: 10) {
                StatusAuthorView(status: primaryStatus)
//                StatusContentView(status: primaryStatus)
            }   // end VStack
        }   // end HStack
        .clipped()
    }
}

struct StatusView_Previews: PreviewProvider {
    static var previews: some View {
        StatusSwiftUIView(status: Sample.status)
            .frame(width: 375)
            .previewLayout(.sizeThatFits)
    }
}
