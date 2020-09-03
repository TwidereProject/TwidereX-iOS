//
//  DocumentStore.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-8-10.
//  Copyright © 2020 Dimension. All rights reserved.
//

import UIKit
import Combine

class DocumentStore: ObservableObject {
    let qrCodeCache = NSCache<NSString, UIImage>()
    let avatarCache = NSCache<NSString, UIImage>()
}

extension DocumentStore {
    
}
