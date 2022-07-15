//
//  AuthContext.swift
//  
//
//  Created by MainasuK on 2022-7-12.
//

import Foundation
import CoreData
import CoreDataStack

public class AuthContext {
    
    public let authenticationContext: AuthenticationContext
    
    public init(authenticationContext: AuthenticationContext) {
        self.authenticationContext = authenticationContext
    }
    
}
