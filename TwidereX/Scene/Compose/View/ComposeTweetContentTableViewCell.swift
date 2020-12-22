//
//  ComposeTweetContentTableViewCell.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-22.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine

protocol ComposeTweetContentTableViewCellDelegate: class {
    func composeTweetContentTableViewCell(_ cell: ComposeTweetContentTableViewCell, mentionPickButtonDidPressed button: UIButton)
}

final class ComposeTweetContentTableViewCell: UITableViewCell {
    
    static let avatarImageViewSize = CGSize(width: 44, height: 44)
    
    var disposeBag = Set<AnyCancellable>()
    
    weak var delegate: ComposeTweetContentTableViewCellDelegate?
    
    let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    // let verifiedBadgeImageView: UIImageView = {
    //     let imageView = UIImageView()
    //     imageView.tintColor = .white
    //     imageView.contentMode = .scaleAspectFill
    //     imageView.image = Asset.ObjectTools.verifiedBadge.image.withRenderingMode(.alwaysOriginal)
    //     return imageView
    // }()
    
    let conversationLinkUpper = UIView.separatorLine
    
    let mentionPickButton: UIButton = {
        let button = UIButton(type: .custom)
        button.contentHorizontalAlignment = .leading
        button.titleLabel?.font = .preferredFont(forTextStyle: .footnote)
        button.setImage(Asset.Communication.textBubbleSmall.image.withRenderingMode(.alwaysTemplate), for: .normal)
        button.setTitleColor(Asset.Colors.hightLight.color, for: .normal)
        return button
    }()
    
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
            avatarImageView.widthAnchor.constraint(equalToConstant: ComposeTweetContentTableViewCell.avatarImageViewSize.width).priority(.required - 1),
            avatarImageView.heightAnchor.constraint(equalToConstant: ComposeTweetContentTableViewCell.avatarImageViewSize.height).priority(.required - 1),
        ])
        
        conversationLinkUpper.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(conversationLinkUpper)
        NSLayoutConstraint.activate([
            conversationLinkUpper.topAnchor.constraint(equalTo: contentView.topAnchor),
            conversationLinkUpper.centerXAnchor.constraint(equalTo: avatarImageView.centerXAnchor),
            conversationLinkUpper.widthAnchor.constraint(equalToConstant: 1),
            avatarImageView.topAnchor.constraint(equalTo: conversationLinkUpper.bottomAnchor, constant: 2),
        ])
    
        //verifiedBadgeImageView.translatesAutoresizingMaskIntoConstraints = false
        //avatarImageView.addSubview(verifiedBadgeImageView)
        //NSLayoutConstraint.activate([
        //    verifiedBadgeImageView.trailingAnchor.constraint(equalTo: avatarImageView.trailingAnchor),
        //    verifiedBadgeImageView.bottomAnchor.constraint(equalTo: avatarImageView.bottomAnchor),
        //    verifiedBadgeImageView.widthAnchor.constraint(equalToConstant: 16),
        //    verifiedBadgeImageView.heightAnchor.constraint(equalToConstant: 16),
        //])
        
        let containerStackView = UIStackView()
        containerStackView.axis = .vertical
        containerStackView.spacing = 8
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerStackView)
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            containerStackView.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 10),
            containerStackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: containerStackView.bottomAnchor),
        ])
        
        containerStackView.addArrangedSubview(mentionPickButton)
        
        composeTextView.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.addArrangedSubview(composeTextView)
        NSLayoutConstraint.activate([
            composeTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 64),
        ])
        
        composeTextView.delegate = self
        conversationLinkUpper.isHidden = true
        
        mentionPickButton.addTarget(self, action: #selector(ComposeTweetContentTableViewCell.mentionPickButtonPressed(_:)), for: .touchUpInside)
    }
    
}

extension ComposeTweetContentTableViewCell {
    @objc private func mentionPickButtonPressed(_ sender: UIButton) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.composeTweetContentTableViewCell(self, mentionPickButtonDidPressed: sender)
    }
}

// MARK: - UITextViewDelegate
extension ComposeTweetContentTableViewCell: UITextViewDelegate {
    func textViewDidChangeSelection(_ textView: UITextView) {
        guard textView === composeTextView else { return }
        composeText.send(composeTextView.text ?? "")
    }
}
