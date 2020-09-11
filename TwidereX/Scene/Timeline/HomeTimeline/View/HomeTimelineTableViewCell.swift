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
    
    let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    
    let retweetContainerStackView = UIStackView()

    let retweetIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .secondaryLabel
        imageView.image = UIImage(systemName: "arrow.2.squarepath") // Asset.Arrows.arrow2Squarepath.image
        return imageView
    }()
    
    let retweetInfoLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.text = "Bob Retweeted"
        return label
    }()
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .label
        label.text = "Alice"
        return label
    }()
    
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .secondaryLabel
        label.text = "@alice"
        return label
    }()
    
    let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textAlignment = .right
        label.textColor = .secondaryLabel
        label.text = "1d"
        return label
    }()
    
    let activeTextLabel: ActiveLabel = {
        let label = ActiveLabel()
        label.numberOfLines = 0
        label.enabledTypes = [.mention, .hashtag, .url]
        label.textColor = .label
        label.text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
        return label
    }()
    
    let replyButton: UIButton = {
        let button = UIButton()
        button.imageView?.tintColor = .secondaryLabel
        button.setImage(UIImage(systemName: "arrowshape.turn.up.left"), for: .normal)
        button.titleLabel?.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        button.setTitle(HomeTimelineTableViewCell.formattedNumberTitleForButton(nil), for: .normal)
        button.setTitleColor(.secondaryLabel, for: .normal)
        button.setInsets(forContentPadding: .zero, imageTitlePadding: HomeTimelineTableViewCell.buttonTitleImagePadding)
        return button
    }()
    
    let retweetButton: UIButton = {
        let button = UIButton()
        button.imageView?.tintColor = .secondaryLabel
        button.setImage(UIImage(systemName: "arrow.2.squarepath"), for: .normal)
        button.titleLabel?.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        button.setTitle(HomeTimelineTableViewCell.formattedNumberTitleForButton(nil), for: .normal)
        button.setTitleColor(.secondaryLabel, for: .normal)
        button.setInsets(forContentPadding: .zero, imageTitlePadding: HomeTimelineTableViewCell.buttonTitleImagePadding)
        return button
    }()
    
    let favoriteButton: UIButton = {
        let button = UIButton()
        button.imageView?.tintColor = .secondaryLabel
        button.setImage(UIImage(systemName: "heart"), for: .normal)
        button.titleLabel?.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        button.setTitle(HomeTimelineTableViewCell.formattedNumberTitleForButton(nil), for: .normal)
        button.setTitleColor(.secondaryLabel, for: .normal)
        button.setInsets(forContentPadding: .zero, imageTitlePadding: HomeTimelineTableViewCell.buttonTitleImagePadding)
        return button
    }()
    
    let moreButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        button.imageView?.tintColor = .secondaryLabel
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
        
        let tweetMetaInfoContainerStackView = UIStackView()
        tweetMainContainerStackView.addArrangedSubview(tweetMetaInfoContainerStackView)
        tweetMetaInfoContainerStackView.axis = .horizontal
        tweetMetaInfoContainerStackView.alignment = .firstBaseline
        tweetMetaInfoContainerStackView.spacing = 10
        tweetMetaInfoContainerStackView.addArrangedSubview(nameLabel)
        tweetMetaInfoContainerStackView.addArrangedSubview(usernameLabel)
        tweetMetaInfoContainerStackView.addArrangedSubview(dateLabel)
        nameLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        usernameLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        usernameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        dateLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        dateLabel.setContentCompressionResistancePriority(.required - 1, for: .horizontal)
        
        // align retweet leading to name
        NSLayoutConstraint.activate([
            retweetInfoLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            retweetIconImageView.trailingAnchor.constraint(equalTo: avatarImageView.trailingAnchor),
        ])
        
        // tweet text
        tweetMainContainerStackView.addArrangedSubview(activeTextLabel)
        
        let paddingView = UIView()
        paddingView.translatesAutoresizingMaskIntoConstraints = false
        tweetMainContainerStackView.addArrangedSubview(paddingView)
        NSLayoutConstraint.activate([
            paddingView.heightAnchor.constraint(equalToConstant: 12).priority(.defaultHigh),
        ])
        
        // tweet panel container
        let tweetPanelContainerStackView = UIStackView()
        tweetMainContainerStackView.addArrangedSubview(tweetPanelContainerStackView)
        tweetPanelContainerStackView.axis = .horizontal
        tweetPanelContainerStackView.distribution = .equalSpacing
        
        tweetPanelContainerStackView.addArrangedSubview(replyButton)
        tweetPanelContainerStackView.addArrangedSubview(retweetButton)
        tweetPanelContainerStackView.addArrangedSubview(favoriteButton)
        tweetPanelContainerStackView.addArrangedSubview(moreButton)
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
                return cell
            }
            .previewDisplayName("Retweet")
            .previewLayout(.fixed(width: 375, height: 200))
            UIViewPreview {
                let cell = HomeTimelineTableViewCell()
                cell.avatarImageView.image = avatarImage
                return cell
            }
            .previewDisplayName("Dark")
            .preferredColorScheme(.dark)
            .previewLayout(.fixed(width: 375, height: 200))
        }
    }
}
#endif
