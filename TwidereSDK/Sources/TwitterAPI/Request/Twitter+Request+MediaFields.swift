//
//  Twitter+Request+MediaFields.swift
//  TwitterAPI
//
//  Created by Cirno MainasuK on 2020-9-16.
//

import Foundation

extension Twitter.Request {
    public enum MediaFields: String, CaseIterable {
        case durationMS = "duration_ms"
        case height = "height"
        case mediaKey = "media_key"
        case previewImageURL = "preview_image_url"
        case type = "type"
        case url = "url"
        case width = "width"
        case publicMetrics = "public_metrics"
        case nonPublicMetrics = "non_public_metrics"
        case organicMetrics = "organic_metrics"
        case promotedMetrics = "promoted_metrics"
        
        public static var allCasesQueryItem: URLQueryItem {
            let value = TwitterFields.allCases.map { $0.rawValue }.joined(separator: ",")
            return URLQueryItem(name: "media.fields", value: value)
        }
    }
}
