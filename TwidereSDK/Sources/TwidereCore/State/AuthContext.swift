//
//  AuthContext.swift
//  
//
//  Created by MainasuK on 2022-7-12.
//

import Foundation
import Combine
import CoreData
import CoreDataStack
import TwidereCommon
import TwitterSDK

public protocol AuthContextProvider {
    var authContext: AuthContext { get }
}

public class AuthContext {
    var disposeBag = Set<AnyCancellable>()

    // authentication
    public let authenticationContext: AuthenticationContext
    
    // Twitter Guest
    public private(set) var twitterGuestAuthorization: Twitter.API.Guest.GuestAuthorization?
    private var lastTwitterGuestAuthorizationTimestamp = Date()
    
    public init(authenticationContext: AuthenticationContext) {
        self.authenticationContext = authenticationContext
        // end init
        
        Timer.publish(every: 10, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else {
                    return
                }
                Task {
                    if self.twitterGuestAuthorization == nil {
                        try await self.refreshTwitterGuestAuthorization()
                    } else if abs(self.lastTwitterGuestAuthorizationTimestamp.timeIntervalSinceNow) > 1 * 60 {
                        try await self.refreshTwitterGuestAuthorization()
                    }
                } // end Task
            }
            .store(in: &disposeBag)
    }
    
    public convenience init?(authenticationIndex: AuthenticationIndex) {
        let _authenticationContext = AuthenticationContext(
            authenticationIndex: authenticationIndex,
            secret: AppSecret.default.secret
        )
        guard let authenticationContext = _authenticationContext else {
            return nil
        }
        self.init(authenticationContext: authenticationContext)
    }
    
}

extension AuthContext {
    public func twitterGuestAuthorization() async throws -> Twitter.API.Guest.GuestAuthorization {
        if let twitterGuestAuthorization = twitterGuestAuthorization {
            return twitterGuestAuthorization
        } else {
            return try await refreshTwitterGuestAuthorization()
        }
    }

    @discardableResult
    public func refreshTwitterGuestAuthorization() async throws -> Twitter.API.Guest.GuestAuthorization {
        let response = try await Twitter.API.Guest.active(
            session: URLSession(configuration: .ephemeral)
        )
        let guestAuthorization = Twitter.API.Guest.GuestAuthorization(token: response.value.guestToken)
        twitterGuestAuthorization = guestAuthorization
        lastTwitterGuestAuthorizationTimestamp = Date()
        return guestAuthorization
    }
}

#if DEBUG
extension AuthContext {
    public static func mock(context: AppContext) -> AuthContext? {
        let request = AuthenticationIndex.sortedFetchRequest
        let _authenticationIndex = try? context.managedObjectContext.fetch(request).first
        let _authContext = _authenticationIndex.flatMap { AuthContext(authenticationIndex: $0) }
        return _authContext
    }
}
#endif
