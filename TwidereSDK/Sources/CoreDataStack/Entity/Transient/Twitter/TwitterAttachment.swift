//
//  TwitterAttachment.swift
//  TwitterAttachment
//
//  Created by Cirno MainasuK on 2021-8-24.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import CoreGraphics

public final class TwitterAttachment: NSObject, Codable {
    public let kind: Kind
    public let size: CGSize
    public let assetURL: String?
    public let previewURL: String?
    public let durationMS: Int?
    public let altDescription: String?
    
    public init(
        kind: TwitterAttachment.Kind,
        size: CGSize,
        assetURL: String?,
        previewURL: String?,
        durationMS: Int?,
        altDescription: String?
    ) {
        self.kind = kind
        self.size = size
        self.assetURL = assetURL
        self.previewURL = previewURL
        self.durationMS = durationMS
        self.altDescription = altDescription
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

extension TwitterAttachment {
    
    public enum Size: String {
        case thumbnail = "thumb"
        case small
        case medium
        case large
        case original = "orig"
    }
    
    public var downloadURL: String? {
        switch kind {
        case .photo:
            guard let urlString = self.assetURL, var url = URL(string: urlString) else { return assetURL }
            let format = url.pathExtension
            url.deletePathExtension()
            guard var component = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return assetURL }
            component.queryItems = [
                URLQueryItem(name: "format", value: format),
                URLQueryItem(name: "name", value: Size.original.rawValue)
            ]
            guard let downloadURL = component.url else { return assetURL }
            return downloadURL.absoluteString
        default:
            return assetURL
        }
    }
}
