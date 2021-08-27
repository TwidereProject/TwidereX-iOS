//
//  UserBriefInfoView.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-30.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import Combine

final class UserBriefInfoView: UIView {
    
    static let containerStackViewSpacing: CGFloat = 10
    static let avatarImageViewSize = CGSize(width: 44, height: 44)
    static let badgeImageViewSize = CGSize(width: 20, height: 20)
    
    var disposeBag = Set<AnyCancellable>()
    
    private(set) lazy var viewModel: ViewModel = {
        let viewModel = ViewModel()
        viewModel.bind(userBriefInfoView: self)
        return viewModel
    }()
    
    let avatarImageView = AvatarImageView()
    
    let badgeImageView = UIImageView()
    
    let headlineLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .label
        return label
    }()
    
//    let lockImageView: UIImageView = {
//        let imageView = UIImageView()
//        imageView.tintColor = .secondaryLabel
//        imageView.contentMode = .center
//        imageView.image = Asset.ObjectTools.lockMini.image.withRenderingMode(.alwaysTemplate)
//        return imageView
//    }()
    
    let secondaryHeadlineLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondaryLabel
        return label
    }()
    
    let subheadlineLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .callout)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondaryLabel
        return label
    }()
    
    let followActionButton = FollowActionButton()
    let menuButton: UIButton = {
        let button = HitTestExpandedButton()
        button.setImage(UIImage(systemName: "ellipsis.circle"), for: .normal)
        button.tintColor = Asset.Colors.hightLight.color
        return button
    }()
    let checkmarkButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
        button.tintColor = Asset.Colors.hightLight.color
        return button
    }()
    
    let activityIndicatorView: UIActivityIndicatorView = {
        let activityIndicatorView = UIActivityIndicatorView(style: .medium)
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.startAnimating()
        return activityIndicatorView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
    deinit {
        viewModel.disposeBag.removeAll()
    }
    
}

extension UserBriefInfoView {
    
    func prepareForReuse() {
        disposeBag.removeAll()
        
        avatarImageView.cancelTask()
        badgeImageView.isHidden = true
        // lockImageView.isHidden = true
        
        activityIndicatorView.isHidden = true
        checkmarkButton.isHidden = true
        followActionButton.isHidden = true
        menuButton.isHidden = true
    }
    
    private func _init() {
        // container: [user avatar | brief info container | more button]
        let containerStackView = UIStackView()
        containerStackView.axis = .horizontal
        containerStackView.spacing = 10
        containerStackView.alignment = .center
        
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerStackView)
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: topAnchor),
            containerStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: containerStackView.trailingAnchor),
            bottomAnchor.constraint(equalTo: containerStackView.bottomAnchor),
        ])
        
        // user avatar
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.addArrangedSubview(avatarImageView)
        NSLayoutConstraint.activate([
            avatarImageView.widthAnchor.constraint(equalToConstant: UserBriefInfoView.avatarImageViewSize.width).priority(.required - 1),
            avatarImageView.heightAnchor.constraint(equalToConstant: UserBriefInfoView.avatarImageViewSize.height).priority(.required - 1),
        ])
        badgeImageView.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.addSubview(badgeImageView)
        NSLayoutConstraint.activate([
            badgeImageView.trailingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 4),
            badgeImageView.bottomAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 4),
            badgeImageView.widthAnchor.constraint(equalToConstant: UserBriefInfoView.badgeImageViewSize.width).priority(.required - 1),
            badgeImageView.heightAnchor.constraint(equalToConstant: UserBriefInfoView.badgeImageViewSize.height).priority(.required - 1),
        ])

        // brief info container: [user meta container | detail]
        let briefInfoContainerStackView = UIStackView()
        containerStackView.addArrangedSubview(briefInfoContainerStackView)
        briefInfoContainerStackView.axis = .vertical
        briefInfoContainerStackView.distribution = .fillEqually
        
        // user meta container: [name | lock | username | (padding)]
        let userMetaContainerStackView = UIStackView()
        briefInfoContainerStackView.addArrangedSubview(userMetaContainerStackView)
        userMetaContainerStackView.axis = .horizontal
        userMetaContainerStackView.alignment = .center
        userMetaContainerStackView.spacing = 6
        userMetaContainerStackView.addArrangedSubview(headlineLabel)
        // userMetaContainerStackView.addArrangedSubview(lockImageView)
        userMetaContainerStackView.addArrangedSubview(secondaryHeadlineLabel)
        let paddingView = UIView()
        userMetaContainerStackView.addArrangedSubview(paddingView)

        headlineLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        //lockImageView.setContentHuggingPriority(.defaultHigh - 1, for: .horizontal)
        secondaryHeadlineLabel.setContentHuggingPriority(.defaultHigh - 2, for: .horizontal)
        paddingView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        // detail container: [detail]
        let detailContainerStackView = UIStackView()
        briefInfoContainerStackView.addArrangedSubview(detailContainerStackView)
        detailContainerStackView.axis = .horizontal
        detailContainerStackView.alignment = .center
        detailContainerStackView.spacing = 6
        detailContainerStackView.addArrangedSubview(subheadlineLabel)
        
        followActionButton.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.addArrangedSubview(followActionButton)
        NSLayoutConstraint.activate([
            followActionButton.heightAnchor.constraint(equalToConstant: FollowActionButton.buttonSize.height).priority(.defaultHigh),
            followActionButton.widthAnchor.constraint(equalToConstant: FollowActionButton.buttonSize.width).priority(.required - 1),
        ])
        followActionButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        followActionButton.setContentCompressionResistancePriority(.required - 1, for: .horizontal)
        
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.addArrangedSubview(menuButton)
        menuButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        menuButton.setContentCompressionResistancePriority(.required - 1, for: .horizontal)
        
        checkmarkButton.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.addArrangedSubview(checkmarkButton)
        checkmarkButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        checkmarkButton.setContentCompressionResistancePriority(.required - 1, for: .horizontal)
        
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.addArrangedSubview(activityIndicatorView)
        activityIndicatorView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        activityIndicatorView.setContentCompressionResistancePriority(.required - 1, for: .horizontal)

        prepareForReuse()
    }
    
    var contentLayoutInset: UIEdgeInsets {
        return UIEdgeInsets(
            top: 0,
            left: UserBriefInfoView.avatarImageViewSize.width + UserBriefInfoView.containerStackViewSpacing,
            bottom: 0,
            right: 0
        )
    }
    
    func setBadgeDisplay() {
        badgeImageView.isHidden = false
    }
}

#if DEBUG
import SwiftUI

struct UserBriefInfoView_Previews: PreviewProvider {
    static var avatarImage: UIImage {
        UIImage(named: "patrick-perkins")!
            .af.imageRoundedIntoCircle()
    }
    
    static var avatarImage2: UIImage {
        UIImage(named: "dan-maisey")!
            .af.imageRoundedIntoCircle()
    }
    
    static var previews: some View {
        Group {
            UIViewPreview(width: 375) {
                let view = UserBriefInfoView()
                view.avatarImageView.image = avatarImage
                return view
            }
            .previewLayout(.fixed(width: 375, height: 200))
            .previewDisplayName("text")
        }
    }
}
#endif
