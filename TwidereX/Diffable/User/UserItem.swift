//
//  UserItem.swift
//  UserItem
//
//  Created by Cirno MainasuK on 2021-8-25.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import CoreDataStack

enum UserItem: Hashable {
    case authenticationIndex(record: ManagedObjectRecord<AuthenticationIndex>)
}


