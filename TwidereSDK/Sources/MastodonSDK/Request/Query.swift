//
//  MastodonRequest.swift
//  MastodonRequest
//
//  Created by Cirno MainasuK on 2021-8-17.
//

import Foundation

protocol Query {
    var contentType: String? { get }
    var queryItems: [URLQueryItem]? { get }
    var body: Data? { get }
}

extension Query where Self: Encodable {
    var contentType: String? {
        return "application/json; charset=utf-8"
    }
    var body: Data? {
        return try? Mastodon.API.encoder.encode(self)
    }
}

extension Query {
    static func multipartContentType(boundary: String = Multipart.boundary) -> String {
        return "multipart/form-data; charset=utf-8; boundary=\"\(boundary)\""
    }
}
