//
//  ViewHeightKey.swift
//  
//
//  Created by MainasuK on 2023/2/9.
//

import UIKit
import SwiftUI

struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = value + nextValue()
    }
}
