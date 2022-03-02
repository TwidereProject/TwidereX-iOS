//
//  ListItem.swift
//  
//
//  Created by MainasuK on 2022-2-28.
//

import Foundation

enum ListItem: Hashable {
    case list(record: ListRecord)
    case loader(id: UUID = UUID())
    case noResults(id: UUID = UUID())
    case showMore(id: UUID = UUID())
}
