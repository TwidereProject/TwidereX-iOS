//
//  ConversationPostTableViewCell.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-17.
//

import os.log
import UIKit
import AVKit
import Combine
import ActiveLabel

protocol ConversationPostTableViewCellDelegate: class {
    var playerViewControllerDelegate: AVPlayerViewControllerDelegate? { get }
    func parent() -> UIViewController
    
    func conversationPostTableViewCell(_ cell: ConversationPostTableViewCell, retweetInfoLabelDidPressed label: UILabel)
    func conversationPostTableViewCell(_ cell: ConversationPostTableViewCell, avatarImageViewDidPressed imageView: UIImageView)
    func conversationPostTableViewCell(_ cell: ConversationPostTableViewCell, quoteAvatarImageViewDidPressed imageView: UIImageView)
    func conversationPostTableViewCell(_ cell: ConversationPostTableViewCell, quotePostViewDidPressed quotePostView: QuotePostView)

    func conversationPostTableViewCell(_ cell: ConversationPostTableViewCell, actionToolbarContainer: ActionToolbarContainer, replayButtonDidPressed sender: UIButton)
    func conversationPostTableViewCell(_ cell: ConversationPostTableViewCell, actionToolbarContainer: ActionToolbarContainer, retweetButtonDidPressed sender: UIButton)
    func conversationPostTableViewCell(_ cell: ConversationPostTableViewCell, actionToolbarContainer: ActionToolbarContainer, favoriteButtonDidPressed sender: UIButton)
    func conversationPostTableViewCell(_ cell: ConversationPostTableViewCell, actionToolbarContainer: ActionToolbarContainer, shareButtonDidPressed sender: UIButton)
    
    func conversationPostTableViewCell(_ cell: ConversationPostTableViewCell, mosaicImageView: MosaicImageView, didTapImageView imageView: UIImageView, atIndex index: Int)
    
    func conversationPostTableViewCell(_ cell: ConversationPostTableViewCell, activeLabel: ActiveLabel, didTapEntity entity: ActiveEntity)
}

final class ConversationPostTableViewCell: UITableViewCell {
    
    var disposeBag = Set<AnyCancellable>()
    var observations = Set<NSKeyValueObservation>()
        
    weak var delegate: ConversationPostTableViewCellDelegate?

    let conversationPostView = ConversationPostView()
    
    let conversationLinkUpper = UIView.separatorLine
    
    private let avatarImageViewTapGestureRecognizer = UITapGestureRecognizer.singleTapGestureRecognizer
    private let retweetInfoLabelTapGestureRecognizer = UITapGestureRecognizer.singleTapGestureRecognizer
    private let quoteAvatarImageViewTapGestureRecognizer = UITapGestureRecognizer.singleTapGestureRecognizer
    private let quotePostViewTapGestureRecognizer = UITapGestureRecognizer.singleTapGestureRecognizer
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        conversationPostView.mosaicImageView.reset()
        conversationPostView.mosaicImageView.isHidden = true
        conversationPostView.mosaicPlayerView.reset()
        conversationPostView.mosaicPlayerView.isHidden = true
        conversationLinkUpper.isHidden = true
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

extension ConversationPostTableViewCell {
    
    private func _init() {
        selectionStyle = .none
        
        conversationPostView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(conversationPostView)
        NSLayoutConstraint.activate([
            conversationPostView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            conversationPostView.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            contentView.readableContentGuide.trailingAnchor.constraint(equalTo: conversationPostView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: conversationPostView.bottomAnchor),
        ])
        
        conversationLinkUpper.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(conversationLinkUpper)
        NSLayoutConstraint.activate([
            conversationLinkUpper.topAnchor.constraint(equalTo: contentView.topAnchor),
            conversationLinkUpper.centerXAnchor.constraint(equalTo: conversationPostView.avatarImageView.centerXAnchor),
            conversationPostView.avatarImageView.topAnchor.constraint(equalTo: conversationLinkUpper.bottomAnchor, constant: 2),
            conversationLinkUpper.widthAnchor.constraint(equalToConstant: 1),
        ])
        
        let separatorLine = UIView.separatorLine
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separatorLine)
        NSLayoutConstraint.activate([
            separatorLine.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            contentView.readableContentGuide.trailingAnchor.constraint(equalTo: separatorLine.trailingAnchor),
            separatorLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: UIView.separatorLineHeight(of: separatorLine)),
        ])
        
        retweetInfoLabelTapGestureRecognizer.addTarget(self, action: #selector(ConversationPostTableViewCell.retweetInfoLabelTapGestureRecognizerHandler(_:)))
        conversationPostView.retweetInfoLabel.isUserInteractionEnabled = true
        conversationPostView.retweetInfoLabel.addGestureRecognizer(retweetInfoLabelTapGestureRecognizer)
        
        avatarImageViewTapGestureRecognizer.addTarget(self, action: #selector(ConversationPostTableViewCell.avatarImageViewTapGestureRecognizerHandler(_:)))
        conversationPostView.avatarImageView.isUserInteractionEnabled = true
        conversationPostView.avatarImageView.addGestureRecognizer(avatarImageViewTapGestureRecognizer)
        
        quoteAvatarImageViewTapGestureRecognizer.addTarget(self, action: #selector(ConversationPostTableViewCell.quoteAvatarImageViewTapGestureRecognizerHandler(_:)))
        conversationPostView.quotePostView.avatarImageView.isUserInteractionEnabled = true
        conversationPostView.quotePostView.avatarImageView.addGestureRecognizer(quoteAvatarImageViewTapGestureRecognizer)
        
        quotePostViewTapGestureRecognizer.addTarget(self, action: #selector(ConversationPostTableViewCell.quotePostViewTapGestureRecognizerHandler(_:)))
        conversationPostView.quotePostView.isUserInteractionEnabled = true
        conversationPostView.quotePostView.addGestureRecognizer(quotePostViewTapGestureRecognizer)
        
        conversationPostView.activeTextLabel.delegate = self
        conversationPostView.actionToolbarContainer.delegate = self
        conversationPostView.mosaicImageView.delegate = self
    }
    
}

extension ConversationPostTableViewCell {
    
    @objc private func retweetInfoLabelTapGestureRecognizerHandler(_ sender: UITapGestureRecognizer) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        guard sender.state == .ended else { return }
        delegate?.conversationPostTableViewCell(self, retweetInfoLabelDidPressed: conversationPostView.retweetInfoLabel)
    }
    
    @objc private func avatarImageViewTapGestureRecognizerHandler(_ sender: UITapGestureRecognizer) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        guard sender.state == .ended else { return }
        assert(delegate != nil)
        delegate?.conversationPostTableViewCell(self, avatarImageViewDidPressed: conversationPostView.avatarImageView)
    }
    
    @objc private func quoteAvatarImageViewTapGestureRecognizerHandler(_ sender: UITapGestureRecognizer) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        guard sender.state == .ended else { return }
        assert(delegate != nil)
        delegate?.conversationPostTableViewCell(self, quoteAvatarImageViewDidPressed: conversationPostView.quotePostView.avatarImageView)
    }
    
    @objc private func quotePostViewTapGestureRecognizerHandler(_ sender: UITapGestureRecognizer) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        guard sender.state == .ended else { return }
        assert(delegate != nil)
        delegate?.conversationPostTableViewCell(self, quotePostViewDidPressed: conversationPostView.quotePostView)
    }
    
}

// MARK: - ActiveLabelDelegate
extension ConversationPostTableViewCell: ActiveLabelDelegate {
    func activeLabel(_ activeLabel: ActiveLabel, didSelectActiveEntity entity: ActiveEntity) {
        if activeLabel === conversationPostView.activeTextLabel {
            delegate?.conversationPostTableViewCell(self, activeLabel: activeLabel, didTapEntity: entity)
        }
    }
}

// MARK: - ActionToolbarContainerDelegate
extension ConversationPostTableViewCell: ActionToolbarContainerDelegate {
    
    func actionToolbarContainer(_ actionToolbarContainer: ActionToolbarContainer, replayButtonDidPressed sender: UIButton) {
        delegate?.conversationPostTableViewCell(self, actionToolbarContainer: actionToolbarContainer, replayButtonDidPressed: sender)
    }
    
    func actionToolbarContainer(_ actionToolbarContainer: ActionToolbarContainer, retweetButtonDidPressed sender: UIButton) {
        delegate?.conversationPostTableViewCell(self, actionToolbarContainer: actionToolbarContainer, retweetButtonDidPressed: sender)
    }
    
    func actionToolbarContainer(_ actionToolbarContainer: ActionToolbarContainer, likeButtonDidPressed sender: UIButton) {
        delegate?.conversationPostTableViewCell(self, actionToolbarContainer: actionToolbarContainer, favoriteButtonDidPressed: sender)
    }
    
    func actionToolbarContainer(_ actionToolbarContainer: ActionToolbarContainer, menuButtonDidPressed sender: UIButton) {
        delegate?.conversationPostTableViewCell(self, actionToolbarContainer: actionToolbarContainer, shareButtonDidPressed: sender)
    }

}

// MARK: - MosaicImageViewDelegate
extension ConversationPostTableViewCell: MosaicImageViewDelegate {
    func mosaicImageView(_ mosaicImageView: MosaicImageView, didTapImageView imageView: UIImageView, atIndex index: Int) {
        delegate?.conversationPostTableViewCell(self, mosaicImageView: mosaicImageView, didTapImageView: imageView, atIndex: index)
    }
}

extension ConversationPostTableViewCell: DisposeBagCollectable { }
extension ConversationPostTableViewCell: MosaicImageViewPresentable {
    var mosaicImageView: MosaicImageView {
        return conversationPostView.mosaicImageView
    }
}

#if DEBUG
import SwiftUI

struct ConversationPostTableViewCell_Previews: PreviewProvider {
    static var avatarImage: UIImage {
        UIImage(named: "patrick-perkins")!
            .af.imageRoundedIntoCircle()
    }
    
    static var avatarImage2: UIImage {
        UIImage(named: "dan-maisey")!
            .af.imageRoundedIntoCircle()
    }
    
    static var previews: some View {
        UIViewPreview {
            let view = ConversationPostTableViewCell()
            view.conversationPostView.avatarImageView.image = avatarImage
            let images = MosaicImageView_Previews.images.prefix(3)
            let imageViews = view.conversationPostView.mosaicImageView.setupImageViews(count: images.count, maxHeight: 162)
            for (i, imageView) in imageViews.enumerated() {
                imageView.image = images[i]
            }
            view.conversationPostView.mosaicImageView.isHidden = false
            // view.quotePostView.avatarImageView.image = avatarImage2
            // view.quotePostView.nameLabel.text = "Bob"
            // view.quotePostView.headerSecondaryLabel.text = "@bob"
            // view.quotePostView.isHidden = false
            return view
        }
        .previewLayout(.fixed(width: 375, height: 500))
    }
}
#endif
