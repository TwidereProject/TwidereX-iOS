//
//  ComposeTweetContentTableViewCell.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-22.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import Combine

final class ComposeTweetContentTableViewCell: UITableViewCell {
    
    static let avatarImageViewSize = CGSize(width: 44, height: 44)
    
    var disposeBag = Set<AnyCancellable>()
    
    let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    let lockImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .white
        imageView.contentMode = .center
        imageView.image = Asset.ObjectTools.lock.image.withRenderingMode(.alwaysTemplate)
        imageView.backgroundColor = .black
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = TimelinePostView.lockImageViewSize.width * 0.5
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = UIColor.white.cgColor
        return imageView
    }()
    
    let conversationLinkUpper = UIView.separatorLine
    
    let composeTextView: UITextView = {
        let textView = UITextView()
        textView.font = .preferredFont(forTextStyle: .body)
        textView.isScrollEnabled = false
        return textView
    }()
    
    let composeText = PassthroughSubject<String, Never>()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        conversationLinkUpper.isHidden = true
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

extension ComposeTweetContentTableViewCell {
    
    private func _init() {
        selectionStyle = .none
        
        // user avatar
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(avatarImageView)
        NSLayoutConstraint.activate([
            avatarImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            avatarImageView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: ComposeTweetViewController.avatarImageViewSize.width).priority(.required - 1),
            avatarImageView.heightAnchor.constraint(equalToConstant: ComposeTweetViewController.avatarImageViewSize.height).priority(.required - 1),
        ])
        
        conversationLinkUpper.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(conversationLinkUpper)
        NSLayoutConstraint.activate([
            conversationLinkUpper.topAnchor.constraint(equalTo: contentView.topAnchor),
            conversationLinkUpper.centerXAnchor.constraint(equalTo: avatarImageView.centerXAnchor),
            conversationLinkUpper.widthAnchor.constraint(equalToConstant: 1),
            avatarImageView.topAnchor.constraint(equalTo: conversationLinkUpper.bottomAnchor, constant: 2),
        ])
    
        lockImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.addSubview(lockImageView)
        NSLayoutConstraint.activate([
            lockImageView.leadingAnchor.constraint(equalTo: avatarImageView.leadingAnchor),
            lockImageView.topAnchor.constraint(equalTo: avatarImageView.topAnchor),
            lockImageView.widthAnchor.constraint(equalToConstant: 16),
            lockImageView.heightAnchor.constraint(equalToConstant: 16),
        ])
        
        composeTextView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(composeTextView)
        NSLayoutConstraint.activate([
            composeTextView.topAnchor.constraint(equalTo: contentView.topAnchor),
            composeTextView.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 10),
            composeTextView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: composeTextView.bottomAnchor),
            composeTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 64),
        ])
        
        composeTextView.delegate = self
        conversationLinkUpper.isHidden = true
    }
    
}

// MARK: - UITextViewDelegate
extension ComposeTweetContentTableViewCell: UITextViewDelegate {
    func textViewDidChangeSelection(_ textView: UITextView) {
        guard textView === composeTextView else { return }
        composeText.send(composeTextView.text ?? "")
    }
}
