//
//  TweetToolbarView.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-22.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit

final class TweetToolbarView: UIView {
    
    let cameraButton: UIButton = {
        let button = UIButton(type: .system)
        button.imageView?.tintColor = .secondaryLabel
        button.setImage(Asset.ObjectTools.camera.image.withRenderingMode(.alwaysTemplate), for: .normal)
        return button
    }()
    
    let gifButton: UIButton = {
        let button = UIButton(type: .system)
        button.imageView?.tintColor = .secondaryLabel
        button.setImage(Asset.ObjectTools.gif.image.withRenderingMode(.alwaysTemplate), for: .normal)
        return button
    }()
    
    let atButton: UIButton = {
        let button = UIButton(type: .system)
        button.imageView?.tintColor = .secondaryLabel
        button.setImage(Asset.Communication.at.image.withRenderingMode(.alwaysTemplate), for: .normal)
        return button
    }()
    
    let topicButton: UIButton = {
        let button = UIButton(type: .system)
        button.imageView?.tintColor = .secondaryLabel
        button.setImage(Asset.Symbol.sharp.image.withRenderingMode(.alwaysTemplate), for: .normal)
        return button
    }()
    
    let locationButton: UIButton = {
        let button = UIButton(type: .system)
        button.imageView?.tintColor = .secondaryLabel
        button.setImage(Asset.ObjectTools.mappin.image.withRenderingMode(.alwaysTemplate), for: .normal)
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension TweetToolbarView {
    private func _init() {
        backgroundColor = .secondarySystemBackground
        
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 16
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
        ])
        
        let buttons = [
            cameraButton,
            gifButton,
            atButton,
            topicButton,
            locationButton,
        ]
        buttons.forEach { button in
            stackView.addArrangedSubview(button)
        }
    }
}
