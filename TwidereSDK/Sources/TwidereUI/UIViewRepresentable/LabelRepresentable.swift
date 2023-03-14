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

public struct LabelRepresentable: UIViewRepresentable {
    
    let label: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.backgroundColor = .clear
        label.adjustsFontSizeToFitWidth = false
        label.allowsDefaultTighteningForTruncation = false
        label.lineBreakMode = .byTruncatingTail
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)     // always try grow vertical
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()
    
    // input
    public let metaContent: MetaContent
    public let textStyle: TextStyle
    let setupLabel: (UILabel) -> Void
    
    public init(
        metaContent: MetaContent,
        textStyle: TextStyle,
        setupLabel: @escaping (UILabel) -> Void
    ) {
        self.metaContent = metaContent
        self.textStyle = textStyle
        self.setupLabel = setupLabel
    }
    
    public func makeUIView(context: Context) -> UILabel {
        let label = self.label
        setupLabel(label)
        
        let attributedString = NSMutableAttributedString(string: metaContent.string)
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: textStyle.font,
            .foregroundColor: textStyle.textColor,
        ]
        let linkAttributes: [NSAttributedString.Key: Any] = [
            .font: textStyle.font,
            .foregroundColor: UIColor.tintColor,
        ]
        let paragraphStyle: NSMutableParagraphStyle = {
            let style = NSMutableParagraphStyle()
            let fontMargin = textStyle.font.lineHeight - textStyle.font.pointSize
            style.lineSpacing = 3 - fontMargin
            style.paragraphSpacing = 8 - fontMargin
            return style
        }()
        
        MetaText.setAttributes(
            for: attributedString,
            textAttributes: textAttributes,
            linkAttributes: linkAttributes,
            paragraphStyle: paragraphStyle,
            content: metaContent
        )
        
        label.attributedText = attributedString
        
        return label
    }
    
    public func updateUIView(_ view: UILabel, context: Context) {
        
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
