//
//  ReplyStatusViewPresentable.swift
//  
//
//  Created by MainasuK on 2022-5-18.
//

import UIKit
import SwiftUI
import TwidereCore

public struct ReplyStatusViewRepresentable: UIViewRepresentable {
        
    let statusObject: StatusObject
    let configurationContext: StatusView.ConfigurationContext
    let width: CGFloat
    
    public func makeUIView(context: Context) -> ReplyStatusView {
        let view = ReplyStatusView()
        // using view `intrinsicContentSize` for layout
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }
    
    public func updateUIView(_ view: ReplyStatusView, context: Context) {
        if width != .zero {
            view.statusView.frame.size.width = width
            view.widthLayoutConstraint.constant = width
            view.widthLayoutConstraint.isActive = true
        }
        
        view.statusView.prepareForReuse()
        view.statusView.configure(
            statusObject: statusObject,
            configurationContext: configurationContext
        )
    }
    
}
