//
//  TimelinePostTableViewCell.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-3.
//

import os.log
import UIKit
import AVKit
import Combine
import ActiveLabel

protocol TimelinePostTableViewCellDelegate: class {
    var playerViewControllerDelegate: AVPlayerViewControllerDelegate? { get }
    func parent() -> UIViewController
    
    func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, retweetInfoLabelDidPressed label: UILabel)
    func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, avatarImageViewDidPressed imageView: UIImageView)
    func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, quoteAvatarImageViewDidPressed imageView: UIImageView)
    func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, quotePostViewDidPressed quotePostView: QuotePostView)
    func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, playerViewControllerDidPressed playerViewController: AVPlayerViewController)
    
    func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, actionToolbar: TimelinePostActionToolbar, replayButtonDidPressed sender: UIButton)
    func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, actionToolbar: TimelinePostActionToolbar, retweetButtonDidPressed sender: UIButton)
    func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, actionToolbar: TimelinePostActionToolbar, favoriteButtonDidPressed sender: UIButton)
    func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, actionToolbar: TimelinePostActionToolbar, shareButtonDidPressed sender: UIButton)
    
    func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, mosaicImageView: MosaicImageView, didTapImageView imageView: UIImageView, atIndex index: Int)
    
    func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, activeLabel: ActiveLabel, didTapEntity entity: ActiveEntity)
}

extension TimelinePostTableViewCellDelegate {
    func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, playerViewControllerDidPressed playerViewController: AVPlayerViewController) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        playerViewController.showsPlaybackControls.toggle()
    }
}

final class TimelinePostTableViewCell: UITableViewCell {
    
    static let verticalMargin: CGFloat = 16         // without retweet indicator
    static let verticalMarginAlt: CGFloat = 8       // with retweet indicator
    
    weak var delegate: TimelinePostTableViewCellDelegate?
    
    var disposeBag = Set<AnyCancellable>()
    var observations = Set<NSKeyValueObservation>()
    var dateLabelUpdateSubscription: AnyCancellable?
    var quoteDateLabelUpdateSubscription: AnyCancellable?
    
    let timelinePostView = TimelinePostView()
    let conversationLinkUpper = UIView.separatorLine
    let conversationLinkLower = UIView.separatorLine
    let separatorLine = UIView.separatorLine

    var timelinePostViewTopLayoutConstraint: NSLayoutConstraint!
    
    var separatorLineNormalLeadingLayoutConstraint: NSLayoutConstraint!
    var separatorLineExpandLeadingLayoutConstraint: NSLayoutConstraint!
    var separatorLineIndentLeadingLayoutConstraint: NSLayoutConstraint!
    
    var separatorLineNormalTrailingLayoutConstraint: NSLayoutConstraint!
    var separatorLineExpandTrailingLayoutConstraint: NSLayoutConstraint!
    
    private let avatarImageViewTapGestureRecognizer = UITapGestureRecognizer.singleTapGestureRecognizer
    private let retweetInfoLabelTapGestureRecognizer = UITapGestureRecognizer.singleTapGestureRecognizer
    private let quoteAvatarImageViewTapGestureRecognizer = UITapGestureRecognizer.singleTapGestureRecognizer
    private let quotePostViewTapGestureRecognizer = UITapGestureRecognizer.singleTapGestureRecognizer
//    private let playerTapGestureRecognizer = UITapGestureRecognizer.singleTapGestureRecognizer
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        timelinePostView.mosaicImageView.reset()
        timelinePostView.mosaicImageView.isHidden = true
        timelinePostView.mosaicPlayerView.reset()
        timelinePostView.mosaicPlayerView.isHidden = true
        timelinePostView.quotePostView.isHidden = true
        timelinePostView.avatarImageView.af.cancelImageRequest()
        timelinePostView.avatarImageView.kf.cancelDownloadTask()
        conversationLinkUpper.isHidden = true
        conversationLinkLower.isHidden = true
        disposeBag.removeAll()
        observations.removeAll()
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
        timelinePostViewTopLayoutConstraint = timelinePostView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: TimelinePostTableViewCell.verticalMargin)
        contentView.addSubview(timelinePostView)
        NSLayoutConstraint.activate([
            timelinePostViewTopLayoutConstraint,
            timelinePostView.leadingAnchor.constraint(equalTo:  contentView.readableContentGuide.leadingAnchor),
            contentView.readableContentGuide.trailingAnchor.constraint(equalTo: timelinePostView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: timelinePostView.bottomAnchor),    // use action toolbar margin 
        ])
        
        conversationLinkUpper.translatesAutoresizingMaskIntoConstraints = false
        conversationLinkLower.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(conversationLinkUpper)
        contentView.addSubview(conversationLinkLower)
        NSLayoutConstraint.activate([
            conversationLinkUpper.topAnchor.constraint(equalTo: contentView.topAnchor),
            conversationLinkUpper.centerXAnchor.constraint(equalTo: timelinePostView.avatarImageView.centerXAnchor),
            timelinePostView.avatarImageView.topAnchor.constraint(equalTo: conversationLinkUpper.bottomAnchor, constant: 2),
            conversationLinkUpper.widthAnchor.constraint(equalToConstant: 1),
            conversationLinkLower.topAnchor.constraint(equalTo: timelinePostView.avatarImageView.bottomAnchor, constant: 2),
            conversationLinkLower.centerXAnchor.constraint(equalTo: timelinePostView.avatarImageView.centerXAnchor),
            contentView.bottomAnchor.constraint(equalTo: conversationLinkLower.bottomAnchor),
            conversationLinkLower.widthAnchor.constraint(equalToConstant: 1),
        ])
        
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        separatorLineNormalLeadingLayoutConstraint = separatorLine.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor)
        separatorLineExpandLeadingLayoutConstraint = separatorLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
        separatorLineIndentLeadingLayoutConstraint = separatorLine.leadingAnchor.constraint(equalTo: timelinePostView.nameLabel.leadingAnchor)
        separatorLineNormalTrailingLayoutConstraint = separatorLine.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor)
        separatorLineExpandTrailingLayoutConstraint = separatorLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        contentView.addSubview(separatorLine)
        NSLayoutConstraint.activate([
            separatorLineIndentLeadingLayoutConstraint,
            separatorLineNormalTrailingLayoutConstraint,
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
        
        quotePostViewTapGestureRecognizer.addTarget(self, action: #selector(TimelinePostTableViewCell.quotePostViewTapGestureRecognizerHandler(_:)))
        timelinePostView.quotePostView.isUserInteractionEnabled = true
        timelinePostView.quotePostView.addGestureRecognizer(quotePostViewTapGestureRecognizer)
                
        timelinePostView.activeTextLabel.delegate = self
        timelinePostView.actionToolbar.delegate = self
        timelinePostView.mosaicImageView.delegate = self
        conversationLinkUpper.isHidden = true
        conversationLinkLower.isHidden = true
    }
    
}

extension TimelinePostTableViewCell {
    
    @objc private func retweetInfoLabelTapGestureRecognizerHandler(_ sender: UITapGestureRecognizer) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        guard sender.state == .ended else { return }
        delegate?.timelinePostTableViewCell(self, retweetInfoLabelDidPressed: timelinePostView.retweetInfoLabel)
    }
    
    @objc private func avatarImageViewTapGestureRecognizerHandler(_ sender: UITapGestureRecognizer) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        guard sender.state == .ended else { return }
        delegate?.timelinePostTableViewCell(self, avatarImageViewDidPressed: timelinePostView.avatarImageView)
    }
    
    @objc private func quoteAvatarImageViewTapGestureRecognizerHandler(_ sender: UITapGestureRecognizer) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        guard sender.state == .ended else { return }
        delegate?.timelinePostTableViewCell(self, quoteAvatarImageViewDidPressed: timelinePostView.quotePostView.avatarImageView)
    }
    
    @objc private func quotePostViewTapGestureRecognizerHandler(_ sender: UITapGestureRecognizer) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        guard sender.state == .ended else { return }
        delegate?.timelinePostTableViewCell(self, quotePostViewDidPressed: timelinePostView.quotePostView)
    }
    
}

// MARK: - ActiveLabelDelegate
extension TimelinePostTableViewCell: ActiveLabelDelegate {
    func activeLabel(_ activeLabel: ActiveLabel, didSelectActiveEntity entity: ActiveEntity) {
        delegate?.timelinePostTableViewCell(self, activeLabel: activeLabel, didTapEntity: entity)
    }
}

// MARK: - TimelinePostActionToolbarDelegate
extension TimelinePostTableViewCell: TimelinePostActionToolbarDelegate {
    
    func timelinePostActionToolbar(_ toolbar: TimelinePostActionToolbar, replayButtonDidPressed sender: UIButton) {
        delegate?.timelinePostTableViewCell(self, actionToolbar: toolbar, replayButtonDidPressed: sender)
    }
    
    func timelinePostActionToolbar(_ toolbar: TimelinePostActionToolbar, retweetButtonDidPressed sender: UIButton) {
        delegate?.timelinePostTableViewCell(self, actionToolbar: toolbar, retweetButtonDidPressed: sender)
    }
    
    func timelinePostActionToolbar(_ toolbar: TimelinePostActionToolbar, favoriteButtonDidPressed sender: UIButton) {
        delegate?.timelinePostTableViewCell(self, actionToolbar: toolbar, favoriteButtonDidPressed: sender)
    }
    
    func timelinePostActionToolbar(_ toolbar: TimelinePostActionToolbar, shareButtonDidPressed sender: UIButton) {
        delegate?.timelinePostTableViewCell(self, actionToolbar: toolbar, shareButtonDidPressed: sender)
    }
    
}

// MARK: - MosaicImageViewDelegate
extension TimelinePostTableViewCell: MosaicImageViewDelegate {
    func mosaicImageView(_ mosaicImageView: MosaicImageView, didTapImageView imageView: UIImageView, atIndex index: Int) {
        delegate?.timelinePostTableViewCell(self, mosaicImageView: mosaicImageView, didTapImageView: imageView, atIndex: index)
    }
}

extension TimelinePostTableViewCell: DisposeBagCollectable { }
extension TimelinePostTableViewCell: MosaicImageViewPresentable {
    var mosaicImageView: MosaicImageView {
        return timelinePostView.mosaicImageView
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
