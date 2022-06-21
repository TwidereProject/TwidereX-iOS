//
//  GaugeProgressStyle.swift
//  
//
//  Created by MainasuK on 2022-5-20.
//

import SwiftUI

// Ref:
// https://www.hackingwithswift.com/quick-start/swiftui/customizing-progressview-with-progressviewstyle
struct GaugeProgressStyle: ProgressViewStyle {
    
    var strokeColor = Color.blue
    var strokeWidth = 25.0

    func makeBody(configuration: Configuration) -> some View {
        let fractionCompleted = configuration.fractionCompleted ?? 0

        return ZStack {
            Circle()
                .stroke(Color(uiColor: .systemGray3), style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
            Circle()
                .trim(from: 0, to: fractionCompleted)
                .stroke(strokeColor, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

#if DEBUG
struct GaugeProgressStyle_Preview: PreviewProvider {

    static var previews: some View {
        ProgressView(value: 0.2, total: 1.0)
            .progressViewStyle(GaugeProgressStyle())
            .frame(width: 200, height: 200)
            .contentShape(Rectangle())
    }
    
}
#endif
