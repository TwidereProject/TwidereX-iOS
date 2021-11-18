//
//  ComposeInputTableViewCell.swift
//
//
//  Created by MainasuK on 2021/11/18.
//

import os.log
import UIKit
import Combine

public protocol ComposeInputTableViewCellDelegate: AnyObject {
    func composeInputTableViewCell(_ cell: ComposeInputTableViewCell, mentionPickButtonDidPressed button: UIButton)
}

final public class ComposeInputTableViewCell: UITableViewCell {
    
    public static let avatarImageViewSize = CGSize(width: 44, height: 44)
    
    var disposeBag = Set<AnyCancellable>()
    
    public weak var delegate: ComposeInputTableViewCellDelegate?
    
    // TODO: use ProfileAvatarButton
    public let avatarView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    // let conversationLinkUpper = UIView.separatorLine
    
//    let mentionPickButton: UIButton = {
//        let button = UIButton(type: .custom)
//        button.contentHorizontalAlignment = .leading
//        button.titleLabel?.font = .preferredFont(forTextStyle: .footnote)
//        button.titleLabel?.lineBreakMode = .byTruncatingTail
//        button.setImage(Asset.Communication.textBubbleSmall.image.withRenderingMode(.alwaysTemplate), for: .normal)
//        button.setTitleColor(Asset.Colors.hightLight.color, for: .normal)
//        return button
//    }()
    
    public let composeTextView: UITextView = {
        let textView = UITextView()
        textView.font = .preferredFont(forTextStyle: .body)
        textView.isScrollEnabled = false
        return textView
    }()
    
    public let composeText = PassthroughSubject<String, Never>()
    
    override public func prepareForReuse() {
        super.prepareForReuse()
//        conversationLinkUpper.isHidden = true
        disposeBag.removeAll()
    }
    
    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension ComposeInputTableViewCell {
    
    private func _init() {
        selectionStyle = .none
        
        // user avatar
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(avatarView)
        NSLayoutConstraint.activate([
            avatarView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            avatarView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: ComposeInputTableViewCell.avatarImageViewSize.width).priority(.required - 1),
            avatarView.heightAnchor.constraint(equalToConstant: ComposeInputTableViewCell.avatarImageViewSize.height).priority(.required - 1),
        ])
        
//        conversationLinkUpper.translatesAutoresizingMaskIntoConstraints = false
//        contentView.addSubview(conversationLinkUpper)
//        NSLayoutConstraint.activate([
//            conversationLinkUpper.topAnchor.constraint(equalTo: contentView.topAnchor),
//            conversationLinkUpper.centerXAnchor.constraint(equalTo: avatarImageView.centerXAnchor),
//            conversationLinkUpper.widthAnchor.constraint(equalToConstant: 1),
//            avatarImageView.topAnchor.constraint(equalTo: conversationLinkUpper.bottomAnchor, constant: 2),
//        ])
        
        let containerStackView = UIStackView()
        containerStackView.axis = .vertical
        containerStackView.spacing = 8
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerStackView)
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            containerStackView.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 10),
            containerStackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: containerStackView.bottomAnchor),
        ])
        
        #if DEBUG
        avatarView.backgroundColor = .red
        containerStackView.backgroundColor = .green
        #endif
        
//        containerStackView.addArrangedSubview(mentionPickButton)
        
        composeTextView.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.addArrangedSubview(composeTextView)
        NSLayoutConstraint.activate([
            composeTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 64),
        ])
        
        composeTextView.delegate = self
//        conversationLinkUpper.isHidden = true
        
//        mentionPickButton.addTarget(self, action: #selector(ComposeTweetContentTableViewCell.mentionPickButtonPressed(_:)), for: .touchUpInside)
    }
    
}

extension ComposeInputTableViewCell {
    @objc private func mentionPickButtonPressed(_ sender: UIButton) {
        // TODO:
    }
}

// MARK: - UITextViewDelegate
extension ComposeInputTableViewCell: UITextViewDelegate {
    public func textViewDidChange(_ textView: UITextView) {
        guard textView === composeTextView else { return }
        composeText.send(composeTextView.text ?? "")
    }
}
