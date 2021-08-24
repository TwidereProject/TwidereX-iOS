//
//  TwitterAttachment.swift
//  TwitterAttachment
//
//  Created by Cirno MainasuK on 2021-8-24.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import CoreGraphics

public struct TwitterAttachment: Codable {
    public let kind: Kind
    public let size: CGSize
    public let assetURL: String?
    public let previewURL: String?
    
    public init(
        kind: TwitterAttachment.Kind,
        size: CGSize,
        assetURL: String?,
        previewURL: String?
    ) {
        self.kind = kind
        self.size = size
        self.assetURL = assetURL
        self.previewURL = previewURL
    }
}

extension TwitterAttachment {
    public enum Kind: String, Codable {
        case photo
        case video
        case animatedGIF
        
        enum CodingKeys: String, CodingKey {
            case photo
            case video
            case animatedGIF = "animated_gif"
        }
    }
}
