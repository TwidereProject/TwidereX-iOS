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
    }
    
    public func makeUIView(context: Context) -> MetaLabel {
        let label = MetaLabel(style: textStyle)
        label.textArea.textContainer.lineBreakMode = .byTruncatingTail
        label.textArea.textContainer.maximumNumberOfLines = 1
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        label.setContentHuggingPriority(.defaultHigh, for: .vertical)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        setupLabel(label)
        label.configure(content: metaContent)
        return label
    }
    
    public func updateUIView(_ label: MetaLabel, context: Context) {
        label.configure(content: metaContent)
    }
}
