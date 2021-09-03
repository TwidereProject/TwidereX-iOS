//
//  MetaTextAreaView+MetaContent.swift
//  MetaTextAreaView+MetaContent
//
//  Created by Cirno MainasuK on 2021-9-3.
//

import Foundation
import Meta
import MetaTextKit

extension  MetaTextAreaView {
    
    public func configure(content: MetaContent) {
        let attributedString = NSMutableAttributedString(string: content.string)
        
        MetaText.setAttributes(
            for: attributedString,
               textAttributes: textAttributes,
               linkAttributes: linkAttributes,
               paragraphStyle: paragraphStyle,
               content: content
        )
        
        setAttributedString(attributedString)
    }
    
    public func reset() {
        let attributedString = NSAttributedString(string: "")
        setAttributedString(attributedString)
    }
    
}
