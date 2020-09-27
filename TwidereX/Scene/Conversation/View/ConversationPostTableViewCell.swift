//
//  ConversationPostTableViewCell.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-17.
//

import os.log
import UIKit

protocol ConversationPostTableViewCellDelegate: class {
    func conversationPostTableViewCell(_ cell: ConversationPostTableViewCell, avatarImageViewDidPressed imageView: UIImageView)
    func conversationPostTableViewCell(_ cell: ConversationPostTableViewCell, quoteAvatarImageViewDidPressed imageView: UIImageView)
}

final class ConversationPostTableViewCell: UITableViewCell {
    
    weak var delegate: ConversationPostTableViewCellDelegate?

    let conversationPostView = ConversationPostView()
    
    private let avatarImageViewTapGestureRecognizer: UITapGestureRecognizer = {
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
            conversationPostView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            contentView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: conversationPostView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: conversationPostView.bottomAnchor),
        ])
        
        let separatorLine = UIView.separatorLine
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separatorLine)
        NSLayoutConstraint.activate([
            separatorLine.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            contentView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: separatorLine.trailingAnchor),
            separatorLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: UIView.separatorLineHeight(of: separatorLine)),
        ])
        
        avatarImageViewTapGestureRecognizer.addTarget(self, action: #selector(ConversationPostTableViewCell.avatarImageViewTapGestureRecognizerHandler(_:)))
        conversationPostView.avatarImageView.isUserInteractionEnabled = true
        conversationPostView.avatarImageView.addGestureRecognizer(avatarImageViewTapGestureRecognizer)
        
        quoteAvatarImageViewTapGestureRecognizer.addTarget(self, action: #selector(ConversationPostTableViewCell.quoteAvatarImageViewTapGestureRecognizerHandler(_:)))
        conversationPostView.quotePostView.avatarImageView.isUserInteractionEnabled = true
        conversationPostView.quotePostView.avatarImageView.addGestureRecognizer(quoteAvatarImageViewTapGestureRecognizer)
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
//            let images = MosaicImageView_Previews.images.prefix(3)
//            let imageViews = view.mosaicImageView.setupImageViews(count: images.count, maxHeight: 162)
//            for (i, imageView) in imageViews.enumerated() {
//                imageView.image = images[i]
//            }
//            view.mosaicImageView.isHidden = false
//            view.quotePostView.avatarImageView.image = avatarImage2
//            view.quotePostView.nameLabel.text = "Bob"
//            view.quotePostView.usernameLabel.text = "@bob"
//            view.quotePostView.isHidden = false
            return view
        }
        .previewLayout(.fixed(width: 375, height: 200))
    }
}
#endif
