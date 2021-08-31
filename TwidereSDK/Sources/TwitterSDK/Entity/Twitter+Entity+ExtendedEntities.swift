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

extension Twitter.Entity.ExtendedEntities: Equatable { }

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
        public let videoInfo: VideoInfo?
        public let sourceStatusID: Double?
        public let sourceStatusIDStr: String?
        public let sourceUserID: Int?
        public let sourceUserIDStr: String?
        public let extAltText: String?
        
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
            case videoInfo = "video_info"
            case sourceStatusID = "source_status_id"
            case sourceStatusIDStr = "source_status_id_str"
            case sourceUserID = "source_user_id"
            case sourceUserIDStr = "source_user_id_str"
            case extAltText = "ext_alt_text"
        }
    }
}

extension Twitter.Entity.ExtendedEntities.Media: Equatable { }


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
    
    public struct VideoInfo: Codable {
        public let durationMillis: Int?
        public let variants: [Variant]?
        
        enum CodingKeys: String, CodingKey {
            case durationMillis = "duration_millis"
            case variants
        }
        
        public struct Variant: Codable {
            public let bitrate: Int?
            public let contentType: String
            public let url: String
            
            enum CodingKeys: String, CodingKey {
                case bitrate
                case contentType = "content_type"
                case url
            }
        }
    }
    
}

extension Twitter.Entity.ExtendedEntities.Media.Sizes: Equatable { }
extension Twitter.Entity.ExtendedEntities.Media.Size: Equatable { }
extension Twitter.Entity.ExtendedEntities.Media.VideoInfo: Equatable { }
extension Twitter.Entity.ExtendedEntities.Media.VideoInfo.Variant: Equatable { }

extension Twitter.Entity.ExtendedEntities.Media {
    
    public var assetURL: String? {
        switch type {
        case "animated_gif":    return videoInfo?.variants?.max(by: { ($0.bitrate ?? 0) < ($1.bitrate ?? 0) })?.url
        case "video":           return videoInfo?.variants?.max(by: { ($0.bitrate ?? 0) < ($1.bitrate ?? 0) })?.url
        case "photo":           return mediaURLHTTPS
        default:                return nil
        }
    }
    
    public var previewImageURL: String? {
        switch type {
        case "animated_gif":    return mediaURLHTTPS
        case "video":           return mediaURLHTTPS
        default:                return nil
        }
    }
    
    public var durationMS: Int? {
        switch type {
        case "video":           return videoInfo?.durationMillis
        default:                return nil
        }
    }
    
}
