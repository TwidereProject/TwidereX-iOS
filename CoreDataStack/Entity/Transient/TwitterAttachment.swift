//
//  TwitterAttachment.swift
//  TwitterAttachment
//
//  Created by Cirno MainasuK on 2021-8-24.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import CoreGraphics

final public class TwitterAttachment: NSObject, Codable {
    public let kind: Kind
    public let size: CGSize
    public let assetURL: String?
    public let previewURL: String?
    public let durationMS: Int?
    
    public init(
        kind: TwitterAttachment.Kind,
        size: CGSize,
        assetURL: String?,
        previewURL: String?,
        durationMS: Int?
    ) {
        self.kind = kind
        self.size = size
        self.assetURL = assetURL
        self.previewURL = previewURL
        self.durationMS = durationMS
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
