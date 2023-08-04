//
//  HistoryItem.swift
//  TwidereX
//
//  Created by MainasuK on 2022-7-29.
//  Copyright © 2022 Twidere. All rights reserved.
//


import Foundation
import CoreDataStack
import TwidereCore

enum HistoryItem: Hashable {
    case history(record: ManagedObjectRecord<History>)
}
