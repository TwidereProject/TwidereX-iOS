//
//  CoverFlowStackLayoutAttributes.swift
//  
//
//  Created by Cirno MainasuK on 2021-10-15.
//

import UIKit

public final class CoverFlowStackLayoutAttributes: UICollectionViewLayoutAttributes {
    
    public var originalFrame: CGRect = .zero
    
    public override func copy(with zone: NSZone? = nil) -> Any {
        let object = super.copy(with: zone)
        guard let attributes = object as? CoverFlowStackLayoutAttributes else { return object }
        attributes.originalFrame = originalFrame
        return attributes
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? CoverFlowStackLayoutAttributes else { return false }
        return super.isEqual(object) && originalFrame == object.originalFrame
    }
}
