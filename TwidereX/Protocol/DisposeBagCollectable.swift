//
//  DisposeBagCollectable.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-1.
//  Copyright © 2020 Twidere. All rights reserved.
//

import Foundation
import Combine

protocol DisposeBagCollectable: class {
    var disposeBag: Set<AnyCancellable> { get set }
}
