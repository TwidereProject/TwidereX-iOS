//
//  Twitter+AuthorizationContext+OAuth2.swift
//  
//
//  Created by MainasuK on 2022-4-24.
//

import Foundation
import CryptoKit

extension Twitter.AuthorizationContext {
    public enum OAuth2 {
        public enum Relay { }
    }
}

extension Twitter.AuthorizationContext.OAuth2 {
    public enum Context {
        case relay(Relay.Context)        
    }
}

extension Twitter.AuthorizationContext.OAuth2.Relay {
    public typealias Context = Twitter.API.V2.OAuth2.Authorize.Relay.Query
    public typealias Response = Twitter.API.V2.OAuth2.Authorize.Relay.Response
}

extension Twitter.AuthorizationContext.OAuth2.Relay.Context {
    public func authorize(session: URLSession) async throws -> Twitter.AuthorizationContext.OAuth2.Relay.Response {
        return try await Twitter.API.V2.OAuth2.Authorize.Relay.authorize(
            session: session,
            query: self
        )
    }
}
