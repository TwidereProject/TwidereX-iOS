//
//  TouchBlockingViewRepresentable.swift
//  
//
//  Created by MainasuK on 2023/3/22.
//

import SwiftUI

public struct TouchBlockingViewRepresentable: UIViewRepresentable {
    
    public func makeUIView(context: Context) -> TouchBlockingView {
        let view = TouchBlockingView()
        return view
    }
    
    public func updateUIView(_ view: TouchBlockingView, context: Context) {
        // do nothing
    }
    
}
