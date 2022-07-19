//
//  ProfileAvatarViewRepresentable.swift
//  
//
//  Created by MainasuK on 2022-7-12.
//

import UIKit
import SwiftUI
import TwidereCore

public struct ProfileAvatarViewRepresentable: UIViewRepresentable {
    
    public let configuration: AvatarImageView.Configuration
    public let dimension: ProfileAvatarView.Dimension
    public let badge: ProfileAvatarView.Badge
    
    public init(
        configuration: AvatarImageView.Configuration,
        dimension: ProfileAvatarView.Dimension,
        badge: ProfileAvatarView.Badge
    ) {
        self.configuration = configuration
        self.dimension = dimension
        self.badge = badge
    }
    
    public func makeUIView(context: Context) -> ProfileAvatarView {
        let view = ProfileAvatarView()
        view.setup(dimension: dimension)
        view.badge = badge
        return view
    }
    
    public func updateUIView(_ view: ProfileAvatarView, context: Context) {
        view.avatarButton.avatarImageView.configure(configuration: configuration)
    }
    
}

#if DEBUG
struct ProfileAvatarViewRepresentable_Preview: PreviewProvider {
    static var previews: some View {
        Group {
            ProfileAvatarViewRepresentable(
                configuration: .init(url: URL(string: "https://upload.wikimedia.org/wikipedia/commons/2/2c/Rotating_earth_%28large%29.gif")),
                dimension: .inline,
                badge: .robot
            )
            .frame(width: 44, height: 44, alignment: .center)
            .previewLayout(.fixed(width: 44, height: 44))
            ProfileAvatarViewRepresentable(
                configuration: .init(url: URL(string: "https://upload.wikimedia.org/wikipedia/commons/2/2c/Rotating_earth_%28large%29.gif")),
                dimension: .plain,
                badge: .circle(.mastodon)
            )
            .frame(width: 88, height: 88, alignment: .center)
            .previewLayout(.fixed(width: 88, height: 88))
        }
    }
}
#endif


