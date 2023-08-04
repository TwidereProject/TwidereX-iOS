//
//  WrapperViewRepresentable.swift
//  
//
//  Created by MainasuK on 2023/3/17.
//

import UIKit
import SwiftUI
import TwidereCore

public struct WrapperViewRepresentable: UIViewRepresentable {
    
    public let view: UIView
    
    public func makeUIView(context: Context) -> UIView {
        return view
    }
    
    public func updateUIView(_ view: UIView, context: Context) {
        // do nothing
    }
    
}
