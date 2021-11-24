//
//  ComposeInputTableViewCell.swift
//
//
//  Created by MainasuK on 2021/11/18.
//

import os.log
import UIKit
import Combine
import MetaTextKit
import TwidereAsset
import TwidereLocalization
import UITextView_Placeholder

public protocol ComposeInputTableViewCellDelegate: AnyObject {
    func composeInputTableViewCell(_ cell: ComposeInputTableViewCell, mentionPickButtonDidPressed button: UIButton)
}

final public class ComposeInputTableViewCell: UITableViewCell {
    
    public static let avatarImageViewSize = CGSize(width: 44, height: 44)

    let logger = Logger(subsystem: "ComposeInputTableViewCell", category: "UI")
    var disposeBag = Set<AnyCancellable>()
    
    public weak var delegate: ComposeInputTableViewCellDelegate?
    public private(set) lazy var viewModel: ViewModel = {
        let viewModel = ViewModel()
        viewModel.bind(cell: self)
        return viewModel
    }()
    
    public let avatarView: ProfileAvatarView = {
        let imageView = ProfileAvatarView()
        imageView.dimension = ComposeInputTableViewCell.avatarImageViewSize.width
        return imageView
    }()
    
    let conversationLinkLineView = SeparatorLineView()
    
    let mentionPickButton: UIButton = {
        let button = UIButton(type: .custom)
        button.contentHorizontalAlignment = .leading
        button.titleLabel?.font = .preferredFont(forTextStyle: .footnote)
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        button.setImage(Asset.Communication.textBubbleSmall.image.withRenderingMode(.alwaysTemplate), for: .normal)
        button.setTitleColor(Asset.Colors.hightLight.color, for: .normal)
        return button
    }()
    
    let metaText: MetaText = {
        let metaText = MetaText()
        metaText.textView.backgroundColor = .clear
        metaText.textView.isScrollEnabled = false
        metaText.textView.keyboardType = .twitter
        metaText.textView.textDragInteraction?.isEnabled = false    // disable drag for link and attachment
        metaText.textView.textContainer.lineFragmentPadding = 0     // leading inset
        metaText.textView.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 17, weight: .regular))
//        metaText.textAttributes = [
//            .font: UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 17, weight: .regular)),
//            .foregroundColor: Asset.Colors.Label.primary.color,
//        ]
//        metaText.linkAttributes = [
//            .font: UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 17, weight: .semibold)),
//            .foregroundColor: Asset.Colors.brandBlue.color,
//        ]
        metaText.textView.attributedPlaceholder = {
            var attributes = metaText.textAttributes
            attributes[.foregroundColor] = UIColor.secondaryLabel
            return NSAttributedString(
                string: L10n.Scene.Compose.placeholder,
                attributes: attributes
            )
        }()
        return metaText
    }()
    
    public let composeText = PassthroughSubject<String, Never>()
    
    override public func prepareForReuse() {
        super.prepareForReuse()

        disposeBag.removeAll()
        mentionPickButton.isHidden = true
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
        
        conversationLinkLineView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(conversationLinkLineView)
        NSLayoutConstraint.activate([
            conversationLinkLineView.topAnchor.constraint(equalTo: contentView.topAnchor),
            conversationLinkLineView.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            conversationLinkLineView.widthAnchor.constraint(equalToConstant: 1),
            avatarView.topAnchor.constraint(equalTo: conversationLinkLineView.bottomAnchor, constant: 2),
        ])
        
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
    
        containerStackView.addArrangedSubview(mentionPickButton)

        metaText.textView.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.addArrangedSubview(metaText.textView)
        NSLayoutConstraint.activate([
            metaText.textView.bottomAnchor.constraint(greaterThanOrEqualTo: avatarView.bottomAnchor, constant: 16),
        ])
        
        mentionPickButton.isHidden = true
        conversationLinkLineView.isHidden = true
        
        mentionPickButton.addTarget(self, action: #selector(ComposeInputTableViewCell.mentionPickButtonPressed(_:)), for: .touchUpInside)
    }
    
}

extension ComposeInputTableViewCell {
    func setMentionPickerButtonDisplay() {
        mentionPickButton.isHidden = false
    }
    
}

extension ComposeInputTableViewCell {
    @objc private func mentionPickButtonPressed(_ sender: UIButton) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        delegate?.composeInputTableViewCell(self, mentionPickButtonDidPressed: sender)
    }
}
