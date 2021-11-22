//
//  ProfileAvatarView.swift
//  ProfileAvatarView
//
//  Created by Cirno MainasuK on 2021-9-9.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import Combine

public final class ProfileAvatarView: UIView {
    
    static let primitiveAvatarButtonSize = CGSize(width: 88, height: 88)
    static let primitiveBadgeImageViewSize = CGSize(width: 24, height: 24)
    
    var disposeBag = Set<AnyCancellable>()
    
    public let avatarContainerView = UIView()
    
    public let avatarButton: AvatarButton = {
        let frame = CGRect(origin: .zero, size: ProfileAvatarView.primitiveAvatarButtonSize)
        let button = AvatarButton(frame: frame)
        button.avatarImageView.image = .placeholder(color: .systemFill)
        return button
    }()
    var avatarButtonWidthLayoutConstraint: NSLayoutConstraint!
    var avatarButtonHeightLayoutConstraint: NSLayoutConstraint!
    
    let badgeImageView = UIImageView()
    var badgeImageViewWidthLayoutConstraint: NSLayoutConstraint!
    var badgeImageViewHeightLayoutConstraint: NSLayoutConstraint!
    
    private let badgeMaskImageView = UIImageView()
    
    let layoutDidChange = PassthroughSubject<Void, Never>()
    
    public var dimention: CGFloat = 44.0 {
        didSet {
            updateScale()
        }
    }
    @Published public var avatarStyle: CornerStyle = .circle
    @Published public var badge: Badge = .none
    
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
        avatarButtonWidthLayoutConstraint = avatarButton.widthAnchor.constraint(equalToConstant: ProfileAvatarView.primitiveAvatarButtonSize.width).priority(.required - 1)
        avatarButtonHeightLayoutConstraint = avatarButton.heightAnchor.constraint(equalToConstant: ProfileAvatarView.primitiveAvatarButtonSize.height).priority(.required - 1)
        NSLayoutConstraint.activate([
            avatarButton.topAnchor.constraint(equalTo: avatarContainerView.topAnchor),
            avatarButton.leadingAnchor.constraint(equalTo: avatarContainerView.leadingAnchor),
            avatarContainerView.trailingAnchor.constraint(equalTo: avatarButton.trailingAnchor),
            avatarContainerView.bottomAnchor.constraint(equalTo: avatarButton.bottomAnchor),
            avatarButtonWidthLayoutConstraint,
            avatarButtonHeightLayoutConstraint,
        ])
        
        badgeImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(badgeImageView)
        badgeImageViewWidthLayoutConstraint = badgeImageView.widthAnchor.constraint(equalToConstant: ProfileAvatarView.primitiveBadgeImageViewSize.width).priority(.required - 1)
        badgeImageViewHeightLayoutConstraint = badgeImageView.heightAnchor.constraint(equalToConstant: ProfileAvatarView.primitiveBadgeImageViewSize.height).priority(.required - 1)
        NSLayoutConstraint.activate([
            badgeImageView.trailingAnchor.constraint(equalTo: avatarButton.trailingAnchor),
            badgeImageView.bottomAnchor.constraint(equalTo: avatarButton.bottomAnchor),
            badgeImageViewWidthLayoutConstraint,
            badgeImageViewHeightLayoutConstraint,
        ])

        Publishers.CombineLatest3(
            $avatarStyle,
            $badge,
            layoutDidChange
        )
        .sink { [weak self] _ in
            guard let self = self else { return }
            self.updateBadge()
        }
        .store(in: &disposeBag)
        
        updateScale()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        layoutDidChange.send()
    }
    
}

extension ProfileAvatarView {

    func updateScale() {
        self.avatarButtonWidthLayoutConstraint.constant = dimention
        self.avatarButtonHeightLayoutConstraint.constant = dimention
        
        let scale = dimention / ProfileAvatarView.primitiveAvatarButtonSize.width
        let badgeDimention = ProfileAvatarView.primitiveBadgeImageViewSize.width * scale
        self.badgeImageViewWidthLayoutConstraint.constant = badgeDimention
        self.badgeImageViewHeightLayoutConstraint.constant = badgeDimention
        
        self.setNeedsLayout()
    }
    
}

extension ProfileAvatarView {
    
    public enum Badge {
        case none
        case circle
        case robot
        case verified
    }
    
    public enum CornerStyle {
        case circle
        case roundedRect
    }
    
    private func updateBadge() {
        // mask avatarButton
        let _avatarMaskImage: UIImage? = {
            switch badge {
            case .none:
                return nil
            case .circle:
                return Asset.Badge.circleMask.image
            case .robot:
                return Asset.Badge.robotMask.image
            case .verified:
                return Asset.Badge.verifiedMask.image
            }
        }()
        if let avatarMaskImage = _avatarMaskImage {
            let frame = avatarButton.layer.frame
            let imageView = UIImageView(frame: frame)
            imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            imageView.image = avatarMaskImage
            avatarButton.mask = imageView
        } else {
            avatarButton.mask = nil
        }
        
        // set badge
        switch badge {
        case .none:
            badgeImageView.image = nil
        case .circle:
            badgeImageView.image = nil
        case .verified:
            badgeImageView.image = Asset.Badge.verified.image
        case .robot:
            badgeImageView.image = Asset.Badge.robot.image
        }
        
        // mask outline
        let outlineMaskLayer = CAShapeLayer()
        outlineMaskLayer.fillRule = .evenOdd
        outlineMaskLayer.path = {
            let containerFrame = bounds
            let path: UIBezierPath
            switch avatarStyle {
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
