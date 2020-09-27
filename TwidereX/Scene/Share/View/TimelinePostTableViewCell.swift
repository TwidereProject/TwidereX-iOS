//
//  TimelinePostTableViewCell.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-3.
//

import os.log
import UIKit
import Combine
import AlamofireImage
import ActiveLabel

protocol TimelinePostTableViewCellDelegate: class {
    func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, retweetInfoLabelDidPressed label: UILabel)
    func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, avatarImageViewDidPressed imageView: UIImageView)
    func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, quoteAvatarImageViewDidPressed imageView: UIImageView)
}

final class TimelinePostTableViewCell: UITableViewCell {

    static let verticalMargin: CGFloat = 8
    
    weak var delegate: TimelinePostTableViewCellDelegate?
    
    var disposeBag = Set<AnyCancellable>()
    var dateLabelUpdateSubscription: AnyCancellable?
    var quoteDateLabelUpdateSubscription: AnyCancellable?
    
    let timelinePostView = TimelinePostView()
    var separatorLineLeadingLayoutConstraint: NSLayoutConstraint!
    var separatorLineIndentLeadingLayoutConstraint: NSLayoutConstraint!
    
    private let avatarImageViewTapGestureRecognizer: UITapGestureRecognizer = {
        let tapGestureRecognizer = UITapGestureRecognizer()
        tapGestureRecognizer.numberOfTapsRequired = 1
        tapGestureRecognizer.numberOfTouchesRequired = 1
        return tapGestureRecognizer
    }()
    private let retweetInfoLabelTapGestureRecognizer: UITapGestureRecognizer = {
        let tapGestureRecognizer = UITapGestureRecognizer()
        tapGestureRecognizer.numberOfTapsRequired = 1
        tapGestureRecognizer.numberOfTouchesRequired = 1
        return tapGestureRecognizer
    }()
    private let quoteAvatarImageViewTapGestureRecognizer: UITapGestureRecognizer = {
        let tapGestureRecognizer = UITapGestureRecognizer()
        tapGestureRecognizer.numberOfTapsRequired = 1
        tapGestureRecognizer.numberOfTouchesRequired = 1
        return tapGestureRecognizer
    }()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        timelinePostView.mosaicImageView.reset()
        timelinePostView.mosaicImageView.isHidden = true
        timelinePostView.quotePostView.isHidden = true
        timelinePostView.avatarImageView.af.cancelImageRequest()
        disposeBag.removeAll()
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
        timelinePostView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(timelinePostView)
        NSLayoutConstraint.activate([
            timelinePostView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: TimelinePostTableViewCell.verticalMargin),
            timelinePostView.leadingAnchor.constraint(equalTo:  contentView.layoutMarginsGuide.leadingAnchor),
            contentView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: timelinePostView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: timelinePostView.bottomAnchor),    // use action toolbar margin 
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
            separatorLine.heightAnchor.constraint(equalToConstant: UIView.separatorLineHeight(of: separatorLine)),
        ])
        
        retweetInfoLabelTapGestureRecognizer.addTarget(self, action: #selector(TimelinePostTableViewCell.retweetInfoLabelTapGestureRecognizerHandler(_:)))
        timelinePostView.retweetInfoLabel.isUserInteractionEnabled = true
        timelinePostView.retweetInfoLabel.addGestureRecognizer(retweetInfoLabelTapGestureRecognizer)
        
        avatarImageViewTapGestureRecognizer.addTarget(self, action: #selector(TimelinePostTableViewCell.avatarImageViewTapGestureRecognizerHandler(_:)))
        timelinePostView.avatarImageView.isUserInteractionEnabled = true
        timelinePostView.avatarImageView.addGestureRecognizer(avatarImageViewTapGestureRecognizer)
        
        quoteAvatarImageViewTapGestureRecognizer.addTarget(self, action: #selector(TimelinePostTableViewCell.quoteAvatarImageViewTapGestureRecognizerHandler(_:)))
        timelinePostView.quotePostView.avatarImageView.isUserInteractionEnabled = true
        timelinePostView.quotePostView.avatarImageView.addGestureRecognizer(quoteAvatarImageViewTapGestureRecognizer)
    }
    
}

extension TimelinePostTableViewCell {
    
    @objc private func retweetInfoLabelTapGestureRecognizerHandler(_ sender: UITapGestureRecognizer) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        guard sender.state == .ended else { return }
        assert(delegate != nil)
        delegate?.timelinePostTableViewCell(self, retweetInfoLabelDidPressed: timelinePostView.retweetInfoLabel)
    }
    
    @objc private func avatarImageViewTapGestureRecognizerHandler(_ sender: UITapGestureRecognizer) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        guard sender.state == .ended else { return }
        assert(delegate != nil)
        delegate?.timelinePostTableViewCell(self, avatarImageViewDidPressed: timelinePostView.avatarImageView)
    }
    
    @objc private func quoteAvatarImageViewTapGestureRecognizerHandler(_ sender: UITapGestureRecognizer) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        guard sender.state == .ended else { return }
        assert(delegate != nil)
        delegate?.timelinePostTableViewCell(self, quoteAvatarImageViewDidPressed: timelinePostView.quotePostView.avatarImageView)
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
