//
//  LabelRepresentable.swift
//  
//
//  Created by MainasuK on 2023/2/6.
//

import UIKit
import SwiftUI
import TwidereCore
import MetaTextKit
import MetaLabel

public struct LabelRepresentable: UIViewRepresentable {
    
    let label: MetaLabel
    
    // input
    let metaContent: MetaContent
    let textStyle: TextStyle
    let setupLabel: (MetaLabel) -> Void
    
    public init(
        metaContent: MetaContent,
        textStyle: TextStyle,
        setupLabel: @escaping (MetaLabel) -> Void
    ) {
        self.metaContent = metaContent
        self.textStyle = textStyle
        self.setupLabel = setupLabel
        self.label = {
            let label = MetaLabel(style: textStyle)
            label.textArea.textContainer.lineBreakMode = .byTruncatingTail
            label.setContentHuggingPriority(.defaultHigh, for: .horizontal)     // always try grow vertical
            label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            return label
        }()
    }
    
    public func makeUIView(context: Context) -> UIView {
        setupLabel(label)
        label.configure(content: metaContent)
        return label
    }
    
    public func updateUIView(_ view: UIView, context: Context) {
        // do nothing
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public class Coordinator: NSObject, UITextViewDelegate {
        let view: LabelRepresentable

        init(_ view: LabelRepresentable) {
            self.view = view
            super.init()
        }
    }
}
