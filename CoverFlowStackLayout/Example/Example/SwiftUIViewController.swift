//
//  SwiftUIViewController.swift
//  Example
//
//  Created by MainasuK on 2023/4/17.
//

import UIKit
import SwiftUI
import CoverFlowStackScrollView

final class SwiftUIViewController: UIViewController {
    
}

extension SwiftUIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "SwiftUI"
        
        let hostingController = UIHostingController(rootView: ContentView())
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.willMove(toParent: self)
        view.addSubview(hostingController.view)
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
    
}

public struct ContentView: View {
    
    @StateObject var viewModel = ViewModel()
    
    public var body: some View {
        GeometryReader { root in
            let dimension = min(root.size.width, root.size.height)
            CoverFlowStackScrollView {
                HStack(spacing: .zero) {
                    ForEach(Array(viewModel.colors.enumerated()), id: \.0) { index, color in
                        GeometryReader { geo in
                            let transformAttribute = viewModel.transformAttribute(at: index)
                            ZStack {
                                VStack {
                                    Text("Number \(index)")
                                        .font(.largeTitle)
                                    Text("\(viewModel.frame(at: index).debugDescription)")
                                        .font(.caption)
                                }
                                .frame(
                                    width: transformAttribute.transformFrame.width,
                                    height: transformAttribute.transformFrame.height
                                )
                                .background(Color(uiColor: color))
                                .offset(
                                    x: transformAttribute.offsetX,
                                    y: transformAttribute.offsetY
                                )
                            }
                            .frame(width: dimension, height: dimension)
                        }
                        .frame(width: dimension, height: dimension)
                        .zIndex(Double(999 - index))
                    }
                }
            } contentOffsetDidUpdate: { contentOffset in
                viewModel.contentOffset = contentOffset
            } contentSizeDidUpdate: { contentSize in
                viewModel.contentSize = contentSize
            }   // end ScrollView
            .overlay(alignment: .top) {
                VStack {
                    Text("\(viewModel.progress)")
                        .font(.title)
                    Text("viewPort: \(viewModel.viewPortRect().debugDescription)")
                        .font(.caption)
                    Text("viewPort maxX: \(viewModel.viewPortRect().maxX)")
                        .font(.caption)
                }
            }
            
        }   // end GeometryReader
    }   // end body
    
}

extension ContentView {
    class ViewModel: ObservableObject {
        
        // input
        @Published var colors: [UIColor] = []
        
        @Published var contentOffset: CGFloat = .zero
        @Published var contentSize: CGSize = .zero
        
        // output
        var progress: CGFloat {
            return abs(contentOffset) / contentSize.width
        }
        
        init() {
            colors = (0..<4).map { i in
                return [.systemRed, .systemGreen, .systemBlue][i % 3]
            }
        }
    }   // end class
}

extension ContentView.ViewModel {
    func frame(at index: Int) -> CGRect {
        let count = colors.count
        guard count > 0 else { return .zero }
        let width = contentSize.width / CGFloat(count)
        let minX = CGFloat(index) * width
        let frame = CGRect(
            x: minX,
            y: 0,
            width: width,
            height: contentSize.height
        )
        return frame
    }
    
    func viewPortRect() -> CGRect {
        let count = colors.count
        guard count > 0 else { return .zero }
        let width = contentSize.width / CGFloat(count)
        let rect = CGRect(
            origin: .init(x: -contentOffset, y: 0),
            size: .init(width: width, height: contentSize.height)
        )
        return rect
    }
    
    struct TransformAttribute {
        
        let originalFrame: CGRect
        let transformFrame: CGRect
        let zIndex: Int
        let alpha: CGFloat
        
        init(
            originalFrame: CGRect,
            transformFrame: CGRect,
            zIndex: Int,
            alpha: CGFloat
        ) {
            self.originalFrame = originalFrame
            self.transformFrame = transformFrame
            self.zIndex = zIndex
            self.alpha = alpha
        }
        
        var offsetX: CGFloat {
            return (transformFrame.minX - originalFrame.minX) + (transformFrame.width - originalFrame.width) / 2
            //return transformFrame.origin.x - originalFrame.origin.x
        }
        
        var offsetY: CGFloat {
            return .zero // (transformFrame.height - originalFrame.height) / 2
            //return transformFrame.origin.y - originalFrame.origin.y
        }
    }
    
    var sizeScaleRatio: CGFloat { 0.8 }
    var trailingMarginRatio: CGFloat { 0.1 }
    
    func transformAttribute(at index: Int) -> TransformAttribute {
        let originalFrame = frame(at: index)
        let viewPortRect = self.viewPortRect()
        
        // calculate constants
        let endFrameSize = CGSize(
            width: viewPortRect.width * (1 - trailingMarginRatio),
            height: viewPortRect.height
        )
        let startFrameSize = CGSize(
            width: endFrameSize.width * sizeScaleRatio,
            height: endFrameSize.height * sizeScaleRatio
        )
        
        if originalFrame.minX <= viewPortRect.minX {
            // A: top most cover
            // set frame
            return TransformAttribute(
                originalFrame: originalFrame,
                transformFrame: CGRect(
                    x: originalFrame.origin.x,
                    y: originalFrame.origin.y,
                    width: endFrameSize.width,
                    height: endFrameSize.height
                ),
                zIndex: Int.max - index,
                alpha: 1
            )
        } else if originalFrame.minX <= viewPortRect.maxX {
            // B: middle cover
            // timing curve
            let offset = viewPortRect.maxX - originalFrame.minX
            let t = offset / viewPortRect.width
            let timingCurve = easeInOutInterpolation(progress: t)
            // get current scale ratio
            let scaleRatio: CGFloat = {
                let start = sizeScaleRatio
                let end: CGFloat = 1
                return lerp(v0: start, v1: end, t: timingCurve)
            }()
            // set height
            let height = endFrameSize.height * scaleRatio
            // pin offsetY
            let topMargin = (viewPortRect.height - height) / 2
            // set width
            let width = endFrameSize.width * scaleRatio
            // set offsetX
            let end = viewPortRect.origin.x
            let start = viewPortRect.maxX - width
            let minX = lerp(v0: start, v1: end, t: timingCurve)
            // set alpha
            let alpha = lerp(v0: 0.5, v1: 1, t: timingCurve)
            return TransformAttribute(
                originalFrame: originalFrame,
                transformFrame: CGRect(
                    x: minX,
                    y: topMargin - (originalFrame.height - endFrameSize.height) / 2,
                    width: width,
                    height: height
                ),
                zIndex: Int.max - index,
                alpha: alpha
            )
        } else {
            // C: bottom cover
            // timing curve
            let offset = originalFrame.minX - viewPortRect.maxX
            let t = 1 - (offset / viewPortRect.width)
            // set height
            let height = startFrameSize.height
            // pin offsetY
            let topMargin = (viewPortRect.height - height) / 2
            // set width
            let width = startFrameSize.width
            // set offsetX
            let minX = viewPortRect.maxX - width
            // set alpha
            let alpha = lerp(v0: 0, v1: 0.5, t: t)
            return TransformAttribute(
                originalFrame: originalFrame,
                transformFrame: CGRect(
                    x: minX,
                    y: topMargin,
                    width: width,
                    height: height
                ),
                zIndex: Int.max - index,
                alpha: alpha
            )
        }
    }
}

// ref:
// - https://stackoverflow.com/questions/13462001/ease-in-and-ease-out-animation-formula
// - https://math.stackexchange.com/questions/121720/ease-in-out-function/121755#121755
// for a = 2
func easeInOutInterpolation(progress t: CGFloat) -> CGFloat {
    let sqt = t * t
    return sqt / (2.0 * (sqt - t) + 1.0)
}

// linear interpolation
func lerp(v0: CGFloat, v1: CGFloat, t: CGFloat) -> CGFloat {
    return (1 - t) * v0 + (t * v1)
}
