//
//  SizeDimensionPreferenceKey.swift
//  
//
//  Created by MainasuK on 2023/4/10.
//

import SwiftUI

public struct SizeDimensionPreferenceKey: PreferenceKey {
    public static let defaultValue: CGFloat = 0

    public static func reduce(
        value: inout CGFloat,
        nextValue: () -> CGFloat
    ) {
        value = max(value, nextValue())
    }
}
