//
//  ConversationPostTableViewCell.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-17.
//

import UIKit

final class ConversationPostTableViewCell: UITableViewCell {
    
    let conversationPostView = ConversationPostView()
    
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
