//
//  MastodonUser.swift
//  MastodonUser
//
//  Created by Cirno MainasuK on 2021-8-26.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import CoreDataStack

extension MastodonUser {
    var name: String {
        if displayName.isEmpty {
            return username
        } else {
            return displayName
        }
    }
    
    var acctWithDomain: String {
        if !acct.contains("@") {
            // Safe concat due to username cannot contains "@"
            return username + "@" + domain
        } else {
            return acct
        }
    }
}
