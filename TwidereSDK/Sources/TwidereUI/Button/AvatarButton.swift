//
//  AvatarButton.swift
//  AvatarButton
//
//  Created by Cirno MainasuK on 2021-8-20.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit

public class AvatarButton: UIControl {
    
    // UIControl.Event - Application: 0x0F000000
    static let primaryAction = UIControl.Event(rawValue: 1 << 25)     // 0x01000000
    var primaryActionState: UIControl.State = .normal
    
    public var size = CGSize(width: 44, height: 44)
    public let avatarImageView = AvatarImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
    func _init() {
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(avatarImageView)
        NSLayoutConstraint.activate([
            avatarImageView.topAnchor.constraint(equalTo: topAnchor),
            avatarImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            avatarImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            avatarImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        isAccessibilityElement = true
    }
    
    func updateAppearance() {
        avatarImageView.alpha = primaryActionState.contains(.highlighted)  ? 0.6 : 1.0
    }
    
}

extension AvatarButton {
    
    public override var intrinsicContentSize: CGSize {
        return size
    }
    
    public override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        defer { updateAppearance() }
        
        updateState(touch: touch, event: event)
        return super.beginTracking(touch, with: event)
    }
    
    public override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        defer { updateAppearance() }
        
        updateState(touch: touch, event: event)
        return super.continueTracking(touch, with: event)
    }
    
    public override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        defer { updateAppearance() }
        resetState()
        
        if let touch = touch {
            if AvatarButton.isTouching(touch, view: self, event: event) {
                sendActions(for: AvatarButton.primaryAction)
            } else {
                // do nothing
            }
        }
        
        super.endTracking(touch, with: event)
    }
    
    public override func cancelTracking(with event: UIEvent?) {
        defer { updateAppearance() }
        
        resetState()
        super.cancelTracking(with: event)
    }
    
}

extension AvatarButton {
    
    private static func isTouching(_ touch: UITouch, view: UIView, event: UIEvent?) -> Bool {
        let location = touch.location(in: view)
        return view.point(inside: location, with: event)
    }
    
    private func resetState() {
        primaryActionState = .normal
    }
    
    private func updateState(touch: UITouch, event: UIEvent?) {
        primaryActionState = AvatarButton.isTouching(touch, view: self, event: event) ? .highlighted : .normal
    }
    
}
