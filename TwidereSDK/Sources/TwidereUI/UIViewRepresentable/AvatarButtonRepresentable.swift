//
//  AvatarButtonRepresentable.swift
//  
//
//  Created by MainasuK on 2022-5-19.
//

import UIKit
import SwiftUI
import TwidereCore

public struct AvatarButtonRepresentable: UIViewRepresentable {
    
    public let configuration: AvatarImageView.Configuration
    
    public func makeUIView(context: Context) -> AvatarButton {
        let view = AvatarButton()
        return view
    }
    
    public func updateUIView(_ view: AvatarButton, context: Context) {
        view.avatarImageView.configure(configuration: configuration)
    }
    
}

#if DEBUG
struct AvatarButtonRepresentable_Preview: PreviewProvider {
    static var previews: some View {
        AvatarButtonRepresentable(configuration: .init(
            url: URL(string: "https://upload.wikimedia.org/wikipedia/commons/2/2c/Rotating_earth_%28large%29.gif")
        ))
        .frame(width: 44, height: 44, alignment: .center)
        .previewLayout(.fixed(width: 44, height: 44))
    }
}
#endif
