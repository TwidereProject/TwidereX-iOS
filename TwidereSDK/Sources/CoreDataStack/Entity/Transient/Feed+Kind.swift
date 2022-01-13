//
//  Feed+Kind.swift
//  Feed+Kind
//
//  Created by Cirno MainasuK on 2021-8-26.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation

extension Feed {
    public enum Kind: String, CaseIterable {
        case none
        case home
        case local
        case `public`
        case notification
    }
}
