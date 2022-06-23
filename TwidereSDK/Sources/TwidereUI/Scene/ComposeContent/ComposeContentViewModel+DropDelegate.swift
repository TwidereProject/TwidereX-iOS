//
//  ComposeContentViewModel+DropDelegate.swift
//  
//
//  Created by MainasuK on 2022-5-23.
//

import Foundation
import SwiftUI

// MARK: - DropDelegate
extension ComposeContentViewModel: DropDelegate {
    
    public func dropUpdated(info: DropInfo) -> DropProposal? {
        if info.hasItemsConforming(to: [AttachmentViewModel.typeIdentifier]) {
            return .init(operation: .move)
        }
        
        return nil
    }

    public func performDrop(info: DropInfo) -> Bool {
        return false
    }

}
