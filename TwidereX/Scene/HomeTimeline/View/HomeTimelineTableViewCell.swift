//
//  HomeTimelineTableViewCell.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-3.
//

import UIKit
import Combine
import AlamofireImage
import ActiveLabel

final class HomeTimelineTableViewCell: UITableViewCell {

    static let avatarImageViewSize = CGSize(width: 48, height: 48)
    static let verticalMargin: CGFloat = 8
    
    var disposeBag = Set<AnyCancellable>()
    var dateLabelUpdateSubscription: AnyCancellable?
    
    let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    
    let retweetNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        return label
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
        dateLabelUpdateSubscription = nil
        disposeBag.removeAll()
        avatarImageView.af.cancelImageRequest()
        avatarImageView.image = .placeholder(color: .placeholderText)
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension HomeTimelineTableViewCell {
    
    private func _init() {
        
        retweetNameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(retweetNameLabel)
        NSLayoutConstraint.activate([
            retweetNameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: HomeTimelineTableViewCell.verticalMargin),
            contentView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: retweetNameLabel.trailingAnchor),
        ])
        
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(avatarImageView)
        NSLayoutConstraint.activate([
            avatarImageView.topAnchor.constraint(equalTo: retweetNameLabel.bottomAnchor, constant: 4),
            avatarImageView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: HomeTimelineTableViewCell.avatarImageViewSize.width),
            avatarImageView.heightAnchor.constraint(equalToConstant: HomeTimelineTableViewCell.avatarImageViewSize.height).priority(.defaultHigh),
            retweetNameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 8),
        ])
        
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameLabel)
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: avatarImageView.topAnchor),
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
            paddingView.topAnchor.constraint(greaterThanOrEqualTo: avatarImageView.bottomAnchor, constant: HomeTimelineTableViewCell.verticalMargin),
            paddingView.topAnchor.constraint(equalTo: textlabel.bottomAnchor, constant: HomeTimelineTableViewCell.verticalMargin),
            paddingView.topAnchor.constraint(lessThanOrEqualTo: textlabel.bottomAnchor, constant: 10).priority(.required - 1),
        ])
        
        // contentView.backgroundColor = .systemGray
        // nameLabel.backgroundColor = .systemGreen
        // textlabel.backgroundColor = .systemYellow
        // paddingView.backgroundColor = .systemRed
    }
    
}
