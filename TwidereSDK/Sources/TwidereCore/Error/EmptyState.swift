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
}

extension EmptyState {
    public var iconSystemName: String {
        switch self {
        case .noResults:
            return "eye.slash"
        case .unableToAccess:
            return "exclamationmark.triangle"
        }
    }
    
    public var title: String {
        switch self {
        case .noResults:
            return L10n.Common.Controls.List.noResults
        case .unableToAccess:
            return "Unable to access"
        }
    }
    
    public var subtitle: String? {
        switch self {
        case .noResults:
            return nil
        case .unableToAccess(let reason):
            return reason
        }
    }
}
