//
//  TweetToolbarView.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-22.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit

protocol TweetToolbarViewDelegate: class {
    func tweetToolbarView(_ tweetToolbarView: TweetToolbarView, cameraButtonDidPressed sender: UIButton)
    func tweetToolbarView(_ tweetToolbarView: TweetToolbarView, gifButtonDidPressed sender: UIButton)
    func tweetToolbarView(_ tweetToolbarView: TweetToolbarView, atButtonDidPressed sender: UIButton)
    func tweetToolbarView(_ tweetToolbarView: TweetToolbarView, topicButtonDidPressed sender: UIButton)
    func tweetToolbarView(_ tweetToolbarView: TweetToolbarView, locationButtonDidPressed sender: UIButton)
}

final class TweetToolbarView: UIView {
    
    weak var delegate: TweetToolbarViewDelegate?
    
    let cameraButton: UIButton = {
        let button = UIButton(type: .custom)
        button.imageView?.tintColor = .secondaryLabel
        button.setImage(Asset.ObjectTools.camera.image.withRenderingMode(.alwaysTemplate), for: .normal)
        return button
    }()
    
    let gifButton: UIButton = {
        let button = UIButton(type: .custom)
        button.imageView?.tintColor = .secondaryLabel
        button.setImage(Asset.ObjectTools.gif.image.withRenderingMode(.alwaysTemplate), for: .normal)
        return button
    }()
    
    let atButton: UIButton = {
        let button = UIButton(type: .custom)
        button.imageView?.tintColor = .secondaryLabel
        button.setImage(Asset.Communication.at.image.withRenderingMode(.alwaysTemplate), for: .normal)
        return button
    }()
    
    let topicButton: UIButton = {
        let button = UIButton(type: .custom)
        button.imageView?.tintColor = .secondaryLabel
        button.setImage(Asset.Symbol.sharp.image.withRenderingMode(.alwaysTemplate), for: .normal)
        return button
    }()
    
    let locationButton: UIButton = {
        let button = UIButton(type: .custom)
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
        
        cameraButton.addTarget(self, action: #selector(TweetToolbarView.cameraButtonDidPressed(_:)), for: .touchUpInside)
        gifButton.addTarget(self, action: #selector(TweetToolbarView.gifButtonDidPressed(_:)), for: .touchUpInside)
        atButton.addTarget(self, action: #selector(TweetToolbarView.atButtonDidPressed(_:)), for: .touchUpInside)
        topicButton.addTarget(self, action: #selector(TweetToolbarView.topicButtonDidPressed(_:)), for: .touchUpInside)
        locationButton.addTarget(self, action: #selector(TweetToolbarView.locationButtonDidPressed(_:)), for: .touchUpInside)
    }
}


extension TweetToolbarView {
    
    @objc private func cameraButtonDidPressed(_ sender: UIButton) {
        delegate?.tweetToolbarView(self, cameraButtonDidPressed: sender)
    }
    
    @objc private func gifButtonDidPressed(_ sender: UIButton) {
        delegate?.tweetToolbarView(self, gifButtonDidPressed: sender)
    }
    
    @objc private func atButtonDidPressed(_ sender: UIButton) {
        delegate?.tweetToolbarView(self, atButtonDidPressed: sender)
    }
    
    @objc private func topicButtonDidPressed(_ sender: UIButton) {
        delegate?.tweetToolbarView(self, topicButtonDidPressed: sender)
    }
    
    @objc private func locationButtonDidPressed(_ sender: UIButton) {
        delegate?.tweetToolbarView(self, locationButtonDidPressed: sender)
    }
    
}
