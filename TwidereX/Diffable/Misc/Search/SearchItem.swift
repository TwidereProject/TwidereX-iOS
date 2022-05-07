//
//  SearchItem.swift
//  TwidereX
//
//  Created by MainasuK on 2021-12-22.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import TwidereCore

enum SearchItem: Hashable {
    case history(record: SavedSearchRecord)
    case trend(trend: TrendObject)
    case loader(id: UUID = UUID())
    case noResults(id: UUID = UUID())
    case showMore(id: UUID = UUID())
}
