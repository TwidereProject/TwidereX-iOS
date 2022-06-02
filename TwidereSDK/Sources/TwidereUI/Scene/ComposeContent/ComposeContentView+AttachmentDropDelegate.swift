//
//  ComposeContentView+AttachmentDropDelegate.swift
//  
//
//  Created by MainasuK on 2022-5-24.
//

import SwiftUI
import UniformTypeIdentifiers

extension ComposeContentView {
    
    struct AttachmentDropDelegate: DropDelegate {
        let isAttachmentViewModelAppendable: Bool
        let addAttachmentViewModel: (AttachmentViewModel) -> Void
        
        func validateDrop(info: DropInfo) -> Bool {
            return info.hasItemsConforming(to: AttachmentViewModel.writableTypeIdentifiersForItemProvider)
        }
        
        func dropUpdated(info: DropInfo) -> DropProposal? {
            // FIXME: somehow it's not works
            // do not accept in-app drag & drop to avoid duplicate
            guard !info.hasItemsConforming(to: [AttachmentViewModel.typeIdentifier]) else {
                return DropProposal(operation: .cancel)
            }
            
            return DropProposal(operation: isAttachmentViewModelAppendable ? .copy : .forbidden)
        }
        
        func performDrop(info: DropInfo) -> Bool {
            let types: [UTType] = [.movie, .image]
            
            for type in types {
                guard let attachmentViewModel = createAttachmentViewModel(info: info, type: type) else { continue }
                addAttachmentViewModel(attachmentViewModel)
                return true
            }
            
            return false
        }
        
        private func createAttachmentViewModel(info: DropInfo, type: UTType) -> AttachmentViewModel? {
            guard info.hasItemsConforming(to: [type]),
                  let itemProvider = info.itemProviders(for: [type]).first
            else { return nil }
            return AttachmentViewModel(input: .itemProvider(itemProvider))
        }
    }
    
}
