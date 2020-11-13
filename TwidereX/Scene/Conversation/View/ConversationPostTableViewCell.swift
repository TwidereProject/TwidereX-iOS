//
//  ConversationPostTableViewCell.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-17.
//

import os.log
import UIKit
import Combine

protocol ConversationPostTableViewCellDelegate: class {
    func conversationPostTableViewCell(_ cell: ConversationPostTableViewCell, avatarImageViewDidPressed imageView: UIImageView)
    func conversationPostTableViewCell(_ cell: ConversationPostTableViewCell, quoteAvatarImageViewDidPressed imageView: UIImageView)
    func conversationPostTableViewCell(_ cell: ConversationPostTableViewCell, quotePostViewDidPressed quotePostView: QuotePostView)

    func conversationPostTableViewCell(_ cell: ConversationPostTableViewCell, actionToolbar: StatusActionToolbar, replayButtonDidPressed sender: UIButton)
    func conversationPostTableViewCell(_ cell: ConversationPostTableViewCell, actionToolbar: StatusActionToolbar, retweetButtonDidPressed sender: UIButton)
    func conversationPostTableViewCell(_ cell: ConversationPostTableViewCell, actionToolbar: StatusActionToolbar, favoriteButtonDidPressed sender: UIButton)
    func conversationPostTableViewCell(_ cell: ConversationPostTableViewCell, actionToolbar: StatusActionToolbar, shareButtonDidPressed sender: UIButton)
    
    func conversationPostTableViewCell(_ cell: ConversationPostTableViewCell, mosaicImageView: MosaicImageView, didTapImageView imageView: UIImageView, atIndex index: Int)
}

final class ConversationPostTableViewCell: UITableViewCell {
    
    var disposeBag = Set<AnyCancellable>()
    weak var delegate: ConversationPostTableViewCellDelegate?

    let conversationPostView = ConversationPostView()
    
    private let avatarImageViewTapGestureRecognizer = UITapGestureRecognizer.singleTapGestureRecognizer
    private let quoteAvatarImageViewTapGestureRecognizer = UITapGestureRecognizer.singleTapGestureRecognizer
    private let quotePostViewTapGestureRecognizer = UITapGestureRecognizer.singleTapGestureRecognizer
    
    override func prepareForReuse() {
        super.prepareForReuse()
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
        
        let separatorLine = UIView.separatorLine
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separatorLine)
        NSLayoutConstraint.activate([
            separatorLine.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            contentView.readableContentGuide.trailingAnchor.constraint(equalTo: separatorLine.trailingAnchor),
            separatorLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: UIView.separatorLineHeight(of: separatorLine)),
        ])
        
        avatarImageViewTapGestureRecognizer.addTarget(self, action: #selector(ConversationPostTableViewCell.avatarImageViewTapGestureRecognizerHandler(_:)))
        conversationPostView.avatarImageView.isUserInteractionEnabled = true
        conversationPostView.avatarImageView.addGestureRecognizer(avatarImageViewTapGestureRecognizer)
        
        quoteAvatarImageViewTapGestureRecognizer.addTarget(self, action: #selector(ConversationPostTableViewCell.quoteAvatarImageViewTapGestureRecognizerHandler(_:)))
        conversationPostView.quotePostView.avatarImageView.isUserInteractionEnabled = true
        conversationPostView.quotePostView.avatarImageView.addGestureRecognizer(quoteAvatarImageViewTapGestureRecognizer)
        
        quotePostViewTapGestureRecognizer.addTarget(self, action: #selector(ConversationPostTableViewCell.quotePostViewTapGestureRecognizerHandler(_:)))
        conversationPostView.quotePostView.isUserInteractionEnabled = true
        conversationPostView.quotePostView.addGestureRecognizer(quotePostViewTapGestureRecognizer)
        
        conversationPostView.actionToolbar.delegate = self
        conversationPostView.mosaicImageView.delegate = self
    }
    
}

extension ConversationPostTableViewCell {
    
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

// MARK: - TimelinePostActionToolbarDelegate
extension ConversationPostTableViewCell: StatusActionToolbarDelegate {
    
    func statusActionToolbar(_ toolbar: StatusActionToolbar, replayButtonDidPressed sender: UIButton) {
        delegate?.conversationPostTableViewCell(self, actionToolbar: toolbar, replayButtonDidPressed: sender)
    }
    
    func statusActionToolbar(_ toolbar: StatusActionToolbar, retweetButtonDidPressed sender: UIButton) {
        delegate?.conversationPostTableViewCell(self, actionToolbar: toolbar, retweetButtonDidPressed: sender)
    }
    
    func statusActionToolbar(_ toolbar: StatusActionToolbar, favoriteButtonDidPressed sender: UIButton) {
        delegate?.conversationPostTableViewCell(self, actionToolbar: toolbar, favoriteButtonDidPressed: sender)
    }
    
    func statusActionToolbar(_ toolbar: StatusActionToolbar, shareButtonDidPressed sender: UIButton) {
        delegate?.conversationPostTableViewCell(self, actionToolbar: toolbar, shareButtonDidPressed: sender)
    }
    
}

// MARK: - MosaicImageViewDelegate
extension ConversationPostTableViewCell: MosaicImageViewDelegate {
    func mosaicImageView(_ mosaicImageView: MosaicImageView, didTapImageView imageView: UIImageView, atIndex index: Int) {
        delegate?.conversationPostTableViewCell(self, mosaicImageView: mosaicImageView, didTapImageView: imageView, atIndex: index)
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
            // view.quotePostView.usernameLabel.text = "@bob"
            // view.quotePostView.isHidden = false
            return view
        }
        .previewLayout(.fixed(width: 375, height: 500))
    }
}
#endif
