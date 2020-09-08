//
//  TimelineCollectionViewCell.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-3.
//

import UIKit
import Combine
import AlamofireImage
import ActiveLabel

final class TimelineCollectionViewCell: UICollectionViewCell {

    static let avatarImageViewSize = CGSize(width: 48, height: 48)
    static let verticalMargin: CGFloat = 8
    
    var disposeBag = Set<AnyCancellable>()
    var dateLabelUpdateSubscription: AnyCancellable?
    
    let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .label
        return label
    }()
    
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11, weight: .regular)
        label.textColor = .secondaryLabel
        return label
    }()
    
    let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11, weight: .regular)
        label.textAlignment = .right
        label.textColor = .secondaryLabel
        return label
    }()
    
    let textlabel: ActiveLabel = {
        let label = ActiveLabel()
        label.numberOfLines = 0
        label.enabledTypes = [.mention, .hashtag, .url]
        label.textColor = .label
        return label
    }()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        disposeBag.removeAll()
        avatarImageView.af.cancelImageRequest()
        avatarImageView.image = .placeholder(color: .placeholderText)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension TimelineCollectionViewCell {
    
    private func _init() {
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(avatarImageView)
        NSLayoutConstraint.activate([
            avatarImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: TimelineCollectionViewCell.verticalMargin),
            avatarImageView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: TimelineCollectionViewCell.avatarImageViewSize.width),
            avatarImageView.heightAnchor.constraint(equalToConstant: TimelineCollectionViewCell.avatarImageViewSize.height).priority(.defaultHigh),
            //contentView.bottomAnchor.constraint(greaterThanOrEqualTo: avatarImageView.bottomAnchor, constant: 8).priority(.defaultHigh),
        ])
        
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameLabel)
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 8),
        ])
        nameLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        nameLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        
        usernameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(usernameLabel)
        NSLayoutConstraint.activate([
            usernameLabel.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            usernameLabel.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 4),
        ])
        usernameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        usernameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(dateLabel)
        NSLayoutConstraint.activate([
            dateLabel.centerYAnchor.constraint(equalTo: usernameLabel.centerYAnchor),
            dateLabel.leadingAnchor.constraint(equalTo: usernameLabel.trailingAnchor, constant: 4),
            contentView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: dateLabel.trailingAnchor),
        ])
        dateLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        dateLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        textlabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(textlabel)
        NSLayoutConstraint.activate([
            textlabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor),
            textlabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            contentView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: textlabel.trailingAnchor),
        ])
        
        let paddingView = UIView()
        paddingView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(paddingView)
        NSLayoutConstraint.activate([
            paddingView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            paddingView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            paddingView.heightAnchor.constraint(equalToConstant: 1).priority(.defaultLow),
            contentView.bottomAnchor.constraint(equalTo: paddingView.bottomAnchor),
        ])
        paddingView.setContentHuggingPriority(.defaultLow, for: .vertical)
        
        /// http://swiftandpainless.com/minimal-distance-to-two-views-in-auto-layout/
        NSLayoutConstraint.activate([
            paddingView.topAnchor.constraint(greaterThanOrEqualTo: avatarImageView.bottomAnchor, constant: TimelineCollectionViewCell.verticalMargin),
            paddingView.topAnchor.constraint(equalTo: textlabel.bottomAnchor, constant: TimelineCollectionViewCell.verticalMargin),
            paddingView.topAnchor.constraint(lessThanOrEqualTo: textlabel.bottomAnchor, constant: 10).priority(.required - 1),
        ])
        
        
        contentView.backgroundColor = .systemGray
        nameLabel.backgroundColor = .systemGreen
        textlabel.backgroundColor = .systemYellow
        paddingView.backgroundColor = .systemRed
    }
    
}
