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
    case trend
    case loader(id: UUID)
    case noResults
    case showMore
}
