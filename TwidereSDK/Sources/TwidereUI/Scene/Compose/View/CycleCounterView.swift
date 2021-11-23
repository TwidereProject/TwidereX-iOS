//
//  CycleCounterView.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-22.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import Combine

public final class CycleCounterView: UIView {
    
    var disposeBag = Set<AnyCancellable>()

    private let backRingLayer: CAShapeLayer = {
        let shapeLayer = CAShapeLayer()
        shapeLayer.lineCap = .round
        shapeLayer.lineWidth = 2
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = UIColor.secondarySystemBackground.cgColor
        return shapeLayer
    }()
    
    private let frontRingLayer: CAShapeLayer = {
        let shapeLayer = CAShapeLayer()
        shapeLayer.lineCap = .round
        shapeLayer.lineWidth = 2
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = Asset.Colors.hightLight.color.cgColor
        return shapeLayer
    }()
    
    @Published public var strokeColor = Asset.Colors.hightLight.color
    @Published public var progress: CGFloat = 0.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension CycleCounterView {
    
    private func _init() {
        updateLayerPath()
        
        layer.addSublayer(backRingLayer)
        layer.addSublayer(frontRingLayer)
        
        $strokeColor
            .receive(on: DispatchQueue.main)
            .sink { [weak self] strokeColor in
                guard let self = self else { return }
                self.frontRingLayer.strokeColor = strokeColor.cgColor
            }
            .store(in: &disposeBag)
        $progress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                guard let self = self else { return }
                let progress = max(0, min(1, progress))
                self.frontRingLayer.strokeEnd = progress
            }
            .store(in: &disposeBag)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        updateLayerPath()
    }
    
}

extension CycleCounterView {
    private func updateLayerPath() {
        guard bounds != .zero else { return }
        
        
        backRingLayer.frame = bounds
        backRingLayer.position = CGPoint(x: bounds.width, y: bounds.height)

        frontRingLayer.frame = bounds
        frontRingLayer.position = CGPoint(x: bounds.width, y: bounds.height)
        
        backRingLayer.path = UIBezierPath(arcCenter: .zero, radius: bounds.width * 0.5, startAngle: -0.5 * CGFloat.pi, endAngle: 1.5 * CGFloat.pi, clockwise: true).cgPath
        frontRingLayer.path = UIBezierPath(arcCenter: .zero, radius: bounds.width * 0.5, startAngle: -0.5 * CGFloat.pi, endAngle: 1.5 * CGFloat.pi, clockwise: true).cgPath
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        backRingLayer.fillColor = UIColor.clear.cgColor
        backRingLayer.strokeColor = UIColor.secondarySystemBackground.cgColor
        
        frontRingLayer.fillColor = UIColor.clear.cgColor
        frontRingLayer.strokeColor = Asset.Colors.hightLight.color.cgColor
    }
}
