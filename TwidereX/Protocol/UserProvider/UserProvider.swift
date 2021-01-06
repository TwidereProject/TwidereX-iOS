//
//  UserProvider.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-24.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import Combine
import CoreDataStack

protocol UserProvider: NeedsDependency & DisposeBagCollectable & UIViewController {
    func twitterUser() -> Future<TwitterUser?, Never>
    func twitterUser(for cell: UITableViewCell, indexPath: IndexPath?) -> Future<TwitterUser?, Never>
}
