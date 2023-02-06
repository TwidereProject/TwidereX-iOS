//
//  TextViewRepresentable.swift
//  
//
//  Created by MainasuK on 2023/2/3.
//

import UIKit
import SwiftUI
import TwidereCore
import MetaTextKit

public struct TextViewRepresentable: UIViewRepresentable {
    
    let textView: UITextView = {
        let textView = UITextView()
        textView.backgroundColor = .clear
        textView.isScrollEnabled = false
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        return textView
    }()
    
    // input
    public let metaContent: MetaContent
    public let textStyle: TextStyle
    let width: CGFloat
    
    public init(
        metaContent: MetaContent,
        textStyle: TextStyle,
        width: CGFloat
    ) {
        self.metaContent = metaContent
        self.textStyle = textStyle
        self.width = width
    }
    
    public func makeUIView(context: Context) -> UITextView {
        let textView = self.textView
        
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
            style.lineSpacing = 5
            style.paragraphSpacing = 8
            return style
        }()
        
        MetaText.setAttributes(
            for: attributedString,
            textAttributes: textAttributes,
            linkAttributes: linkAttributes,
            paragraphStyle: paragraphStyle,
            content: metaContent
        )
        
        textView.frame.size.width = width
        textView.textStorage.setAttributedString(attributedString)
        textView.invalidateIntrinsicContentSize()
        
        return textView
    }
    
    public func updateUIView(_ view: UITextView, context: Context) {
        
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public class Coordinator: NSObject, UITextViewDelegate {
        let view: TextViewRepresentable

        init(_ view: TextViewRepresentable) {
            self.view = view
            super.init()
        }
    }
}
