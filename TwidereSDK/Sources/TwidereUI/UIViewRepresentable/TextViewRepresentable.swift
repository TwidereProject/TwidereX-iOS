//
//  TextViewRepresentable.swift
//  
//
//  Created by MainasuK on 2023/2/3.
//

import os.log
import UIKit
import SwiftUI
import TwidereCore
import MetaTextKit
import MetaTextArea

public struct TextViewRepresentable: UIViewRepresentable {
    // let logger = Logger(subsystem: "TextViewRepresentable", category: "View")
    let logger = Logger(.disabled)
    
    // input
    let metaContent: MetaContent
    let textStyle: TextStyle
    let width: CGFloat
    let isSelectable: Bool
    let handler: (Meta) -> Void
    
    // output
    let attributedString: NSAttributedString
    
    public init(
        metaContent: MetaContent,
        textStyle: TextStyle,
        width: CGFloat,
        isSelectable: Bool,
        handler: @escaping (Meta) -> Void
    ) {
        self.metaContent = metaContent
        self.textStyle = textStyle
        self.width = width
        self.isSelectable = isSelectable
        self.handler = handler
        self.attributedString = {
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
            
            return attributedString
        }()
    }
    
    public func makeUIView(context: Context) -> UITextView {
        let textView: WrappedTextView = {
            let textView = WrappedTextView()
            textView.backgroundColor = .clear
            textView.isScrollEnabled = false
            textView.isEditable = false
            textView.isSelectable = false
            textView.textContainerInset = .zero
            textView.textContainer.lineFragmentPadding = 0
            textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            textView.setContentHuggingPriority(.defaultHigh, for: .vertical)
            return textView
        }()
        textView.isSelectable = isSelectable
        textView.delegate = context.coordinator
        textView.textViewDelegate = context.coordinator
        textView.frame.size.width = width
        textView.textStorage.setAttributedString(attributedString)
        textView.invalidateIntrinsicContentSize()
        textView.setNeedsLayout()
        textView.layoutIfNeeded()
        return textView
    }
    
    public func updateUIView(_ view: UITextView, context: Context) {
        let textView = view
        
        var needsLayout = false
        
        if textView.frame.size.width != width {
            textView.frame.size.width = width
            needsLayout = true
        }
        if textView.attributedText.string != attributedString.string {
            textView.textStorage.setAttributedString(attributedString)
            needsLayout = true
            
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): update textView \(view.hashValue): \(metaContent.string)")
        } else {
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): reuse textView content")
        }
        
        if needsLayout {
            textView.invalidateIntrinsicContentSize()
            textView.setNeedsLayout()
            textView.layoutIfNeeded()
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public class Coordinator: NSObject {
        let logger = Logger(subsystem: "TextViewRepresentable", category: "Coordinator")
        
        let view: TextViewRepresentable

        init(_ view: TextViewRepresentable) {
            self.view = view
            super.init()
        }
    }
}

// MARK: - UITextViewDelegate
extension TextViewRepresentable.Coordinator: UITextViewDelegate {
    public func textView(_ textView: UITextView, shouldInteractWith textAttachment: NSTextAttachment, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        return false
    }
    
    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        return false
    }
}

// MARK: - WrappedTextViewDelegate
extension TextViewRepresentable.Coordinator: WrappedTextViewDelegate {
    public func wrappedTextView(_ wrappedTextView: WrappedTextView, didSelectMeta meta: Meta) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): meta: \(meta.debugDescription)")
        view.handler(meta)
    }
}

public protocol WrappedTextViewDelegate: AnyObject {
    func wrappedTextView(_ wrappedTextView: WrappedTextView, didSelectMeta meta: Meta)
}

public class WrappedTextView: UITextView {
    
    let logger = Logger(subsystem: "WrappedTextView", category: "View")
    
    let tapGestureRecognizer = UITapGestureRecognizer()
    
    private var lastWidth: CGFloat = 0
    
    public weak var textViewDelegate: WrappedTextViewDelegate?
    
    public override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        // end init
        
        addGestureRecognizer(tapGestureRecognizer)
        tapGestureRecognizer.addTarget(self, action: #selector(WrappedTextView.tapGestureRecognizerHandler(_:)))
        tapGestureRecognizer.delaysTouchesBegan = false
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()

        if bounds.width != lastWidth {
            lastWidth = bounds.width
            invalidateIntrinsicContentSize()
        }
    }

    public override var intrinsicContentSize: CGSize {
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

extension WrappedTextView {
    @objc private func tapGestureRecognizerHandler(_ sender: UITapGestureRecognizer) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        switch sender.state {
        case .ended:
            let point = sender.location(in: self)
            guard let meta = meta(at: point) else { return }
            textViewDelegate?.wrappedTextView(self, didSelectMeta: meta)
        default:
            break
        }
    }
}

extension WrappedTextView {
    
    public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return meta(at: point) != nil || isSelectable
    }
    
    func meta(at point: CGPoint) -> Meta? {
        guard let fragment = textLayoutManager?.textLayoutFragment(for: point) else { return nil }

        let pointInFragmentFrame = CGPoint(
            x: point.x - fragment.layoutFragmentFrame.origin.x,
            y: point.y - fragment.layoutFragmentFrame.origin.y
        )
        let lines = fragment.textLineFragments
        guard let lineIndex = lines.firstIndex(where: { $0.typographicBounds.contains(pointInFragmentFrame) }) else { return nil }
        guard lineIndex < lines.count else { return nil }
        let line = lines[lineIndex]

        let characterIndex = line.characterIndex(for: point)
        guard characterIndex >= 0, characterIndex < line.attributedString.length else { return nil }

        guard let meta = line.attributedString.attribute(.meta, at: characterIndex, effectiveRange: nil) as? Meta else {
            return nil
        }
        return meta
    }
    
}
