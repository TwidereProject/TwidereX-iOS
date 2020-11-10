//
//  TweetProvider.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020/11/10.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import Combine
import CoreDataStack

protocol TweetProvider: NeedsDependency & UIViewController {
    var disposeBag: Set<AnyCancellable> { get set }
    func tweet(for cell: TimelinePostTableViewCell) -> Future<Tweet?, Never>
}
