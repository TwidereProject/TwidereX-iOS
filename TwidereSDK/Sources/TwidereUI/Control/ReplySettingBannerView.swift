//
//  ReplySettingBannerView.swift
//  
//
//  Created by MainasuK on 2022-6-16.
//

import UIKit
import TwidereAsset

final public class ReplySettingBannerView: UIView {
    
    let topSeparator = SeparatorLineView()
    
    let overflowBackgroundView = UIView()
    
    let stackView = UIStackView()
    
    public let imageView = UIImageView()
    
    public let label: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .callout)
        label.numberOfLines = 0
        return label
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension ReplySettingBannerView {
    private func _init() {
        // Hack the background view to fill the table width
        overflowBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(overflowBackgroundView)
        NSLayoutConstraint.activate([
            overflowBackgroundView.topAnchor.constraint(equalTo: topAnchor),
            leadingAnchor.constraint(equalTo: overflowBackgroundView.leadingAnchor, constant: 400),
            overflowBackgroundView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 400),
            overflowBackgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        // Hack the line to fill the table width
        topSeparator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(topSeparator)
        NSLayoutConstraint.activate([
            topSeparator.topAnchor.constraint(equalTo: topSeparator.topAnchor),
            leadingAnchor.constraint(equalTo: topSeparator.leadingAnchor, constant: 400),
            topSeparator.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 400),
        ])
        
        // stackView: H - [ icon | label ]
        stackView.axis = .horizontal
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .center
        stackView.spacing = 4
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 8),
        ])
        
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(label)
        
        overflowBackgroundView.backgroundColor = Asset.Colors.hightLight.color.withAlphaComponent(0.6)
        imageView.tintColor = .white
        label.textColor = .white
    }
}
