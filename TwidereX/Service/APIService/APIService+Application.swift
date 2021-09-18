//
//  APIService+Application.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-7.
//  Copyright © 2020 Twidere. All rights reserved.
//

import Foundation
import Combine
import CoreDataStack
import CommonOSLog
import TwitterSDK
import MastodonSDK

extension APIService {
    
    public func rateLimitStatus(authorization: Twitter.API.OAuth.Authorization) -> AnyPublisher<Twitter.Response.Content<Twitter.Entity.RateLimitStatus>, Error> {
        return Twitter.API.Application.rateLimitStatus(session: session, authorization: authorization)
    }
    
}

extension APIService {

    #if DEBUG
    private static let clientName = "Pyro"
    private static let appWebsite: String? = nil
    #else
    private static let clientName = "Twidere X"
    private static let appWebsite: String? = "https://x.twidere.com"
    #endif
    
    public func createMastodonApplication(
        domain: String
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Application> {
        let query = Mastodon.API.App.CreateQuery(
            clientName: APIService.clientName,
            redirectURIs: MastodonAuthenticationController.callbackURL,
            website: APIService.appWebsite
        )
        let application = try await Mastodon.API.App.create(session: session, domain: domain, query: query)
        return application
    }

}
