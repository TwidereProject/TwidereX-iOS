//
//  TwitterUserProvider.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-24.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import Combine
import CoreDataStack

protocol TwitterUserProvider: NeedsDependency & DisposeBagCollectable & UIViewController {
    func twitterUser(for cell: FriendshipTableViewCell, indexPath: IndexPath?) -> Future<TwitterUser?, Never>
}
