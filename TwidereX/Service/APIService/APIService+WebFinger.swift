//
//  APIService+WebFinger.swift
//  APIService+WebFinger
//
//  Created by Cirno MainasuK on 2021-8-13.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation

extension APIService {
    
    private static func webFingerEndpointURL(domain: String) -> URL {
        return URL(string: "https://\(domain)/")!
            .appendingPathComponent(".well-known")
            .appendingPathComponent("webfinger")
    }
    
    
    /// Try get host via server WebFinger
    ///
    /// - Parameter domain: the server host. e.g. example.com
    /// - Returns: new domain if server set WebFinger. Otherwise, return `domain`
    func webFinger(domain: String) async throws -> String {
        let url = APIService.webFingerEndpointURL(domain: domain)
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 5)
        let (_, response) = try await session.data(for: request, delegate: nil)
        return response.url?.host ?? domain
    }

}
