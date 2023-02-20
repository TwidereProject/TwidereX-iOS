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
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.setContentHuggingPriority(.defaultHigh, for: .vertical)
        return label
    }()
    
    // input
    public let metaContent: MetaContent
    public let textStyle: TextStyle
    
    public init(
        metaContent: MetaContent,
        textStyle: TextStyle
    ) {
        self.metaContent = metaContent
        self.textStyle = textStyle
    }
    
    public func makeUIView(context: Context) -> UILabel {
        let label = self.label
        
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
        label.invalidateIntrinsicContentSize()
        
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
