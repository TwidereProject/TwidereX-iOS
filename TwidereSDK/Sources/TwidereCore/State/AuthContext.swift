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
    
    public init(authenticationContext: AuthenticationContext) {
        self.authenticationContext = authenticationContext
        // end init
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
