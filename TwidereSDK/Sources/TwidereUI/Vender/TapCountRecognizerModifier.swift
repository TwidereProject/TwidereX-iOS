//
//  TapCountRecognizerModifier.swift
//  
//
//  Created by MainasuK on 2022-7-28.
//

import UIKit
import SwiftUI

// ref:
// https://stackoverflow.com/questions/65062833/handling-both-double-and-triple-gesture-recognisers-in-swiftui/66979241#66979241

public struct TapCountRecognizerModifier: ViewModifier {
    
    let tapSensitivity: Int
    let singleTapAction: (() -> Void)?
    let doubleTapAction: (() -> Void)?
    let tripleTapAction: (() -> Void)?
    
    
    public init(tapSensitivity: Int = 250, singleTapAction: (() -> Void)? = nil, doubleTapAction: (() -> Void)? = nil, tripleTapAction: (() -> Void)? = nil) {
        
        self.tapSensitivity  = ((tapSensitivity >= 0) ? tapSensitivity : 250)
        self.singleTapAction = singleTapAction
        self.doubleTapAction = doubleTapAction
        self.tripleTapAction = tripleTapAction
        
    }
    
    @State private var tapCount: Int = Int()
    @State private var currentDispatchTimeID: DispatchTime = DispatchTime.now()
    
    public func body(content: Content) -> some View {

        return content
            .gesture(fundamentalGesture)
        
    }
    
    var fundamentalGesture: some Gesture {
        
        DragGesture(minimumDistance: 0.0, coordinateSpace: .local)
            .onEnded() { _ in tapCount += 1; tapAnalyzerFunction() }
        
    }
    
    
    
    func tapAnalyzerFunction() {
        
        currentDispatchTimeID = dispatchTimeIdGenerator(deadline: tapSensitivity)
        
        if tapCount == 1 {
            
            let singleTapGestureDispatchTimeID: DispatchTime = currentDispatchTimeID
            
            DispatchQueue.main.asyncAfter(deadline: singleTapGestureDispatchTimeID) {

                if (singleTapGestureDispatchTimeID == currentDispatchTimeID) {

                    if let unwrappedSingleTapAction: () -> Void = singleTapAction { unwrappedSingleTapAction() }

                    tapCount = 0
                    
                }
                
            }
            
        }
        else if tapCount == 2 {
            
            let doubleTapGestureDispatchTimeID: DispatchTime = currentDispatchTimeID
            
            DispatchQueue.main.asyncAfter(deadline: doubleTapGestureDispatchTimeID) {
                
                if (doubleTapGestureDispatchTimeID == currentDispatchTimeID) {
 
                    if let unwrappedDoubleTapAction: () -> Void = doubleTapAction { unwrappedDoubleTapAction() }
                    
                    tapCount = 0
                    
                }
                
            }
            
        }
        else  {
            
            
            if let unwrappedTripleTapAction: () -> Void = tripleTapAction { unwrappedTripleTapAction() }
            
            tapCount = 0
            
        }
        
    }
    
    func dispatchTimeIdGenerator(deadline: Int) -> DispatchTime { return DispatchTime.now() + DispatchTimeInterval.milliseconds(deadline) }
    
}

extension View {
    
    public func tapCountRecognizer(tapSensitivity: Int = 250, singleTapAction: (() -> Void)? = nil, doubleTapAction: (() -> Void)? = nil, tripleTapAction: (() -> Void)? = nil) -> some View {
        
        return self.modifier(TapCountRecognizerModifier(tapSensitivity: tapSensitivity, singleTapAction: singleTapAction, doubleTapAction: doubleTapAction, tripleTapAction: tripleTapAction))
        
    }
    
}
