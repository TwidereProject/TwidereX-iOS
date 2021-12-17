//
//  CoverFlowStackCollectionViewLayout.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-14.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit

final public class CoverFlowStackCollectionViewLayout: UICollectionViewFlowLayout {

    public var sizeScaleRatio: CGFloat = 0.8
    public var trailingMarginRatio: CGFloat = 0.1
    
    override public func prepare() {
        super.prepare()
        
        scrollDirection = .horizontal
        minimumLineSpacing = 0
        minimumInteritemSpacing = 0
        
        collectionView?.showsHorizontalScrollIndicator = false
        collectionView?.showsVerticalScrollIndicator = false
        collectionView?.isPagingEnabled = true
        
        guard let collectionView = self.collectionView else { return }
        itemSize = collectionView.frame.size
    }
    
    override public func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
}

extension CoverFlowStackCollectionViewLayout {
    
    public override class var layoutAttributesClass: AnyClass {
        CoverFlowStackLayoutAttributes.self
    }
    
    public override var flipsHorizontallyInOppositeLayoutDirection: Bool {
        return true
    }
    
    public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let attributes = super.layoutAttributesForElements(in: rect)
        guard let collectionView = self.collectionView else { return attributes }
    
        let viewPortRect = CGRect(
            origin: collectionView.contentOffset,
            size: collectionView.bounds.size
        )
                
        // precondition:
        // - the item size is the same width as collection view canvas
        for attribute in attributes ?? [] {
            let originalFrame = attribute.frame
            if let attribute = attribute as? CoverFlowStackLayoutAttributes {
                attribute.originalFrame = originalFrame
            }
            
            // set zIndex
            attribute.zIndex = Int.max - attribute.indexPath.row
            
            // calculate constants
            let endFrameSize = CGSize(
                width: viewPortRect.width * (1 - trailingMarginRatio),
                height: viewPortRect.height
            )
            let startFrameSize = CGSize(
                width: endFrameSize.width * sizeScaleRatio,
                height: endFrameSize.height * sizeScaleRatio
            )
            
            attribute.alpha = 1

            if originalFrame.minX <= viewPortRect.minX {
                // A: top most cover
                // set frame
                attribute.frame.size.width = endFrameSize.width
                attribute.frame.size.height = endFrameSize.height
            } else if originalFrame.minX <= viewPortRect.maxX {
                // B: middle cover
                // timing curve
                let offset = viewPortRect.maxX - originalFrame.minX
                let t = offset / viewPortRect.width
                let timingCurve = easeInOutInterpolation(progress: t)
                // get current scale ratio
                let scaleRatio: CGFloat = {
                    let start = sizeScaleRatio
                    let end: CGFloat = 1
                    return lerp(v0: start, v1: end, t: timingCurve)
                }()
                // set height
                attribute.frame.size.height = endFrameSize.height * scaleRatio
                // pin offsetY
                let topMargin = (viewPortRect.height - attribute.frame.height) / 2
                attribute.frame.origin.y = topMargin
                // set width
                attribute.frame.size.width = endFrameSize.width * scaleRatio
                // set offsetX
                let end = viewPortRect.origin.x
                let start = viewPortRect.maxX - attribute.frame.width
                let minX = lerp(v0: start, v1: end, t: timingCurve)
                attribute.frame.origin.x = minX
                // set alpha
                attribute.alpha = lerp(v0: 0.5, v1: 1, t: timingCurve)
            } else {
                // C: bottom cover
                // timing curve
                let offset = originalFrame.minX - viewPortRect.maxX
                let t = 1 - (offset / viewPortRect.width)
                // set height
                attribute.frame.size.height = startFrameSize.height
                // pin offsetY
                let topMargin = (viewPortRect.height - attribute.frame.height) / 2
                attribute.frame.origin.y = topMargin
                // set width
                attribute.frame.size.width = startFrameSize.width
                // set offsetX
                attribute.frame.origin.x = viewPortRect.maxX - attribute.frame.width
                // set alpha
                attribute.alpha = lerp(v0: 0, v1: 0.5, t: t)
            }
        }   // end for
        
        return attributes
    }
}

// ref:
// - https://stackoverflow.com/questions/13462001/ease-in-and-ease-out-animation-formula
// - https://math.stackexchange.com/questions/121720/ease-in-out-function/121755#121755
// for a = 2
func easeInOutInterpolation(progress t: CGFloat) -> CGFloat {
    let sqt = t * t
    return sqt / (2.0 * (sqt - t) + 1.0)
}

// linear interpolation
func lerp(v0: CGFloat, v1: CGFloat, t: CGFloat) -> CGFloat {
    return (1 - t) * v0 + (t * v1)
}
