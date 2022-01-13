//
//  CurveAlgorithm.swift
//
// Ref: https://github.com/nhatminh12369/LineChart/blob/master/LineChart/CurveAlgorithm.swift

import UIKit

public struct CurvedSegment {
    public var controlPoint1: CGPoint
    public var controlPoint2: CGPoint
}

public class CurveAlgorithm {
    public static let shared = CurveAlgorithm()
    
    private func controlPointsFrom(points: [CGPoint]) -> [CurvedSegment] {
        var result: [CurvedSegment] = []
        
        // control point offset
        let delta: CGFloat = 0.4
        
        // only use horizontal control point
        for i in 1..<points.count {
            let A = points[i-1]
            let B = points[i]
            let controlPoint1 = CGPoint(x: A.x + delta*(B.x-A.x), y: A.y)
            let controlPoint2 = CGPoint(x: B.x - delta*(B.x-A.x), y: B.y)
            let curvedSegment = CurvedSegment(controlPoint1: controlPoint1, controlPoint2: controlPoint2)
            result.append(curvedSegment)
        }
        
        return result
    }

    // Create a curved bezier path that connects all points in the dataset
    public func createCurvedPath(_ dataPoints: [CGPoint]) -> UIBezierPath? {
        let path = UIBezierPath()
        path.move(to: dataPoints[0])
        
        var curveSegments: [CurvedSegment] = []
        curveSegments = controlPointsFrom(points: dataPoints)
        
        for i in 1..<dataPoints.count {
            path.addCurve(to: dataPoints[i], controlPoint1: curveSegments[i-1].controlPoint1, controlPoint2: curveSegments[i-1].controlPoint2)
        }
        return path
    }
}
