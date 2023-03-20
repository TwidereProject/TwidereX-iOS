//
//  ContextMenuInteractionRepresentable.swift
//  
//
//  Created by MainasuK on 2023/2/27.
//

import os.log
import UIKit
import SwiftUI
import Combine

struct ContextMenuInteractionRepresentable<Content: View>: UIViewRepresentable {
    
    let contextMenuContentPreviewProvider: UIContextMenuContentPreviewProvider
    let contextMenuActionProvider: UIContextMenuActionProvider
    @ViewBuilder var view: Content
    let previewActionWithContext: (ContextMenuInteractionPreviewActionContext) -> Void
    
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
        let logger = Logger(subsystem: "ContextMenuInteractionRepresentable", category: "Coordinator")
        
        var disposeBag = Set<AnyCancellable>()
        
        let representable: ContextMenuInteractionRepresentable
        
        var hostingViewController: UIHostingController<Content>?
        
        var activePreviewActionContext: ContextMenuInteractionPreviewActionContext?
        
        @Published var previewViewFrameInWindow: CGRect = .zero
        
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
            let targetedPreview = UITargetedPreview(view: hostingViewController.view, parameters: parameters)
            return targetedPreview
        }
        
        func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configuration: UIContextMenuConfiguration, dismissalPreviewForItemWithIdentifier identifier: NSCopying) -> UITargetedPreview? {
            return activePreviewActionContext?.dismissTargetedPreviewHandler()
        }
        
        func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
            let context = ContextMenuInteractionPreviewActionContext(
                interaction: interaction,
                animator: animator
            )
            activePreviewActionContext = context
            representable.previewActionWithContext(context)
        }
        
        func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willDisplayMenuFor configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
            print(#function)
        }
        
        func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willEndFor configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
            print(#function)
        }
    }
}

public class ContextMenuInteractionPreviewActionContext {
    public let interaction: UIContextMenuInteraction
    public let animator: UIContextMenuInteractionCommitAnimating
    public var dismissTargetedPreviewHandler: () -> UITargetedPreview? = { nil }
    
    public init(interaction: UIContextMenuInteraction, animator: UIContextMenuInteractionCommitAnimating) {
        self.interaction = interaction
        self.animator = animator
    }
}

extension ContextMenuInteractionPreviewActionContext {
    public func platterClippingView() -> UIView? {
        // iOS 16: pass
        guard let window = interaction.view?.window,
              let contextMenuContainerView = window.subviews.first(where: { !($0.gestureRecognizers ?? []).isEmpty }),
              let contextMenuPlatterTransitionView = contextMenuContainerView.subviews.first(where: { !($0 is UIVisualEffectView) }),
              let morphingPlatterView = contextMenuPlatterTransitionView.subviews.first(where: { ($0.gestureRecognizers ?? []).count == 1 }),
              let platterClippingView = morphingPlatterView.subviews.last, platterClippingView.bounds != .zero
        else {
            assertionFailure("system API changes!")
            return nil
        }
 
        return platterClippingView
    }
}
