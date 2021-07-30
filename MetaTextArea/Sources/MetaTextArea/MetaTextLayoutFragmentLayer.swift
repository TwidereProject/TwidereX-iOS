//
//  MetaTextLayoutFragmentLayer.swift
//  MetaTextLayoutFragmentLayer
//
//  Created by Cirno MainasuK on 2021-7-30.
//

import UIKit
import CoreGraphics

class MetaTextLayoutFragmentLayer: CALayer {
    
    var textLayoutFragment: NSTextLayoutFragment?
    
    #if DEBUG
    var showLayerFrames: Bool = false
    static let renderingSurfaceBoundsStrokeColor: UIColor = .systemOrange
    static let typographicBoundsStrokeColor: UIColor = .systemPurple
    static let lineTypographicBoundsStrokeColor: UIColor = .systemCyan
    #endif
    
    override class func defaultAction(forKey event: String) -> CAAction? {
        // Suppress default opacity animations.
        return NSNull()
    }
    
    init(textLayoutFragment: NSTextLayoutFragment) {
        self.textLayoutFragment = textLayoutFragment
        super.init()
        contentsScale = UIScreen.main.scale
        updateGeometry()
        setNeedsDisplay()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(in ctx: CGContext) {
        guard let textLayoutFragment = textLayoutFragment else { return }
        
        textLayoutFragment.draw(at: .zero, in: ctx)
        
        #if DEBUG
        if showLayerFrames {
            // draw surface bounds
            let strokeWidth: CGFloat = 2
            let inset = 0.5 * strokeWidth
            ctx.setLineWidth(strokeWidth)
            ctx.setStrokeColor(MetaTextLayoutFragmentLayer.renderingSurfaceBoundsStrokeColor.cgColor)
            ctx.setLineDash(phase: 0, lengths: [])  // sold line.
            ctx.stroke(textLayoutFragment.renderingSurfaceBounds.insetBy(dx: inset, dy: inset))
            
            // draw typographic bounds
            ctx.setStrokeColor(MetaTextLayoutFragmentLayer.typographicBoundsStrokeColor.cgColor)
            ctx.setLineDash(phase: 0, lengths: [strokeWidth, strokeWidth]) // square dashes.
            var typographicBounds = textLayoutFragment.layoutFragmentFrame
            typographicBounds.origin = .zero
            ctx.stroke(typographicBounds.insetBy(dx: inset, dy: inset))
            
            // draw bounds for lines
            for textLineFragment in textLayoutFragment.textLineFragments {
                // draw typographic bounds for line
                let lineTypographicBounds = textLineFragment.typographicBounds
                ctx.setStrokeColor(MetaTextLayoutFragmentLayer.lineTypographicBoundsStrokeColor.cgColor)
                ctx.setLineDash(phase: 0, lengths: [strokeWidth, strokeWidth]) // square dashes.
                ctx.stroke(lineTypographicBounds.insetBy(dx: inset, dy: inset))
                
                // draw character edge
                let characterRange = textLineFragment.characterRange
                guard let range = Range(characterRange) else { continue }
                for characterLocation in range {
                    let characterOrigin = textLineFragment.locationForCharacter(at: characterLocation)
                    ctx.saveGState()
                    let rect = CGRect(
                        x: characterOrigin.x,
                        y: lineTypographicBounds.minY,
                        width: 1,
                        height: lineTypographicBounds.height
                    )
                    let path = CGPath(rect: rect, transform: nil)
                    ctx.addPath(path)
                    ctx.setFillColor(UIColor.red.cgColor)
                    ctx.fillPath()
                    ctx.restoreGState()
                }
            }
        }
        #endif
    }
    
}

extension MetaTextLayoutFragmentLayer {
    func updateGeometry() {
        guard let textLayoutFragment = textLayoutFragment else { return }
        bounds = textLayoutFragment.renderingSurfaceBounds
        
        var typographicBounds = textLayoutFragment.layoutFragmentFrame
        typographicBounds.origin = .zero
        bounds = bounds.union(typographicBounds)
        
        // The (0, 0) point in layer space should be the anchor point.
        anchorPoint = CGPoint(x: -bounds.origin.x / bounds.size.width, y: -bounds.origin.y / bounds.size.height)
        position = textLayoutFragment.layoutFragmentFrame.origin
    }
}
