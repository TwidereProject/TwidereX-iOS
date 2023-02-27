//
//  ContextMenuInteractionRepresentable.swift
//  
//
//  Created by MainasuK on 2023/2/27.
//

import UIKit
import SwiftUI

struct ContextMenuInteractionRepresentable<Content: View>: UIViewRepresentable {
    
    let contextMenuContentPreviewProvider: UIContextMenuContentPreviewProvider
    let contextMenuActionProvider: UIContextMenuActionProvider
    @ViewBuilder var view: Content
    let previewAction: () -> Void
    
    func makeUIView(context: Context) -> UIView {
        let hostingController = UIHostingController(rootView: view)
        hostingController.view.backgroundColor = .clear
        context.coordinator.hostingViewController = hostingController
        let interaction = UIContextMenuInteraction(delegate: context.coordinator)
        hostingController.view.addInteraction(interaction)
        hostingController.view.setContentHuggingPriority(.defaultHigh, for: .vertical)
        return hostingController.view
    }
    
    func updateUIView(_ view: UIView, context: Context) {
        // do nothing
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(representable: self)
    }
    
    class Coordinator: NSObject, UIContextMenuInteractionDelegate {
        let representable: ContextMenuInteractionRepresentable
        
        var hostingViewController: UIHostingController<Content>?
        
        init(representable: ContextMenuInteractionRepresentable) {
            self.representable = representable
        }
        
        func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
            UIContextMenuConfiguration(identifier: nil, previewProvider: representable.contextMenuContentPreviewProvider, actionProvider: representable.contextMenuActionProvider)
        }
        
        func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configuration: UIContextMenuConfiguration, highlightPreviewForItemWithIdentifier identifier: NSCopying) -> UITargetedPreview? {
            guard let hostingViewController = self.hostingViewController else { return nil }
            let parameters = UIPreviewParameters()
            parameters.backgroundColor = .clear
            parameters.visiblePath = UIBezierPath(roundedRect: hostingViewController.view.bounds, cornerRadius: MediaGridContainerView.cornerRadius)
            return UITargetedPreview(view: hostingViewController.view, parameters: parameters)
        }
        
        func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
            representable.previewAction()
        }
        
        func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willDisplayMenuFor configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
            print(#function)
        }
        
        func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willEndFor configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
            print(#function)
        }
    }
}
