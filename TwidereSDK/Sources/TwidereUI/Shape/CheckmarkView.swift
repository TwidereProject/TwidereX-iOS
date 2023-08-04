//
//  CheckmarkView.swift
//  
//
//  Created by MainasuK on 2023/3/21.
//

import Foundation
import SwiftUI

public struct CheckmarkView: View {
    
    public let tintColor: UIColor
    public let borderWidth: CGFloat
    public let cornerRadius: CGFloat
    public let check: Bool
    
    
    public var body: some View {
        ZStack {
            Color(uiColor: tintColor)
            if check {
                CheckmarkShape()
                    .blendMode(.destinationOut)
            } else {
                Color(uiColor: tintColor)
                    .cornerRadius(cornerRadius - borderWidth)
                    .padding(borderWidth)
                    .blendMode(.destinationOut)
            }
        }
        .compositingGroup()
        .cornerRadius(cornerRadius)
    }
}

struct CheckmarkShape: Shape {

    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        let radius = width / 20
        
        var path = Path()
        let cos45 = cos(45.0 * CGFloat.pi / 180.0)
        let sin45 = cos(45.0 * CGFloat.pi / 180.0)
        let root2 = 2.squareRoot()
        path.addArc(center: CGPoint(x: 9/20 * width, y: 12/20 * height), radius: radius, startAngle: Angle(degrees: 45), endAngle: Angle(degrees: 135), clockwise: false)
        path.addLine(to: CGPoint(x: 7/20 * width - cos45 * radius, y: 10/20 * height + sin45 * radius))
        path.addArc(center: CGPoint(x: 7/20 * width, y: 10/20 * height), radius: radius, startAngle: Angle(degrees: 135), endAngle: Angle(degrees: 315), clockwise: false)
        path.addLine(to: CGPoint(x: 9/20 * width, y: 12/20 * height - root2 * radius))
        path.addArc(center: CGPoint(x: 13/20 * width, y: 8/20 * height), radius: radius, startAngle: Angle(degrees: 225), endAngle: Angle(degrees: 405), clockwise: false)
        path.closeSubpath()
        return path
    }
}


#if DEBUG
import SwiftUI
struct CheckmarkView_Preview: PreviewProvider {
    
    static var width: CGFloat = 100
    
    static var previews: some View {
        CheckmarkView(
            tintColor: .systemBlue,
            borderWidth: width / 18,
            cornerRadius: width / 4,
            check: true
        )
        .previewLayout(.fixed(width: width, height: width))
        CheckmarkView(
            tintColor: .systemBlue,
            borderWidth: width / 18,
            cornerRadius: width / 4,
            check: false
        )
        .previewLayout(.fixed(width: width, height: width))
    }
}
#endif
