//
//  PrototypeStatusViewRepresentable.swift
//  
//
//  Created by MainasuK on 2022-7-25.
//

import SwiftUI
import TwitterMeta
import TwidereCore

public struct PrototypeStatusViewRepresentable: UIViewRepresentable {
    
    private let now = Date()
        
    let style: Style
    let configurationContext: StatusView.ConfigurationContext

    @Binding var height: CGFloat
    
    public init(
        style: Style,
        configurationContext: StatusView.ConfigurationContext,
        height: Binding<CGFloat>
    ) {
        self.style = style
        self.configurationContext = configurationContext
        self._height = height
    }
    
    public func makeUIView(context: Context) -> PrototypeStatusView {
        let view = PrototypeStatusView()
        switch style {
        case .timeline:
            view.statusView.setup(style: .inline)
            view.statusView.toolbar.setup(style: .inline)
        case .thread:
            view.statusView.setup(style: .plain)
            view.statusView.toolbar.setup(style: .plain)
        }
        view.delegate = context.coordinator

        view.translatesAutoresizingMaskIntoConstraints = false
        view.setContentCompressionResistancePriority(.required, for: .vertical)

        view.statusView.prepareForReuse()
        view.statusView.viewModel.timestamp = now
        view.statusView.viewModel.dateTimeProvider = configurationContext.dateTimeProvider

        return view
    }
    
    public func updateUIView(_ view: PrototypeStatusView, context: Context) {
        let statusView = view.statusView
        statusView.viewModel.authorAvatarImage = Asset.Scene.Preference.twidereAvatar.image
        statusView.viewModel.authorName = PlaintextMetaContent(string: "Twidere")
        statusView.viewModel.authorUsername = "TwidereProject"
        
        let content = TwitterContent(content: L10n.Scene.Settings.Display.Preview.thankForUsingTwidereX)
        statusView.viewModel.content = TwitterMetaContent.convert(
            content: content,
            urlMaximumLength: 16,
            twitterTextProvider: configurationContext.twitterTextProvider
        )

        view.setNeedsLayout()
        view.layoutIfNeeded()
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
}

extension PrototypeStatusViewRepresentable {
    
    public class Coordinator: PrototypeStatusViewDelegate {
        
        let representable: PrototypeStatusViewRepresentable
        
        init(_ representable: PrototypeStatusViewRepresentable) {
            self.representable = representable
        }
        
        public func layoutDidUpdate(_ view: PrototypeStatusView) {
            DispatchQueue.main.async {
                self.representable.height = view.statusView.frame.height
            }
        }
        
    }
    
}

extension PrototypeStatusViewRepresentable {
 
    public enum Style: Hashable, CaseIterable {
        case timeline
        case thread
    }
    
}
