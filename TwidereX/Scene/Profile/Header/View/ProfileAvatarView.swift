//
//  ProfileAvatarView.swift
//  ProfileAvatarView
//
//  Created by Cirno MainasuK on 2021-9-9.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import Combine

final class ProfileAvatarView: UIView {
    
    static let margin: CGFloat = 4
    static let avatarButtonSize = CGSize(width: 88, height: 88)
    static let badgeImageViewSize = CGSize(width: 24, height: 24)
    
    var disposeBag = Set<AnyCancellable>()
    
    let avatarContainerView = UIView()
    let avatarButton: AvatarButton = {
        let frame = CGRect(origin: .zero, size: ProfileAvatarView.avatarButtonSize)
        let button = AvatarButton(frame: frame)
        button.avatarImageView.image = .placeholder(color: .systemFill)
        return button
    }()
    
    let badgeImageView = UIImageView()
    private let badgeMaskImageView = UIImageView()
    
    let layoutDidChange = PassthroughSubject<Void, Never>()
    let avatarStyle = CurrentValueSubject<CornerStyle, Never>(.circle)
    let badge = CurrentValueSubject<Badge, Never>(.none)
    let badgeStyle = CurrentValueSubject<CornerStyle, Never>(.circle)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension ProfileAvatarView {
    private func _init() {
        backgroundColor = .clear
        avatarContainerView.backgroundColor = .systemBackground
        
        avatarContainerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(avatarContainerView)
        NSLayoutConstraint.activate([
            avatarContainerView.topAnchor.constraint(equalTo: topAnchor),
            avatarContainerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            avatarContainerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            avatarContainerView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        avatarButton.translatesAutoresizingMaskIntoConstraints = false
        avatarContainerView.addSubview(avatarButton)
        NSLayoutConstraint.activate([
            avatarButton.topAnchor.constraint(equalTo: avatarContainerView.topAnchor, constant: ProfileAvatarView.margin),
            avatarButton.leadingAnchor.constraint(equalTo: avatarContainerView.leadingAnchor, constant: ProfileAvatarView.margin),
            avatarContainerView.trailingAnchor.constraint(equalTo: avatarButton.trailingAnchor, constant: ProfileAvatarView.margin),
            avatarContainerView.bottomAnchor.constraint(equalTo: avatarButton.bottomAnchor, constant: ProfileAvatarView.margin),
            avatarButton.widthAnchor.constraint(equalToConstant: ProfileAvatarView.avatarButtonSize.width).priority(.required - 1),
            avatarButton.heightAnchor.constraint(equalToConstant: ProfileAvatarView.avatarButtonSize.height).priority(.required - 1),
        ])
        
        badgeImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(badgeImageView)
        NSLayoutConstraint.activate([
            badgeImageView.trailingAnchor.constraint(equalTo: avatarButton.trailingAnchor),
            badgeImageView.bottomAnchor.constraint(equalTo: avatarButton.bottomAnchor),
            badgeImageView.widthAnchor.constraint(equalToConstant: ProfileAvatarView.badgeImageViewSize.width).priority(.required - 1),
            badgeImageView.heightAnchor.constraint(equalToConstant: ProfileAvatarView.badgeImageViewSize.height).priority(.required - 1),
        ])
        
        Publishers.CombineLatest4(
            avatarStyle,
            badge,
            badgeStyle,
            layoutDidChange
        )
        .sink { [weak self] _ in
            guard let self = self else { return }
            self.updateMask()
        }
        .store(in: &disposeBag)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layoutDidChange.send()
    }
    
}

extension ProfileAvatarView {
    
    enum Badge {
        case none
        case circle
        case robot
        case verified
    }
    
    enum CornerStyle {
        case circle
        case roundedRect
    }
    
    private func updateMask() {
        // mask avatarButton
        let _avatarMaskImage: UIImage? = {
            switch badge.value {
            case .none:
                return nil
            case .circle:
                return Asset.ObjectTools.Badge.circleMask.image
            case .robot:
                return Asset.ObjectTools.Badge.robotMask.image
            case .verified:
                return Asset.ObjectTools.Badge.verifiedMask.image
            }
        }()
        if let avatarMaskImage = _avatarMaskImage {
            let frame = avatarButton.layer.frame
            let imageView = UIImageView(frame: frame)
            imageView.image = avatarMaskImage
            avatarButton.mask = imageView
        } else {
            avatarButton.mask = nil
        }
        
        // mask outline
        let outlineMaskLayer = CAShapeLayer()
        outlineMaskLayer.fillRule = .evenOdd
        outlineMaskLayer.path = {
            let containerFrame = bounds
            let path: UIBezierPath
            switch avatarStyle.value {
            case .circle:
                path = UIBezierPath(ovalIn: containerFrame)
            case .roundedRect:
                path = UIBezierPath(roundedRect: containerFrame, cornerRadius: containerFrame.width / 3)
            }
            return path.cgPath
        }()
        avatarContainerView.layer.mask = outlineMaskLayer
    }
}
