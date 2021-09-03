//
//  MetaTextAreaView.swift
//  MetaTextAreaView
//
//  Created by Cirno MainasuK on 2021-7-30.
//

import os.log
import UIKit
import Combine

public protocol MetaTextAreaViewDelegate: AnyObject {
    func metaTextAreaView(_ view: MetaTextAreaView, intrinsicContentSizeDidUpdate size: CGSize)
}

public class MetaTextAreaView: UIView {
    
    // let logger = Logger(subsystem: "MetaTextAreaView", category: "Layout")
    let logger = Logger(OSLog.disabled)
    
    public let textContentStorage = NSTextContentStorage()
    public let textLayoutManager = NSTextLayoutManager()
    public let textContainer = NSTextContainer()
    
    public var paragraphStyle: NSMutableParagraphStyle = {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 5
        style.paragraphSpacing = 8
        return style
    }()
    
    static var fontSize: CGFloat = 17
    
    public var textAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: MetaTextAreaView.fontSize, weight: .regular)),
        .foregroundColor: UIColor.label,
    ]
    
    public var linkAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: MetaTextAreaView.fontSize, weight: .semibold)),
        .foregroundColor: UIColor.link,
    ]
    
    private let attachmentView = UIView()
    private let contentLayer = MetaTextAreaLayer()
    private let fragmentLayerMap = NSMapTable<NSTextLayoutFragment, CALayer>.weakToWeakObjects()
    
    // private let underlyingQueue = DispatchQueue(label: "MetaTextAreaView.underlyingQueue", qos: .userInteractive)
    // private lazy var layoutQueue: OperationQueue = {
    //     let queue = OperationQueue()
    //     queue.name = "MetaTextAreaView.layoutQueue"
    //     queue.underlyingQueue = underlyingQueue
    //     return queue
    // }()
    
    #if DEBUG
    public var showLayerFrames: Bool = true
    #endif
    
    public var preferredMaxLayoutWidth: CGFloat?
    public weak var delegate: MetaTextAreaViewDelegate?
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func _init() {
        attachmentView.frame = bounds
        addSubview(attachmentView)
        layer.addSublayer(contentLayer)
        
        textContentStorage.addTextLayoutManager(textLayoutManager)
        textLayoutManager.textContainer = textContainer
    
        textContainer.lineFragmentPadding = 0
        
        // DEBUG
        // showLayerFrames = true
        
        textLayoutManager.delegate = self                               ///< NSTextLayoutManagerDelegate
        textLayoutManager.textViewportLayoutController.delegate = self  ///< NSTextViewportLayoutControllerDelegate
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        invalidateIntrinsicContentSize()
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): bounds \(self.bounds.debugDescription)")
    }

    
    public override var intrinsicContentSize: CGSize {
        let width: CGFloat = {
            if bounds.width == .zero {
                return preferredMaxLayoutWidth ?? UIScreen.main.bounds.width
            } else {
                return bounds.width
            }
        }()
        let size = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        let _intrinsicContentSize = sizeThatFits(size)
        return _intrinsicContentSize
    }
    
    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        // update textContainer width
        textContainer.size.width = size.width
        
        // needs always draw to fit tableView/collectionView cell reusing
        // also, make precise height calculate possible
        textLayoutManager.textViewportLayoutController.layoutViewport()
        
        // calculate height
        var height: CGFloat = 0
        textLayoutManager.enumerateTextLayoutFragments(
            from: textLayoutManager.documentRange.endLocation,
            options: [.reverse, .ensuresLayout]
        ) { layoutFragment in
            height = layoutFragment.layoutFragmentFrame.maxY
            return false // stop
        }
        
        var newSize = size
        newSize.height = ceil(height)
        
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): \(newSize.debugDescription)")
        
        return newSize
    }
    
    deinit {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
    }
    
}

extension MetaTextAreaView {
    public func setAttributedString(_ attributedString: NSAttributedString) {
        textContentStorage.textStorage?.setAttributedString(attributedString)
        invalidateIntrinsicContentSize()
    }
}

extension MetaTextAreaView {
    
    private func resetContent() {
        attachmentView.subviews.forEach { view in view.removeFromSuperview() }
        contentLayer.sublayers?.forEach { layer in layer.removeFromSuperlayer() }
        contentLayer.sublayers = nil
    }
}

// MARK: - NSTextViewportLayoutControllerDelegate
extension MetaTextAreaView: NSTextViewportLayoutControllerDelegate {
    
    public func viewportBounds(for textViewportLayoutController: NSTextViewportLayoutController) -> CGRect {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): return viewportBounds: \(self.bounds.debugDescription)")
        return CGRect(
            origin: .zero,
            size: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        )
    }
    
    public func textViewportLayoutControllerWillLayout(_ textViewportLayoutController: NSTextViewportLayoutController) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        
        resetContent()
    }
    
    private func findOrCreateLayer(_ textLayoutFragment: NSTextLayoutFragment) -> (MetaTextLayoutFragmentLayer, Bool) {
        if let layer = fragmentLayerMap.object(forKey: textLayoutFragment) as? MetaTextLayoutFragmentLayer {
            return (layer, false)
        } else {
            let layer = MetaTextLayoutFragmentLayer(textLayoutFragment: textLayoutFragment)
            layer.contentView = attachmentView
            fragmentLayerMap.setObject(layer, forKey: textLayoutFragment)
            return (layer, true)
        }
    }
    
    public func textViewportLayoutController(
        _ textViewportLayoutController: NSTextViewportLayoutController,
        configureRenderingSurfaceFor textLayoutFragment: NSTextLayoutFragment
    ) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): textLayoutFragment \(textLayoutFragment)")
        
        let (textLayoutFragmentLayer, isCreate) = findOrCreateLayer(textLayoutFragment)
        contentLayer.addSublayer(textLayoutFragmentLayer)

        if !isCreate {
            let oldBounds = textLayoutFragmentLayer.bounds
            textLayoutFragmentLayer.updateGeometry()
            if oldBounds != textLayoutFragmentLayer.bounds {
                textLayoutFragmentLayer.setNeedsDisplay()
            }
        }
        
        #if DEBUG
        if textLayoutFragmentLayer.showLayerFrames != showLayerFrames {
            textLayoutFragmentLayer.showLayerFrames = showLayerFrames
            textLayoutFragmentLayer.setNeedsDisplay()
        }
        #endif
        
        
//        for textLineFragment in textLayoutFragment.textLineFragments {
//            let range = NSRange(location: 0, length: textLineFragment.attributedString.length)
//            let textLineFragmentTypographicBounds = textLineFragment.typographicBounds
//            textLineFragment.attributedString.enumerateAttribute(.attachment, in: range, options: [.reverse]) { attachment, range, _ in
//                guard let attachment = attachment as? MetaAttachment else { return }
//
//                let attachmentFrameMinLocation = textLineFragment.locationForCharacter(at: range.lowerBound)
//                let attachmentFrameMaxLocation = textLineFragment.locationForCharacter(at: range.upperBound)
//                let rect = CGRect(
//                    x: attachmentFrameMinLocation.x,
//                    y: textLineFragmentTypographicBounds.minY + textLayoutFragmentLayer.frame.minY,
//                    width: attachmentFrameMaxLocation.x - attachmentFrameMinLocation.x,
//                    height: textLineFragmentTypographicBounds.height
//                )
//
//                attachment.content.frame = rect
//                if attachment.content.superview == nil {
//                    self.addSubview(attachment.content)
//                }
//            }
//        }
    }
    
    public func textViewportLayoutControllerDidLayout(_ textViewportLayoutController: NSTextViewportLayoutController) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
    }
    
}

// MARK: - NSTextLayoutManagerDelegate
extension MetaTextAreaView: NSTextLayoutManagerDelegate {
//    public func textLayoutManager(_ textLayoutManager: NSTextLayoutManager, textLayoutFragmentFor location: NSTextLocation, in textElement: NSTextElement) -> NSTextLayoutFragment {
//        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): location: \(location.debugDescription ?? ""), element: \(textElement.debugDescription)")
//        
//        let documentRangeLocation = textLayoutManager.documentRange.location
//        if let elementRangeLocation = textElement.elementRange?.location,
//           elementRangeLocation.compare(documentRangeLocation) == .orderedSame {
//            return NSTextLayoutFragment(textElement: textElement, range: textElement.elementRange)
//        } else {
//            return MetaParagraphTextLayoutFragment(textElement: textElement, range: textElement.elementRange)
//        }
//    }
}
