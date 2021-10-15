//
//  CoverFlowStackCollectionViewLayout.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-14.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit

final public class CoverFlowStackCollectionViewLayout: UICollectionViewFlowLayout {
    
    public var startTrailingMarginRatio: CGFloat = 0.1
    public var endTrailingMarginRatio: CGFloat = 0.2
    public var stackVerticalMarginRatio: CGFloat = 0.08
    
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
    
    public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let attributes = super.layoutAttributesForElements(in: rect)
        guard let collectionView = self.collectionView else { return attributes }
    
        let viewPortRect = CGRect(
            origin: collectionView.contentOffset,
            size: collectionView.bounds.size
        )
        
        // let directionVector: CGFloat = collectionView.traitCollection.layoutDirection == .rightToLeft ? -1 : 1
        
        // precondition:
        // - the item size is the same width as collection view canvas
        for attribute in attributes ?? [] {
            
            if let attribute = attribute as? CoverFlowStackLayoutAttributes {
                attribute.originalFrame = attribute.frame
            }
            
            // set zIndex
            attribute.zIndex = Int.max - attribute.indexPath.row
            
            // set frame width (interpolation with easeInOut)
            let offset = viewPortRect.maxX - attribute.frame.minX
            let progress = offset / viewPortRect.width
            let trailingMarginRatio: CGFloat = {
                let start = startTrailingMarginRatio
                let end = endTrailingMarginRatio
                let t = easeInOutInterpolation(progress: progress)
                return lerp(v0: start, v1: end, t: t)
            }()
            attribute.frame.size.width *= 1 - trailingMarginRatio
            
            // set frame height (linear)
            let verticalMarginRatio: CGFloat = {
                let start = stackVerticalMarginRatio
                let end: CGFloat = 0
                return lerp(v0: start, v1: end, t: progress)
            }()
            let topVerticalMargin = attribute.frame.height * verticalMarginRatio / 2
            attribute.frame.size.height *= 1 - verticalMarginRatio
            attribute.frame.origin.y = topVerticalMargin
            
            // set 
            if attribute.frame.minX > viewPortRect.minX {
                // align next item leading edge to viewPort leading
                attribute.frame.origin.x = viewPortRect.origin.x
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
