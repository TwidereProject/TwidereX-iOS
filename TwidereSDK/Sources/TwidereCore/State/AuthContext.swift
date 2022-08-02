//
//  AuthContext.swift
//  
//
//  Created by MainasuK on 2022-7-12.
//

import Foundation
import CoreData
import CoreDataStack
import TwidereCommon

public class AuthContext {
    
    public let authenticationContext: AuthenticationContext
    
    public init(authenticationContext: AuthenticationContext) {
        self.authenticationContext = authenticationContext
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
