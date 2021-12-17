//
//  ReadabilityPadding.swift
//  ReadabilityPadding
//
//  Created by Cirno MainasuK on 2021-8-11.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import SwiftUI

/// https://stackoverflow.com/a/68478487/3797903
struct ReadabilityPadding: ViewModifier {
    let isEnabled: Bool
    @ScaledMetric private var unit: CGFloat = 20
    
    func body(content: Content) -> some View {
        GeometryReader { geometryProxy in
            content
                .padding(.horizontal, padding(for: geometryProxy.size.width))
        }
    }
    
    private func padding(for width: CGFloat) -> CGFloat {
        guard isEnabled else { return 0 }
        
        // The internet seems to think the optimal readable width is 50-75
        // characters wide; I chose 70 here. The `unit` variable is the
        // approximate size of the system font and is wrapped in
        // @ScaledMetric to better support dynamic type. I assume that
        // the average character width is half of the size of the font.
        let deviceWidth = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        let idealWidth = min(70 * unit / 2, deviceWidth - 16 * 2)
        
        // If the width is already readable then don't apply any padding.
        guard width >= idealWidth else {
            return 0
        }
        
        // If the width is too large then calculate the padding required
        // on either side until the view's width is readable.
        let padding = round((width - idealWidth) / 2)
        return padding
    }
}
