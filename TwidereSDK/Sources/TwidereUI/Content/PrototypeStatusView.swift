//
//  PrototypeStatusView.swift
//  
//
//  Created by MainasuK on 2022-7-25.
//

import UIKit
import Combine

public protocol PrototypeStatusViewDelegate: AnyObject {
    func layoutDidUpdate(_ view: PrototypeStatusView)
}

final public class PrototypeStatusView: UIView {
    
    public var disposeBag = Set<AnyCancellable>()
    private var observations = Set<NSKeyValueObservation>()
    
    weak var delegate: PrototypeStatusViewDelegate?
    
    public let statusView = StatusView()
    public private(set)var widthLayoutConstraint: NSLayoutConstraint!
                
    public override var intrinsicContentSize: CGSize {
        let size = statusView.frame.size
        defer {
            self.delegate?.layoutDidUpdate(self)
        }
        return CGSize(width: UIView.noIntrinsicMetric, height: size.height)
    }
    
    public override var frame: CGRect {
        didSet {
            guard frame != oldValue else { return }
            layoutIfNeeded()
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        if frame.width != .zero {
            statusView.frame.size.width = frame.width
            widthLayoutConstraint.constant = frame.width
            widthLayoutConstraint.isActive = true
        }
        
        let targetSize = CGSize(
            width: frame.width,
            height: UIView.layoutFittingCompressedSize.height
        )
        
        statusView.frame.size.height = statusView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        
        invalidateIntrinsicContentSize()
    }

    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension PrototypeStatusView {
    private func _init() {
        widthLayoutConstraint = widthAnchor.constraint(equalToConstant: frame.width)

        addSubview(statusView)
        
        // trigger UIViewRepresentable size update
        statusView
            .observe(\.bounds, options: [.initial, .new]) { [weak self] statusView, _ in
                guard let self = self else { return }
                print(statusView.frame)
                self.invalidateIntrinsicContentSize()
            }
            .store(in: &observations)
    }
}
