//
//  Twitter+ExtendedEntities.swift
//  TwitterAPI
//
//  Created by Cirno MainasuK on 2020-9-3.
//

import Foundation
import CoreGraphics

extension Twitter.Entity {
    public struct ExtendedEntities: Codable {
        public let media: [Media]?

    }
}

extension Twitter.Entity.ExtendedEntities {
    public struct Media: Codable {
        public let id: Double?
        public let idStr: String?
        public let indices: [Int]?
        public let mediaURL: String?
        public let mediaURLHTTPS: String?
        public let url: String?
        public let displayURL: String?
        public let expandedURL: String?
        public let type: String?
        public let sizes: Sizes?
        public let sourceStatusID: Double?
        public let sourceStatusIDStr: String?
        public let sourceUserID: Int?
        public let sourceUserIDStr: String?
        
        enum CodingKeys: String, CodingKey {
            case id = "id"
            case idStr = "id_str"
            case indices = "indices"
            case mediaURL = "media_url"
            case mediaURLHTTPS = "media_url_https"
            case url = "url"
            case displayURL = "display_url"
            case expandedURL = "expanded_url"
            case type = "type"
            case sizes = "sizes"
            case sourceStatusID = "source_status_id"
            case sourceStatusIDStr = "source_status_id_str"
            case sourceUserID = "source_user_id"
            case sourceUserIDStr = "source_user_id_str"
        }
        
        public func photoURL(sizeKind: Sizes.SizeKind) -> (URL, CGSize)? {
            guard let type = self.type, type == "photo" else { return nil }
            guard let urlString = mediaURLHTTPS, var url = URL(string: urlString) else { return nil }
            guard let sizes = self.sizes, let size = sizes.size(kind: sizeKind),
                  let w = size.w, let h = size.h else { return nil }
            
            let format = url.pathExtension
            url.deletePathExtension()
            
            guard var component = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
            component.queryItems = [
                URLQueryItem(name: "format", value: format),
                URLQueryItem(name: "name", value: sizeKind.rawValue)
            ]
            
            guard let targetURL = component.url else { return nil }
            let targetSize = CGSize(width: w, height: h)
            return (targetURL, targetSize)
        }
    }
}

extension Twitter.Entity.ExtendedEntities.Media {
    public struct Sizes: Codable {
        public let thumbnail: Size?
        public let small: Size?
        public let medium: Size?
        public let large: Size?
        
        enum CodingKeys: String, CodingKey {
            case thumbnail = "thumb"
            case small = "small"
            case medium = "medium"
            case large = "large"
        }
        
        public enum SizeKind: String {
            case thumbnail = "thumb"
            case small
            case medium
            case large
        }
        
        public func size(kind: SizeKind) -> Size? {
            switch kind {
            case .thumbnail:    return thumbnail
            case .small:        return small
            case .medium:       return medium
            case .large:        return large
            }
        }
    }
    
    public struct Size: Codable {
        public let w: Int?
        public let h: Int?
        public let resize: String?
        
        enum CodingKeys: String, CodingKey {
            case w = "w"
            case h = "h"
            case resize = "resize"
        }
        
        public init(w: Int?, h: Int?, resize: String?) {
            self.w = w
            self.h = h
            self.resize = resize
        }
    }
    
    public enum Resize: String {
        case fit
        case crop
    }
}
