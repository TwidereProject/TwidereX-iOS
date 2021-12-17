//
//  PlaintextMetaContent.swift
//  PlaintextMetaContent
//
//  Created by Cirno MainasuK on 2021-8-19.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import Meta

public struct PlaintextMetaContent: MetaContent {
    public let string: String
    public let entities: [Meta.Entity] = []
    
    public init(string: String) {
        self.string = string
    }
    
    public func metaAttachment(for entity: Meta.Entity) -> MetaAttachment? {
        return nil
    }
}
