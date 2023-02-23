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
    
    let textView: WrappedTextView = {
        let textView = WrappedTextView()
        textView.backgroundColor = .clear
        textView.isScrollEnabled = false
        textView.isEditable = false
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
            style.lineSpacing = 3
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
        textView.setNeedsLayout()
        textView.layoutIfNeeded()
        
        return textView
    }
    
    public func updateUIView(_ view: UITextView, context: Context) {
        textView.frame.size.width = width
        textView.invalidateIntrinsicContentSize()
        textView.setNeedsLayout()
        textView.layoutIfNeeded()
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

class WrappedTextView: UITextView {
    
    private var lastWidth: CGFloat = 0

    override func layoutSubviews() {
        super.layoutSubviews()

        if bounds.width != lastWidth {
            lastWidth = bounds.width
            invalidateIntrinsicContentSize()
        }
    }

    override var intrinsicContentSize: CGSize {
        let size = sizeThatFits(CGSize(
            width: lastWidth,
            height: UIView.layoutFittingExpandedSize.height
        ))
        return CGSize(
            width: lastWidth,
            height: size.height.rounded(.up)
        )
    }

}
