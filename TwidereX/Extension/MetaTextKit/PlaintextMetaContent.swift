//
//  PlaintextMetaContent.swift
//  PlaintextMetaContent
//
//  Created by Cirno MainasuK on 2021-8-19.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import Meta

struct PlaintextMetaContent: MetaContent {
    let string: String
    let entities: [Meta.Entity] = []
    
    init(string: String) {
        self.string = string
    }
    
    func metaAttachment(for entity: Meta.Entity) -> MetaAttachment? {
        return nil
    }
}
