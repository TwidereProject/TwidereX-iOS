//
//  AvatarClipShape.swift
//  
//
//  Created by MainasuK on 2023/4/20.
//

import SwiftUI

public struct AvatarClipShape: Shape, Animatable {
    var avatarStyle: UserDefaults.AvatarStyle
    var progress: CGFloat
    
    public var animatableData: CGFloat {
        get {
            switch avatarStyle {
            case .circle:           return 0.0
            case .roundedSquare:    return 1.0
            }
        }
        set { progress = newValue }
    }
    
    public init(avatarStyle: UserDefaults.AvatarStyle) {
        self.avatarStyle = avatarStyle
        self.progress = {
            switch avatarStyle {
            case .circle:           return 0.0
            case .roundedSquare:    return 1.0
            }
        }()
        // end init
    }
    
    public func path(in rect: CGRect) -> Path {
        let cornerRadius = lerp(v0: rect.width / 2, v1: rect.width / 4, t: progress)
        return RoundedRectangle(cornerRadius: cornerRadius).path(in: rect)
    }
    
}

extension AvatarClipShape {
    
    // linear interpolation
    func lerp(v0: CGFloat, v1: CGFloat, t: CGFloat) -> CGFloat {
        return (1 - t) * v0 + (t * v1)
    }
}
