//
//  TimelinePostActionToolbar.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-17.
//

import UIKit

final class TimelinePostActionToolbar: UIView {
    
    static let height: CGFloat = 40
    static let buttonTitleImagePadding: CGFloat = 4
    
    let replyButton: UIButton = {
        let button = UIButton()
        button.imageView?.tintColor = .secondaryLabel
        button.setImage(Asset.Communication.mdiMessageReply.image.withRenderingMode(.alwaysTemplate), for: .normal)
        button.titleLabel?.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        button.setTitle("", for: .normal)
        button.setTitleColor(.secondaryLabel, for: .normal)
        button.setInsets(forContentPadding: .zero, imageTitlePadding: TimelinePostActionToolbar.buttonTitleImagePadding)
        button.contentHorizontalAlignment = .leading
        return button
    }()
    
    let retweetButton: UIButton = {
        let button = UIButton()
        button.imageView?.tintColor = .secondaryLabel
        button.setImage(Asset.Arrows.mdiTwitterRetweet.image.withRenderingMode(.alwaysTemplate), for: .normal)
        button.titleLabel?.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        button.setTitle("", for: .normal)
        button.setTitleColor(.secondaryLabel, for: .normal)
        button.setInsets(forContentPadding: .zero, imageTitlePadding: TimelinePostActionToolbar.buttonTitleImagePadding)
        button.contentHorizontalAlignment = .leading
        return button
    }()
    
    let favoriteButton: UIButton = {
        let button = UIButton()
        button.setImage(Asset.Health.icRoundFavoriteBorder.image.withRenderingMode(.alwaysTemplate), for: .normal)
        button.imageView?.tintColor = .secondaryLabel
        button.titleLabel?.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        button.setTitle("", for: .normal)
        button.setTitleColor(.secondaryLabel, for: .normal)
        button.setInsets(forContentPadding: .zero, imageTitlePadding: TimelinePostActionToolbar.buttonTitleImagePadding)
        button.contentHorizontalAlignment = .leading
        return button
    }()
    
    let shareButton: UIButton = {
        let button = UIButton()
        button.imageView?.tintColor = .secondaryLabel
        button.setImage(Asset.ObjectTools.icRoundShare.image.withRenderingMode(.alwaysTemplate), for: .normal)
        button.contentHorizontalAlignment = .trailing
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

extension TimelinePostActionToolbar {
    
    private func _init() {
        replyButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(replyButton)
        NSLayoutConstraint.activate([
            replyButton.topAnchor.constraint(equalTo: topAnchor),
            replyButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomAnchor.constraint(equalTo: replyButton.bottomAnchor),
            replyButton.heightAnchor.constraint(equalToConstant: TimelinePostActionToolbar.height).priority(.defaultHigh),
        ])

        retweetButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(retweetButton)
        NSLayoutConstraint.activate([
            retweetButton.topAnchor.constraint(equalTo: topAnchor),
            retweetButton.leadingAnchor.constraint(equalTo: replyButton.trailingAnchor),
            bottomAnchor.constraint(equalTo: retweetButton.bottomAnchor),
        ])
        
        favoriteButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(favoriteButton)
        NSLayoutConstraint.activate([
            favoriteButton.topAnchor.constraint(equalTo: topAnchor),
            favoriteButton.leadingAnchor.constraint(equalTo: retweetButton.trailingAnchor),
            bottomAnchor.constraint(equalTo: favoriteButton.bottomAnchor),
        ])
        
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(shareButton)
        NSLayoutConstraint.activate([
            shareButton.topAnchor.constraint(equalTo: topAnchor),
            shareButton.leadingAnchor.constraint(equalTo: favoriteButton.trailingAnchor),
            trailingAnchor.constraint(equalTo: shareButton.trailingAnchor),
            bottomAnchor.constraint(equalTo: shareButton.bottomAnchor),
        ])
        shareButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        NSLayoutConstraint.activate([
            replyButton.heightAnchor.constraint(equalTo: retweetButton.heightAnchor),
            replyButton.heightAnchor.constraint(equalTo: favoriteButton.heightAnchor),
            replyButton.heightAnchor.constraint(equalTo: shareButton.heightAnchor),
            replyButton.widthAnchor.constraint(equalTo: retweetButton.widthAnchor),
            replyButton.widthAnchor.constraint(equalTo: favoriteButton.widthAnchor),
            replyButton.widthAnchor.constraint(equalTo: shareButton.widthAnchor, multiplier: 2),
        ])
    }
    
}

#if DEBUG
import SwiftUI


#endif

struct TimelinePostActionToolbar_Previews: PreviewProvider {
    static var previews: some View {
        UIViewPreview(width: 300) {
            let toolbar = TimelinePostActionToolbar()
            return toolbar
        }
        .previewLayout(.fixed(width: 300, height: 100))
    }
}
