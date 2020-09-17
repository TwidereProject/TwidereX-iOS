//
//  TweetPostDetailTableViewCell.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-16.
//

import UIKit
import Combine
import AlamofireImage
import ActiveLabel

final class TweetPostDetailTableViewCell: UITableViewCell {
    
    static let verticalMargin: CGFloat = 8
    static let avatarImageViewSize = CGSize(width: 44, height: 44)
    //static let buttonTitleImagePadding: CGFloat = 4
    //static let tweetImageContainerStackViewDefaultHeight: CGFloat = 160
    //static let tweetImageContainerStackViewMaxHeight: CGFloat = UIScreen.main.bounds.width * 0.8
    
    var disposeBag = Set<AnyCancellable>()
    var dateLabelUpdateSubscription: AnyCancellable?
    var quoteDateLabelUpdateSubscription: AnyCancellable?
    
    let tweetImageContainerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.layer.masksToBounds = true
        stackView.layer.cornerRadius = 8
        stackView.distribution = .fillEqually
        return stackView
    }()
    var tweetImageContainerStackViewHeightLayoutConstraint: NSLayoutConstraint!
    let tweetQuoteContainerStackView = UIStackView()
    let tweetGeoMetaContainerStackView = UIStackView()
    let tweetPanelContainerStackView = UIStackView()
    
    let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .regular)
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
    
    let geoIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .secondaryLabel
        imageView.image = Asset.ObjectTools.icRoundLocationOn.image.withRenderingMode(.alwaysTemplate)
        return imageView
    }()
    
    let geoLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.text = "Earth, Galaxy"
        return label

    }()
    
    let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.text = "2020/01/01 00:00 PM"
        return label
    }()
    
    let sourceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textAlignment = .right
        label.textColor = Asset.Colors.hightLight.color
        label.text = "Twitter App"
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
    
    let quotePostView = QuotePostView()
    
//    let replyButton: UIButton = {
//        let button = UIButton()
//        button.imageView?.tintColor = .secondaryLabel
//        button.setImage(Asset.Communication.mdiMessageReply.image.withRenderingMode(.alwaysTemplate), for: .normal)
//        button.titleLabel?.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
//        button.setTitle(TweetPostTimelineTableViewCell.formattedNumberTitleForButton(nil), for: .normal)
//        button.setTitleColor(.secondaryLabel, for: .normal)
//        button.setInsets(forContentPadding: .zero, imageTitlePadding: TweetPostTimelineTableViewCell.buttonTitleImagePadding)
//        return button
//    }()
//
//    let retweetButton: UIButton = {
//        let button = UIButton()
//        button.imageView?.tintColor = .secondaryLabel
//        button.setImage(Asset.Arrows.mdiTwitterRetweet.image.withRenderingMode(.alwaysTemplate), for: .normal)
//        button.titleLabel?.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
//        button.setTitle(TweetPostTimelineTableViewCell.formattedNumberTitleForButton(nil), for: .normal)
//        button.setTitleColor(.secondaryLabel, for: .normal)
//        button.setInsets(forContentPadding: .zero, imageTitlePadding: TweetPostTimelineTableViewCell.buttonTitleImagePadding)
//        return button
//    }()
//
//    let favoriteButton: UIButton = {
//        let button = UIButton()
//        button.setImage(Asset.Health.icRoundFavoritePath.image.withRenderingMode(.alwaysTemplate), for: .normal)
//        button.imageView?.tintColor = .secondaryLabel
//        button.titleLabel?.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
//        button.setTitle(TweetPostTimelineTableViewCell.formattedNumberTitleForButton(nil), for: .normal)
//        button.setTitleColor(.secondaryLabel, for: .normal)
//        button.setInsets(forContentPadding: .zero, imageTitlePadding: TweetPostTimelineTableViewCell.buttonTitleImagePadding)
//        return button
//    }()
//
//    let shareButton: UIButton = {
//        let button = UIButton()
//        button.imageView?.tintColor = .secondaryLabel
//        button.setImage(Asset.ObjectTools.icRoundShare.image.withRenderingMode(.alwaysTemplate), for: .normal)
//        return button
//    }()
    
    override func prepareForReuse() {
        super.prepareForReuse()
//        avatarImageView.af.cancelImageRequest()
//        dateLabelUpdateSubscription = nil
//        disposeBag.removeAll()
//
//        replyButton.setTitle(TweetPostTimelineTableViewCell.formattedNumberTitleForButton(nil), for: .normal)
//        retweetButton.setTitle(TweetPostTimelineTableViewCell.formattedNumberTitleForButton(nil), for: .normal)
//        favoriteButton.setTitle(TweetPostTimelineTableViewCell.formattedNumberTitleForButton(nil), for: .normal)
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

extension TweetPostDetailTableViewCell {
    
    private func _init() {
        selectionStyle = .none
        contentView.backgroundColor = .systemBackground
        
    //        // container: [user container | main container | meta container | panel container]
    //        let containerStackView = UIStackView()
    //        containerStackView.axis = .vertical
    //        containerStackView.spacing = 8
    //        containerStackView.translatesAutoresizingMaskIntoConstraints = false
    //        contentView.addSubview(containerStackView)
    //        NSLayoutConstraint.activate([
    //            containerStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: TweetPostTimelineTableViewCell.verticalMargin),
    //            containerStackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
    //            contentView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: containerStackView.trailingAnchor),
    //            contentView.bottomAnchor.constraint(equalTo: containerStackView.bottomAnchor, constant: TweetPostTimelineTableViewCell.verticalMargin),
    //        ])
    //        
    //        // user container: [userAvatar | userMeta]
    //        let userContainerStackView = UIStackView()
    //        containerStackView.addArrangedSubview(userContainerStackView)
    //        userContainerStackView.axis = .horizontal
    //        userContainerStackView.alignment = .top
    //        userContainerStackView.spacing = 10
    //
    //        // user avatar
    //        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
    //        userContainerStackView.addArrangedSubview(avatarImageView)
    //        NSLayoutConstraint.activate([
    //            avatarImageView.widthAnchor.constraint(equalToConstant: TweetPostTimelineTableViewCell.avatarImageViewSize.width),
    //            avatarImageView.heightAnchor.constraint(equalToConstant: TweetPostTimelineTableViewCell.avatarImageViewSize.height).priority(.defaultHigh),
    //        ])
    //        
    //        // user meta container: [name Meta | username]
    //        let userMetaContainer = UIStackView()
    //        userContainerStackView.addArrangedSubview(userMetaContainer)
    //        userMetaContainer.axis = .vertical
    //        
    //        // name container
    //        let nameMetaContainer = UIStackView()
    //        userMetaContainer.addArrangedSubview(nameMetaContainer)
    //        nameMetaContainer.axis = .horizontal
    //        nameMetaContainer.addArrangedSubview(nameLabel)
    //        nameMetaContainer.addArrangedSubview(moreMenuButton)
    //        
    //        // username
    //        userMetaContainer.addArrangedSubview(usernameLabel)
    //
    //        // main container: [tweet text | image | quote]
    //        let mainContainerStackView = UIStackView()
    //        containerStackView.addArrangedSubview(mainContainerStackView)
    //        mainContainerStackView.axis = .vertical
    //        
    //        // tweet text
    //        mainContainerStackView.addArrangedSubview(activeTextLabel)
    //        
    //        // tweet image
    //        tweetImageContainerStackView.translatesAutoresizingMaskIntoConstraints = false
    //        tweetImageContainerStackViewHeightLayoutConstraint = tweetImageContainerStackView.heightAnchor.constraint(equalToConstant: 162).priority(.required - 1)
    //        containerStackView.addArrangedSubview(tweetImageContainerStackView)
    //        NSLayoutConstraint.activate([
    //            tweetImageContainerStackViewHeightLayoutConstraint,
    //        ])
    //        tweetImageContainerStackView.setContentHuggingPriority(.defaultHigh, for: .vertical)
    //        
    //        // tweet quote
    ////        tweetMainContainerStackView.addArrangedSubview(tweetQuoteContainerStackView)
    ////        tweetQuoteContainerStackView.axis = .vertical
    ////
    ////
    ////        tweetQuoteContainerStackView.addArrangedSubview(quoteTopPaddingView)
    ////
    ////        quoteView.translatesAutoresizingMaskIntoConstraints = false
    ////        tweetQuoteContainerStackView.addArrangedSubview(quoteView)
    //        
    //        // meta container: [geo meta | date meta | status meta]
    //        let metaContainerStackView = UIStackView()
    //        containerStackView.addArrangedSubview(metaContainerStackView)
    //        metaContainerStackView.axis = .vertical
    //        metaContainerStackView.spacing = 8
    //        metaContainerStackView.alignment = .center
    //        
    //        // top padding for meta container
    //        let metaContainerStackViewTopPadding = UIView()
    //        metaContainerStackViewTopPadding.translatesAutoresizingMaskIntoConstraints = false
    //        metaContainerStackView.addArrangedSubview(metaContainerStackViewTopPadding)
    //        NSLayoutConstraint.activate([
    //            metaContainerStackViewTopPadding.heightAnchor.constraint(equalToConstant: 4).priority(.defaultHigh),
    //        ])
    //        
    //        // geo meta container: [geo icon | geo]
    //        metaContainerStackView.addArrangedSubview(tweetGeoMetaContainerStackView)
    //        tweetGeoMetaContainerStackView.axis = .horizontal
    //        tweetGeoMetaContainerStackView.spacing = 6
    //        tweetGeoMetaContainerStackView.addArrangedSubview(geoIconImageView)
    //        tweetGeoMetaContainerStackView.addArrangedSubview(geoLabel)
    //        
    //        // date meta container: [date | source]
    //        let dateMetaContainer = UIStackView()
    //        metaContainerStackView.addArrangedSubview(dateMetaContainer)
    //        dateMetaContainer.axis = .horizontal
    //        dateMetaContainer.spacing = 8
    //        dateMetaContainer.addArrangedSubview(dateLabel)
    //        dateMetaContainer.addArrangedSubview(sourceLabel)
        
//        let tweetMainContainerStackView = UIStackView()
//        tweetContainerStackView.addArrangedSubview(tweetMainContainerStackView)
//        tweetMainContainerStackView.axis = .vertical
//
//        // meta info: name | username | date | menu button |
//        let tweetMetaInfoContainerStackView = UIStackView()
//        tweetMainContainerStackView.addArrangedSubview(tweetMetaInfoContainerStackView)
//        tweetMetaInfoContainerStackView.axis = .horizontal
//        tweetMetaInfoContainerStackView.alignment = .center
//        tweetMetaInfoContainerStackView.spacing = 6
//        tweetMetaInfoContainerStackView.addArrangedSubview(nameLabel)
//        tweetMetaInfoContainerStackView.addArrangedSubview(usernameLabel)
//        tweetMetaInfoContainerStackView.addArrangedSubview(dateLabel)
//        moreMenuButton.translatesAutoresizingMaskIntoConstraints = false
//        tweetMetaInfoContainerStackView.addArrangedSubview(moreMenuButton)
//        NSLayoutConstraint.activate([
//            moreMenuButton.widthAnchor.constraint(equalToConstant: 16),
//            moreMenuButton.heightAnchor.constraint(equalToConstant: 16),
//        ])
//        nameLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
//        usernameLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
//        usernameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
//        dateLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
//        dateLabel.setContentCompressionResistancePriority(.required - 2, for: .horizontal)
//        shareButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
//        shareButton.setContentCompressionResistancePriority(.required - 1, for: .horizontal)
//
//        // tweet text
//        tweetMainContainerStackView.addArrangedSubview(activeTextLabel)
//
//        // tweet image
//        tweetImageContainerStackView.translatesAutoresizingMaskIntoConstraints = false
//        tweetImageContainerStackViewHeightLayoutConstraint = tweetImageContainerStackView.heightAnchor.constraint(equalToConstant: 162).priority(.required - 1)
//        tweetMainContainerStackView.addArrangedSubview(tweetImageContainerStackView)
//        NSLayoutConstraint.activate([
//            tweetImageContainerStackViewHeightLayoutConstraint,
//        ])
//        tweetImageContainerStackView.setContentHuggingPriority(.defaultHigh, for: .vertical)
//
//        // tweet quote
//        tweetMainContainerStackView.addArrangedSubview(tweetQuoteContainerStackView)
//        tweetQuoteContainerStackView.axis = .vertical
//
//        let quoteTopPaddingView = UIView()
//        quoteTopPaddingView.translatesAutoresizingMaskIntoConstraints = false
//        tweetMainContainerStackView.addArrangedSubview(quoteTopPaddingView)
//        NSLayoutConstraint.activate([
//            quoteTopPaddingView.heightAnchor.constraint(equalToConstant: 8).priority(.defaultHigh),
//        ])
//        tweetQuoteContainerStackView.addArrangedSubview(quoteTopPaddingView)
//
//        quoteView.translatesAutoresizingMaskIntoConstraints = false
//        tweetQuoteContainerStackView.addArrangedSubview(quoteView)
//
//        // tweet panel container
//        tweetMainContainerStackView.addArrangedSubview(tweetPanelContainerStackView)
//        tweetPanelContainerStackView.axis = .vertical
//        tweetPanelContainerStackView.distribution = .fill
//
//        let panelTopPaddingView = UIView()
//        panelTopPaddingView.translatesAutoresizingMaskIntoConstraints = false
//        tweetMainContainerStackView.addArrangedSubview(panelTopPaddingView)
//        NSLayoutConstraint.activate([
//            panelTopPaddingView.heightAnchor.constraint(equalToConstant: 12).priority(.defaultHigh),
//        ])
//        tweetPanelContainerStackView.addArrangedSubview(panelTopPaddingView)
//
//        let tweetPanelContentContainerStackView = UIStackView()
//        tweetPanelContainerStackView.addArrangedSubview(tweetPanelContentContainerStackView)
//        tweetPanelContentContainerStackView.axis = .horizontal
//        tweetPanelContentContainerStackView.distribution = .equalSpacing
//
//        tweetPanelContentContainerStackView.addArrangedSubview(replyButton)
//        tweetPanelContentContainerStackView.addArrangedSubview(retweetButton)
//        tweetPanelContentContainerStackView.addArrangedSubview(favoriteButton)
//        tweetPanelContentContainerStackView.addArrangedSubview(shareButton)
        
//        let separatorLine = UIView.separatorLine
//        separatorLine.translatesAutoresizingMaskIntoConstraints = false
//        separatorLineLeadingLayoutConstraint = separatorLine.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor)
//        separatorLineIndentLeadingLayoutConstraint = separatorLine.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor)
//        contentView.addSubview(separatorLine)
//        NSLayoutConstraint.activate([
//            separatorLineIndentLeadingLayoutConstraint,
//            contentView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: separatorLine.trailingAnchor),
//            contentView.bottomAnchor.constraint(equalTo: separatorLine.bottomAnchor),
//            separatorLine.heightAnchor.constraint(equalToConstant: UIView.separatorLineHeight(of: separatorLine))
//        ])
        
        // default hide image, quote, panel
        tweetImageContainerStackView.isHidden = true
        tweetQuoteContainerStackView.isHidden = true
        tweetGeoMetaContainerStackView.isHidden = true
        tweetPanelContainerStackView.isHidden = true
    }
    
}

#if DEBUG
import SwiftUI

struct TweetPostDetailTableViewCell_Previews: PreviewProvider {
    static var avatarImage: UIImage {
        UIImage(named: "patrick-perkins")!
            .af.imageRoundedIntoCircle()
    }
    
    static var avatarImage2: UIImage {
        UIImage(named: "dan-maisey")!
            .af.imageRoundedIntoCircle()
    }
    
    static var photoImageView: UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.image = UIImage(named: "moran")
        return imageView
    }
    
    static var currentDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }
    
    static var previews: some View {
        Group {
            UIViewPreview {
                let cell = TweetPostDetailTableViewCell()
                cell.avatarImageView.image = avatarImage
                cell.dateLabel.text = currentDateFormatted
                return cell
            }
            .previewDisplayName("Normal")
            .previewLayout(.fixed(width: 375, height: 300))
            UIViewPreview {
                let cell = TweetPostDetailTableViewCell()
                cell.avatarImageView.image = avatarImage
                cell.dateLabel.text = currentDateFormatted
                cell.tweetImageContainerStackView.isHidden = false
                cell.tweetImageContainerStackView.addArrangedSubview(photoImageView)
                return cell
            }
            .previewDisplayName("Image")
            .previewLayout(.fixed(width: 375, height: 400))
        }
    }

}
#endif
