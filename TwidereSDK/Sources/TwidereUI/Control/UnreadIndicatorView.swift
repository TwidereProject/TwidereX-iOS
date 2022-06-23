//
//  UnreadIndicatorView.swift
//  
//
//  Created by MainasuK on 2022-6-23.
//

import UIKit

final public class UnreadIndicatorView: UIView {
    
    static var blurEffect: UIBlurEffect { UIBlurEffect(style: .systemMaterial) }
    
    let visualEffectView = UIVisualEffectView(effect: UnreadIndicatorView.blurEffect)
    
    let vibranceEffectView = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: UnreadIndicatorView.blurEffect))
    
    public let label: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .callout).scaledFont(for: .monospacedDigitSystemFont(ofSize: 17, weight: .medium))
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        return label
    }()
    
    public var translationY: CGFloat = .zero {
        didSet {
            transform = CGAffineTransform(translationX: 0, y: translationY)
        }
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

extension UnreadIndicatorView {
    private func _init() {
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(visualEffectView)
        NSLayoutConstraint.activate([
            visualEffectView.topAnchor.constraint(equalTo: topAnchor),
            visualEffectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            visualEffectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            visualEffectView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        vibranceEffectView.translatesAutoresizingMaskIntoConstraints = false
        visualEffectView.contentView.addSubview(vibranceEffectView)
        NSLayoutConstraint.activate([
            vibranceEffectView.topAnchor.constraint(equalTo: visualEffectView.contentView.topAnchor),
            vibranceEffectView.leadingAnchor.constraint(equalTo: visualEffectView.contentView.leadingAnchor),
            vibranceEffectView.trailingAnchor.constraint(equalTo: visualEffectView.contentView.trailingAnchor),
            vibranceEffectView.bottomAnchor.constraint(equalTo: visualEffectView.contentView.bottomAnchor),
        ])
        
        label.translatesAutoresizingMaskIntoConstraints = false
        vibranceEffectView.contentView.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: vibranceEffectView.contentView.topAnchor, constant: 6),
            label.leadingAnchor.constraint(equalTo: vibranceEffectView.contentView.leadingAnchor, constant: 6),
            vibranceEffectView.contentView.trailingAnchor.constraint(equalTo: label.trailingAnchor, constant: 6),
            vibranceEffectView.contentView.bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: 6),
        ])
        
        layer.masksToBounds = true
        layer.cornerCurve = .continuous
        layer.cornerRadius = 8
    }
}
