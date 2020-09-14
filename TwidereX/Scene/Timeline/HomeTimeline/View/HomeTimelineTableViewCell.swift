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
    static let buttonTitleImagePadding: CGFloat = 4
    static let verticalMargin: CGFloat = 8
    
    var disposeBag = Set<AnyCancellable>()
    var dateLabelUpdateSubscription: AnyCancellable?
    
    let retweetContainerStackView = UIStackView()
    let tweetPanelContainerStackView = UIStackView()

    let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()

    let retweetIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .secondaryLabel
        imageView.image = Asset.Arrows.mdiTwitterRetweet.image.withRenderingMode(.alwaysTemplate)
        return imageView
    }()
    
    let retweetInfoLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .secondaryLabel
        label.text = "Bob Retweeted"
        return label
    }()
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .label
        label.textColor = Asset.Colors.hightLight.color
        label.text = "Alice"
        return label
    }()
    
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.text = "@alice"
        return label
    }()
    
    let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textAlignment = .right
        label.textColor = .secondaryLabel
        label.text = "1d"
        return label
    }()
    
    let moreMenuButton: UIButton = {
        let button = UIButton()
        button.setImage(Asset.Arrows.tablerChevronDown.image.withRenderingMode(.alwaysTemplate), for: .normal)
        button.imageView?.tintColor = .secondaryLabel
        return button
    }()
    
    let activeTextLabel: ActiveLabel = {
        let label = ActiveLabel()
        label.numberOfLines = 0
        label.enabledTypes = [.mention, .hashtag, .url]
        label.textColor = .label
        label.font = .systemFont(ofSize: 14)
        label.text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
        return label
    }()
    
    let replyButton: UIButton = {
        let button = UIButton()
        button.imageView?.tintColor = .secondaryLabel
        button.setImage(Asset.Communication.mdiMessageReply.image.withRenderingMode(.alwaysTemplate), for: .normal)
        button.titleLabel?.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        button.setTitle(HomeTimelineTableViewCell.formattedNumberTitleForButton(nil), for: .normal)
        button.setTitleColor(.secondaryLabel, for: .normal)
        button.setInsets(forContentPadding: .zero, imageTitlePadding: HomeTimelineTableViewCell.buttonTitleImagePadding)
        return button
    }()
    
    let retweetButton: UIButton = {
        let button = UIButton()
        button.imageView?.tintColor = .secondaryLabel
        button.setImage(Asset.Arrows.mdiTwitterRetweet.image.withRenderingMode(.alwaysTemplate), for: .normal)
        button.titleLabel?.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        button.setTitle(HomeTimelineTableViewCell.formattedNumberTitleForButton(nil), for: .normal)
        button.setTitleColor(.secondaryLabel, for: .normal)
        button.setInsets(forContentPadding: .zero, imageTitlePadding: HomeTimelineTableViewCell.buttonTitleImagePadding)
        return button
    }()
    
    let favoriteButton: UIButton = {
        let button = UIButton()
        button.setImage(Asset.Health.icRoundFavoritePath.image.withRenderingMode(.alwaysTemplate), for: .normal)
        button.imageView?.tintColor = .secondaryLabel
        button.titleLabel?.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        button.setTitle(HomeTimelineTableViewCell.formattedNumberTitleForButton(nil), for: .normal)
        button.setTitleColor(.secondaryLabel, for: .normal)
        button.setInsets(forContentPadding: .zero, imageTitlePadding: HomeTimelineTableViewCell.buttonTitleImagePadding)
        return button
    }()
    
    let shareButton: UIButton = {
        let button = UIButton()
        button.imageView?.tintColor = .secondaryLabel
        button.setImage(Asset.ObjectTools.icRoundShare.image.withRenderingMode(.alwaysTemplate), for: .normal)
        return button
    }()
    
    override func prepareForReuse() {
        super.prepareForReuse()        
        avatarImageView.af.cancelImageRequest()
        dateLabelUpdateSubscription = nil
        disposeBag.removeAll()
        
        replyButton.setTitle(HomeTimelineTableViewCell.formattedNumberTitleForButton(nil), for: .normal)
        retweetButton.setTitle(HomeTimelineTableViewCell.formattedNumberTitleForButton(nil), for: .normal)
        favoriteButton.setTitle(HomeTimelineTableViewCell.formattedNumberTitleForButton(nil), for: .normal)
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
    static func formattedNumberTitleForButton(_ number: Int?) -> String {
        guard let number = number, number > 0 else {
            return Array(repeating: " ", count: 5).joined()
        }
        
        guard number < 10000 else {
            return "9999+"
        }
        
        let string = String(number)
        let paddingCount = 5 - string.count
        return string + Array(repeating: " ", count: paddingCount).joined()
    }
}

extension HomeTimelineTableViewCell {
    
    private func _init() {
        selectionStyle = .none
        
        // container
        let containerStackView = UIStackView()
        containerStackView.axis = .vertical
        containerStackView.spacing = 8
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerStackView)
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: HomeTimelineTableViewCell.verticalMargin),
            containerStackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            contentView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: containerStackView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: containerStackView.bottomAnchor, constant: HomeTimelineTableViewCell.verticalMargin),
        ])
        
        // retweet container
        containerStackView.addArrangedSubview(retweetContainerStackView)
        retweetContainerStackView.axis = .horizontal
        let retweetContainerContentView = UIView()
        retweetContainerStackView.addArrangedSubview(retweetContainerContentView)
        
        retweetInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        retweetContainerContentView.addSubview(retweetInfoLabel)
        NSLayoutConstraint.activate([
            retweetInfoLabel.topAnchor.constraint(equalTo: retweetContainerContentView.topAnchor),
            retweetContainerContentView.trailingAnchor.constraint(equalTo: retweetInfoLabel.trailingAnchor),
            retweetContainerContentView.bottomAnchor.constraint(equalTo: retweetInfoLabel.bottomAnchor),
        ])
        
        retweetIconImageView.translatesAutoresizingMaskIntoConstraints = false
        retweetContainerContentView.addSubview(retweetIconImageView)
        NSLayoutConstraint.activate([
            retweetIconImageView.centerYAnchor.constraint(equalTo: retweetInfoLabel.centerYAnchor),
            retweetIconImageView.widthAnchor.constraint(equalToConstant: 12),
            retweetIconImageView.heightAnchor.constraint(equalToConstant: 12),
        ])
        
        // tweet container: [avatar | main container]
        let tweetContainerStackView = UIStackView()
        containerStackView.addArrangedSubview(tweetContainerStackView)
        tweetContainerStackView.axis = .horizontal
        tweetContainerStackView.alignment = .top
        tweetContainerStackView.spacing = 10
        
        // user avatar
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        tweetContainerStackView.addArrangedSubview(avatarImageView)
        NSLayoutConstraint.activate([
            avatarImageView.widthAnchor.constraint(equalToConstant: HomeTimelineTableViewCell.avatarImageViewSize.width),
            avatarImageView.heightAnchor.constraint(equalToConstant: HomeTimelineTableViewCell.avatarImageViewSize.height).priority(.defaultHigh),
        ])
        
        // main container
        let tweetMainContainerStackView = UIStackView()
        tweetContainerStackView.addArrangedSubview(tweetMainContainerStackView)
        tweetMainContainerStackView.axis = .vertical
        
        // meta info: name | username | date | menu button |
        let tweetMetaInfoContainerStackView = UIStackView()
        tweetMainContainerStackView.addArrangedSubview(tweetMetaInfoContainerStackView)
        tweetMetaInfoContainerStackView.axis = .horizontal
        tweetMetaInfoContainerStackView.alignment = .center
        tweetMetaInfoContainerStackView.spacing = 6
        tweetMetaInfoContainerStackView.addArrangedSubview(nameLabel)
        tweetMetaInfoContainerStackView.addArrangedSubview(usernameLabel)
        tweetMetaInfoContainerStackView.addArrangedSubview(dateLabel)
        moreMenuButton.translatesAutoresizingMaskIntoConstraints = false
        tweetMetaInfoContainerStackView.addArrangedSubview(moreMenuButton)
        NSLayoutConstraint.activate([
            moreMenuButton.widthAnchor.constraint(equalToConstant: 16),
            moreMenuButton.heightAnchor.constraint(equalToConstant: 16),
        ])
        nameLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        usernameLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        usernameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        dateLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        dateLabel.setContentCompressionResistancePriority(.required - 2, for: .horizontal)
        shareButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        shareButton.setContentCompressionResistancePriority(.required - 1, for: .horizontal)
        
        // align retweet leading to name
        NSLayoutConstraint.activate([
            retweetInfoLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            retweetIconImageView.trailingAnchor.constraint(equalTo: avatarImageView.trailingAnchor),
        ])
        
        // tweet text
        tweetMainContainerStackView.addArrangedSubview(activeTextLabel)
    
        // tweet panel container
        tweetMainContainerStackView.addArrangedSubview(tweetPanelContainerStackView)
        tweetPanelContainerStackView.axis = .vertical
        tweetPanelContainerStackView.distribution = .fill
        
        let paddingView = UIView()
        paddingView.translatesAutoresizingMaskIntoConstraints = false
        tweetMainContainerStackView.addArrangedSubview(paddingView)
        NSLayoutConstraint.activate([
            paddingView.heightAnchor.constraint(equalToConstant: 12).priority(.defaultHigh),
        ])
        tweetPanelContainerStackView.addArrangedSubview(paddingView)

        let tweetPanelContentContainerStackView = UIStackView()
        tweetPanelContainerStackView.addArrangedSubview(tweetPanelContentContainerStackView)
        tweetPanelContentContainerStackView.axis = .horizontal
        tweetPanelContentContainerStackView.distribution = .equalSpacing

        tweetPanelContentContainerStackView.addArrangedSubview(replyButton)
        tweetPanelContentContainerStackView.addArrangedSubview(retweetButton)
        tweetPanelContentContainerStackView.addArrangedSubview(favoriteButton)
        tweetPanelContentContainerStackView.addArrangedSubview(shareButton)
        
        
        let separatorLine = UIView.separatorLine
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separatorLine)
        NSLayoutConstraint.activate([
            separatorLine.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            contentView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: separatorLine.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: separatorLine.bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: UIView.separatorLineHeight(of: separatorLine))
        ])
        
        // default hide panel
        tweetPanelContainerStackView.isHidden = true
    }
    
}

#if DEBUG
import SwiftUI

struct HomeTimelineTableViewCell_Previews: PreviewProvider {
    static var avatarImage: UIImage {
        UIImage(named: "patrick-perkins")!
            .af.imageRoundedIntoCircle()
    }
    
    static var previews: some View {
        Group {
            UIViewPreview {
                let cell = HomeTimelineTableViewCell()
                cell.avatarImageView.image = avatarImage
                cell.retweetContainerStackView.isHidden = true
                return cell
            }
            .previewDisplayName("Normal")
            .previewLayout(.fixed(width: 375, height: 200))
            UIViewPreview {
                let cell = HomeTimelineTableViewCell()
                cell.avatarImageView.image = avatarImage
                cell.retweetContainerStackView.isHidden = true
                cell.tweetPanelContainerStackView.isHidden = false
                return cell
            }
            .previewDisplayName("Expand")
            .previewLayout(.fixed(width: 375, height: 200))
            UIViewPreview {
                let cell = HomeTimelineTableViewCell()
                cell.avatarImageView.image = avatarImage
                return cell
            }
            .previewDisplayName("Retweet")
            .previewLayout(.fixed(width: 375, height: 200))
            UIViewPreview {
                let cell = HomeTimelineTableViewCell()
                cell.avatarImageView.image = avatarImage
                cell.favoriteButton.imageView?.tintColor = Asset.Colors.heartPink.color
                cell.favoriteButton.setImage(Asset.Health.icRoundFavorite.image.withRenderingMode(.alwaysTemplate), for: .normal)
                return cell
            }
            .previewDisplayName("Dark + Favorite")
            .preferredColorScheme(.dark)
            .previewLayout(.fixed(width: 375, height: 200))
        }
    }
}
#endif
