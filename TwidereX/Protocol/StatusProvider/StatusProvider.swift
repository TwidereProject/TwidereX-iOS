//
//  StatusProvider.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020/11/10.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import Combine
import CoreDataStack

protocol StatusProvider: NeedsDependency & DisposeBagCollectable & UIViewController {
    func tweet() -> Future<Tweet?, Never>
    func tweet(for cell: UITableViewCell, indexPath: IndexPath?) -> Future<Tweet?, Never>
    func tweet(for cell: SearchMediaCollectionViewCell) -> Future<Tweet?, Never>
}

extension StatusProvider {
    
    func tweet() -> Future<Tweet?, Never> {
        return Future { promise in promise(.success(nil)) }
    }
    
    func tweet(for cell: UITableViewCell, indexPath: IndexPath?) -> Future<Tweet?, Never> {
        return Future { promise in promise(.success(nil)) }
    }
    
    func tweet(for cell: SearchMediaCollectionViewCell) -> Future<Tweet?, Never> {
        return Future { promise in promise(.success(nil)) }
    }
    
}
