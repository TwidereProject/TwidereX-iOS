//
//  MastodonFieldContainer.swift
//  MastodonFieldContainer
//
//  Created by Cirno MainasuK on 2021-8-18.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import CoreDataStack
import MastodonSDK

protocol MastodonFieldContainer {
    var fields: [Mastodon.Entity.Field]? { get }
}

extension MastodonFieldContainer {
    var mastodonFields: [MastodonField] {
        return fields.flatMap { fields in
            fields.map { MastodonField(field: $0) }
        } ?? []
    }
}

extension Mastodon.Entity.Account: MastodonFieldContainer { }
