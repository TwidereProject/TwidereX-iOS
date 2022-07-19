//
//  ProfileAvatarView.swift
//  ProfileAvatarView
//
//  Created by Cirno MainasuK on 2021-9-9.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import Combine
import TwidereCore

public final class ProfileAvatarView: UIView {
    
    var disposeBag = Set<AnyCancellable>()
    var observations = Set<NSKeyValueObservation>()

    public let avatarContainerView = UIView()
    
    public let avatarButton: AvatarButton = {
        let button = AvatarButton(frame: .zero)
        button.avatarImageView.image = .placeholder(color: .systemFill)
        return button
    }()
    var avatarButtonWidthLayoutConstraint: NSLayoutConstraint!
    var avatarButtonHeightLayoutConstraint: NSLayoutConstraint!
    
    let badgeImageView = UIImageView()
    var badgeImageViewWidthLayoutConstraint: NSLayoutConstraint!
    var badgeImageViewHeightLayoutConstraint: NSLayoutConstraint!
    
    private let badgeMaskImageView = UIImageView()
        
    private(set) var dimension: Dimension?
    
    @Published public var avatarStyle = UserDefaults.shared.avatarStyle
    @Published public var badge: Badge = .none
    let layoutDidChange = PassthroughSubject<Void, Never>()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    public required init?(coder: NSCoder) {
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
            avatarContainerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            avatarContainerView.centerYAnchor.constraint(equalTo: centerYAnchor),
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
        
        UserDefaults.shared
            .observe(\.avatarStyle, options: [.initial, .new]) { [weak self] defaults, _ in
                guard let self = self else { return }
                self.avatarStyle = defaults.avatarStyle
            }
            .store(in: &observations)
        
        setNeedsUpdateConstraints()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        setNeedsUpdateConstraints()
        layoutDidChange.send()
    }
    
    public override func updateConstraints() {
        super.updateConstraints()
        
        // assert width equalt to height
        
        guard let dimension = self.dimension else { return }
        self.avatarButtonWidthLayoutConstraint.constant = bounds.width
        self.avatarButtonHeightLayoutConstraint.constant = bounds.height
        
        let scale = bounds.width / dimension.primitiveAvatarButtonSize.width
        let badgeDimension = dimension.primitiveBadgeImageViewSize.width * scale
        self.badgeImageViewWidthLayoutConstraint.constant = badgeDimension
        self.badgeImageViewHeightLayoutConstraint.constant = badgeDimension
        
        self.setNeedsLayout()
    }
    
    public func setup(dimension: Dimension) {
        guard self.dimension == nil else {
            assertionFailure("only setup once")
            return
        }
        
        self.dimension = dimension
        dimension.layout(view: self)
        setNeedsLayout()
    }
    
}

extension ProfileAvatarView {
    
    public enum Dimension {
        case inline
        case plain
        
        public var primitiveAvatarButtonSize: CGSize {
            switch self {
            case .inline:       return CGSize(width: 44, height: 44)
            case .plain:        return CGSize(width: 88, height: 88)
            }
        }
        
        public var primitiveBadgeImageViewSize: CGSize {
            return CGSize(width: 24, height: 24)
        }
        
        func layout(view: ProfileAvatarView) {
            switch self {
            case .inline:        layoutInline(view: view)
            case .plain:        layoutPlain(view: view)
            }
        }
    }
    
}

extension ProfileAvatarView.Dimension {
    func layoutInline(view: ProfileAvatarView) {
        guard let dimension = view.dimension else {
            assertionFailure()
            return
        }
        
        view.avatarButton.translatesAutoresizingMaskIntoConstraints = false
        view.avatarContainerView.addSubview(view.avatarButton)
        view.avatarButtonWidthLayoutConstraint = view.avatarButton.widthAnchor.constraint(equalToConstant: dimension.primitiveAvatarButtonSize.width).priority(.required - 1)
        view.avatarButtonHeightLayoutConstraint = view.avatarButton.heightAnchor.constraint(equalToConstant: dimension.primitiveAvatarButtonSize.height).priority(.required - 1)
        NSLayoutConstraint.activate([
            view.avatarButton.topAnchor.constraint(equalTo: view.avatarContainerView.topAnchor),
            view.avatarButton.leadingAnchor.constraint(equalTo: view.avatarContainerView.leadingAnchor),
            view.avatarContainerView.trailingAnchor.constraint(equalTo: view.avatarButton.trailingAnchor),
            view.avatarContainerView.bottomAnchor.constraint(equalTo: view.avatarButton.bottomAnchor),
            view.avatarButtonWidthLayoutConstraint,
            view.avatarButtonHeightLayoutConstraint,
        ])
        
        view.badgeImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(view.badgeImageView)
        view.badgeImageViewWidthLayoutConstraint = view.badgeImageView.widthAnchor.constraint(equalToConstant: dimension.primitiveBadgeImageViewSize.width).priority(.required - 1)
        view.badgeImageViewHeightLayoutConstraint = view.badgeImageView.heightAnchor.constraint(equalToConstant: dimension.primitiveBadgeImageViewSize.height).priority(.required - 1)
        NSLayoutConstraint.activate([
            view.badgeImageView.trailingAnchor.constraint(equalTo: view.avatarButton.trailingAnchor, constant: 4),    // offset 4pt
            view.badgeImageView.bottomAnchor.constraint(equalTo: view.avatarButton.bottomAnchor, constant: 2),        // offset 2pt
            view.badgeImageViewWidthLayoutConstraint,
            view.badgeImageViewHeightLayoutConstraint,
        ])
    }
    
    func layoutPlain(view: ProfileAvatarView) {
        guard let dimension = view.dimension else {
            assertionFailure()
            return
        }
        
        view.avatarButton.translatesAutoresizingMaskIntoConstraints = false
        view.avatarContainerView.layoutMargins = UIEdgeInsets(4)
        view.avatarContainerView.addSubview(view.avatarButton)
        view.avatarButtonWidthLayoutConstraint = view.avatarButton.widthAnchor.constraint(equalToConstant: dimension.primitiveAvatarButtonSize.width).priority(.required - 1)
        view.avatarButtonHeightLayoutConstraint = view.avatarButton.heightAnchor.constraint(equalToConstant: dimension.primitiveAvatarButtonSize.height).priority(.required - 1)
        NSLayoutConstraint.activate([
            view.avatarButton.topAnchor.constraint(equalTo: view.avatarContainerView.layoutMarginsGuide.topAnchor),
            view.avatarButton.leadingAnchor.constraint(equalTo: view.avatarContainerView.layoutMarginsGuide.leadingAnchor),
            view.avatarContainerView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: view.avatarButton.trailingAnchor),
            view.avatarContainerView.layoutMarginsGuide.bottomAnchor.constraint(equalTo: view.avatarButton.bottomAnchor),
            view.avatarButtonWidthLayoutConstraint,
            view.avatarButtonHeightLayoutConstraint,
        ])
        
        view.badgeImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(view.badgeImageView)
        view.badgeImageViewWidthLayoutConstraint = view.badgeImageView.widthAnchor.constraint(equalToConstant: dimension.primitiveBadgeImageViewSize.width).priority(.required - 1)
        view.badgeImageViewHeightLayoutConstraint = view.badgeImageView.heightAnchor.constraint(equalToConstant: dimension.primitiveBadgeImageViewSize.height).priority(.required - 1)
        NSLayoutConstraint.activate([
            view.badgeImageView.trailingAnchor.constraint(equalTo: view.avatarButton.trailingAnchor),
            view.badgeImageView.bottomAnchor.constraint(equalTo: view.avatarButton.bottomAnchor),
            view.badgeImageViewWidthLayoutConstraint,
            view.badgeImageViewHeightLayoutConstraint,
        ])
    }
}

extension ProfileAvatarView {
    
    public enum Badge {
        case none
        case circle(CircleBadge)
        case robot
        case verified
        
        public enum CircleBadge {
            case twitter
            case mastodon
            
            var image: UIImage {
                switch self {
                case .twitter:      return Asset.Badge.circleTwitter.image
                case .mastodon:     return Asset.Badge.circleMastodon.image
                }
            }
        }
    }
    
    public enum CornerStyle {
        case circle
        case roundedRect
    }
    
    private func updateBadge() {
        guard let dimension = self.dimension else { return }
        
        // mask avatarButton
        let _avatarMaskImage: UIImage? = {
            switch (dimension, badge) {
            case (_, .none):
                return nil
            case (.inline, .circle):
                return Asset.Badge.circleMask44.image
            case (.plain, .circle):
                return Asset.Badge.circleMask88.image
            case (.inline, .robot):
                return Asset.Badge.robotMask44.image
            case (.plain, .robot):
                return Asset.Badge.robotMask88.image
            case (.inline, .verified):
                return Asset.Badge.verifiedMask44.image
            case (.plain, .verified):
                return Asset.Badge.verifiedMask88.image
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
        case .circle(let circleBadge):
            badgeImageView.image = circleBadge.image
        case .verified:
            badgeImageView.image = Asset.Badge.verified.image
        case .robot:
            badgeImageView.image = Asset.Badge.robot.image
        }
        
        
        // mask outline
        let outlineMaskLayer = CAShapeLayer()
        outlineMaskLayer.fillRule = .evenOdd
        outlineMaskLayer.path = {
            let path: UIBezierPath
            switch avatarStyle {
            case .circle:
                path = UIBezierPath(ovalIn: avatarContainerView.bounds)
            case .roundedSquare:
                let cornerRadiusRatio: CGFloat = 4
                path = UIBezierPath(roundedRect: avatarContainerView.bounds, cornerRadius: avatarContainerView.bounds.width / cornerRadiusRatio)
            }
            return path.cgPath
        }()
        avatarContainerView.layer.mask = outlineMaskLayer
        
        let cornerConfiguration: AvatarImageView.CornerConfiguration = {
            switch avatarStyle {
            case .circle:
                return .init(corner: .circle)
            case .roundedSquare:
                return .init(corner: .scale())
            }
        }()
        
        // set imageView corner
        avatarButton.avatarImageView.configure(cornerConfiguration: cornerConfiguration)
    }
}
