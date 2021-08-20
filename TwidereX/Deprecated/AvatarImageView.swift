//
//  AvatarImageView.swift
//  TwidereX
//
//  Created by MainasuK Cirno on 2021-7-12.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import SwiftUI
import Kingfisher

struct AvatarImageView: View {

    let imageURL: URL?

    @ScaledMetric(relativeTo: .headline) var _avatarSize: CGFloat = 44.0
    private var avatarSize: CGFloat {
        return max(44.0, min(88.0, _avatarSize))
    }

    var body: some View {
        KFImage(imageURL)
            .placeholder {
                Color(uiColor: .systemFill)
            }
            .cacheOriginalImage()
            .cancelOnDisappear(true)
            .fade(duration: 0.2)
            .forceTransition()
            .resizable()
            .frame(width: avatarSize, height: avatarSize)
            .clipShape(Circle())
    }
}

struct AvatarImageView_Previews: PreviewProvider {
    static var previews: some View {
        AvatarImageView(imageURL: URL(string: "https://pbs.twimg.com/profile_images/551206220707532800/7XOm99Ps_400x400.jpeg"))
            .previewLayout(.sizeThatFits)
    }
}
