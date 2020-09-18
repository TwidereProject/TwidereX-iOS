//
//  TimelinePostTableViewCell.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-3.
//

import UIKit
import Combine
import AlamofireImage
import ActiveLabel

final class TimelinePostTableViewCell: UITableViewCell {

    static let verticalMargin: CGFloat = 8
//    static let tweetImageContainerStackViewDefaultHeight: CGFloat = 160
//    static let tweetImageContainerStackViewMaxHeight: CGFloat = UIScreen.main.bounds.width * 0.8
    
    var disposeBag = Set<AnyCancellable>()
    var dateLabelUpdateSubscription: AnyCancellable?
    var quoteDateLabelUpdateSubscription: AnyCancellable?
    
    let timelinePostView = TimelinePostView()
    var separatorLineLeadingLayoutConstraint: NSLayoutConstraint!
    var separatorLineIndentLeadingLayoutConstraint: NSLayoutConstraint!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        timelinePostView.mosaicImageView.reset()
        timelinePostView.mosaicImageView.isHidden = true
        timelinePostView.quotePostView.isHidden = true
        
        timelinePostView.actionToolbar.alpha = 0
        timelinePostView.actionToolbar.isHidden = true
//        avatarImageView.af.cancelImageRequest()
//        dateLabelUpdateSubscription = nil
//        disposeBag.removeAll()
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

extension TimelinePostTableViewCell {
    
    private func _init() {
        selectionStyle = .none
        contentView.backgroundColor = .systemBackground
        
        timelinePostView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(timelinePostView)
        NSLayoutConstraint.activate([
            timelinePostView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: TimelinePostTableViewCell.verticalMargin),
            timelinePostView.leadingAnchor.constraint(equalTo:  contentView.layoutMarginsGuide.leadingAnchor),
            contentView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: timelinePostView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: timelinePostView.bottomAnchor, constant: TimelinePostTableViewCell.verticalMargin),
        ])
        
        let separatorLine = UIView.separatorLine
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        separatorLineLeadingLayoutConstraint = separatorLine.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor)
        separatorLineIndentLeadingLayoutConstraint = separatorLine.leadingAnchor.constraint(equalTo: timelinePostView.nameLabel.leadingAnchor)
        contentView.addSubview(separatorLine)
        NSLayoutConstraint.activate([
            separatorLineIndentLeadingLayoutConstraint,
            contentView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: separatorLine.trailingAnchor),
            separatorLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: UIView.separatorLineHeight(of: separatorLine))
        ])
        
        timelinePostView.actionToolbar.alpha = 0
        timelinePostView.actionToolbar.isHidden = true
    }
    
}

#if DEBUG
import SwiftUI

struct TimelinePostTableViewCell_Previews: PreviewProvider {
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
            UIViewPreview {
                let cell = TimelinePostTableViewCell()
                cell.timelinePostView.avatarImageView.image = avatarImage
                cell.timelinePostView.retweetContainerStackView.isHidden = false
                let images = MosaicImageView_Previews.images.prefix(3)
                let imageViews = cell.timelinePostView.mosaicImageView.setupImageViews(count: images.count, maxHeight: 162)
                for (i, imageView) in imageViews.enumerated() {
                    imageView.image = images[i]
                }
                cell.timelinePostView.mosaicImageView.isHidden = false
                cell.timelinePostView.quotePostView.avatarImageView.image = avatarImage2
                cell.timelinePostView.quotePostView.nameLabel.text = "Bob"
                cell.timelinePostView.quotePostView.usernameLabel.text = "@bob"
                cell.timelinePostView.quotePostView.isHidden = false
                return cell
            }
            .previewDisplayName("Normal")
            .previewLayout(.sizeThatFits)
        }
    }
}
#endif
