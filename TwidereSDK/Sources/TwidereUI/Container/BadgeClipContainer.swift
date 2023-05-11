//
//  BadgeClipContainer.swift
//  
//
//  Created by MainasuK on 2023/5/9.
//

import SwiftUI

public struct BadgeClipContainer<Content: View, Badge: View>: View {
    
    public let content: Content
    public let badge: Badge
    
    public init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder badge: () -> Badge
    ) {
        self.content = content()
        self.badge = badge()
    }
    
    public var body: some View {
        ZStack(alignment: Alignment(horizontal: .trailing, vertical: .bottom)) {
            content
            badge
                .scaleEffect(1.2)
                .alignmentGuide(HorizontalAlignment.trailing, computeValue: { d in d.width - 4 })
                .alignmentGuide(VerticalAlignment.bottom, computeValue: { d in d.height - 4 })
                .blendMode(.destinationOut)
                .overlay {
                    badge
                }
            
        }
        .compositingGroup()
    }
}

struct BadgeClipContainer_Previews: PreviewProvider {
    static var previews: some View {
        BadgeClipContainer(content: {
            Color.blue
                .frame(width: 44, height: 44)
        }, badge: {
            Image(uiImage: Asset.Badge.verified.image)
        })
    }
}
