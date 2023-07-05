//
//  EmptyState.swift
//  
//
//  Created by MainasuK on 2023-06-20.
//

import Foundation
import TwidereLocalization

public enum EmptyState: Swift.Error {
    case noResults
    case unableToAccess(reason: String? = nil)
    case homeListNotSelected
}

extension EmptyState {
    public var iconSystemName: String {
        switch self {
        case .noResults:
            return "eye.slash"
        case .unableToAccess:
            return "exclamationmark.triangle"
        case .homeListNotSelected:
            return "list.bullet"
        }
    }
    
    public var title: String {
        switch self {
        case .noResults:
            return L10n.Common.Controls.List.noResults
        case .unableToAccess:
            return "Unable to access"
        case .homeListNotSelected:
            return "No list selected"
        }
    }
    
    public var subtitle: String? {
        switch self {
        case .noResults:
            return nil
        case .unableToAccess(let reason):
            return reason
        case .homeListNotSelected:
            return "Please select a list to continue browsing. The home timeline is no longer available due to API changes."
        }
    }
}
