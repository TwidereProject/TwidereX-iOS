//
//  StatusView.swift
//  StatusView
//
//  Created by Cirno MainasuK on 2021-8-19.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import Combine
import UIKit
import MetaTextKit
import MetaTextArea
import Kingfisher
import TwidereCommon

protocol StatusViewDelegate: AnyObject {
    func statusView(_ statusView: StatusView, headerDidPressed header: UIView)
    
    func statusView(_ statusView: StatusView, authorAvatarButtonDidPressed button: AvatarButton)
    func statusView(_ statusView: StatusView, quoteStatusView: StatusView, authorAvatarButtonDidPressed button: AvatarButton)
    
    func statusView(_ statusView: StatusView, mediaGridContainerView containerView: MediaGridContainerView, didTapMediaView mediaView: MediaView, at index: Int)
    func statusView(_ statusView: StatusView, quoteStatusView: StatusView, mediaGridContainerView containerView: MediaGridContainerView, didTapMediaView mediaView: MediaView, at index: Int)
    
    func statusView(_ statusView: StatusView, statusToolbar: StatusToolbar, actionDidPressed action: StatusToolbar.Action)
}

final class StatusView: UIView {
    
    private var _disposeBag = Set<AnyCancellable>() // which lifetime same to view scope
    var disposeBag = Set<AnyCancellable>()          // clear when reuse
    
    weak var delegate: StatusViewDelegate?

    static let bodyContainerStackViewSpacing: CGFloat = 10
    static let quoteStatusViewContainerLayoutMargin: CGFloat = 12
    
    let logger = Logger(subsystem: "StatusView", category: "UI")
    
    private var style: Style?
    
    private(set) lazy var viewModel: ViewModel = {
        let viewModel = ViewModel()
        viewModel.bind(statusView: self)
        return viewModel
    }()
    
    // container
    let containerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        return stackView
    }()
    
    // header
    let headerContainerView = UIView()
    let headerIconImageView = UIImageView()
    static var headerTextLabelStyle: TextStyle { .statusHeader }
    let headerTextLabel = MetaLabel(style: .statusHeader)
    
    // avatar
    let authorAvatarButton = AvatarButton()
    
    // author
    static var authorNameLabelStyle: TextStyle { .statusAuthorName }
    let authorNameLabel = MetaLabel(style: StatusView.authorNameLabelStyle)
    let authorUsernameLabel = PlainLabel(style: .statusAuthorUsername)
    let visibilityImageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    let timestampLabel = PlainLabel(style: .statusTimestamp)
    
    // content
    let contentTextView = MetaTextAreaView()
    
    // media
    let mediaGridContainerView = MediaGridContainerView()
    
    // quote
    private(set) var quoteStatusView: StatusView? {
        didSet {
            if let quoteStatusView = quoteStatusView {
                quoteStatusView.delegate = self
            }
        }
    }
    
    // location
    let locationContainer: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 6
        return stackView
    }()
    let locationMapPinImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .secondaryLabel
        return imageView
    }()
    let locationLabel = PlainLabel(style: .statusAuthorUsername)

    
    // toolbar
    let toolbar = StatusToolbar()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        assert(style != nil, "Needs setup style before use")
    }
    
    deinit {
        viewModel.disposeBag.removeAll()
    }
    
}

extension StatusView {
    
    func prepareForReuse() {
        disposeBag.removeAll()
        viewModel.objects.removeAll()
        viewModel.authorAvatarImageURL = nil
        authorAvatarButton.avatarImageView.cancelTask()
        mediaGridContainerView.prepareForReuse()
        Style.prepareForReuse(statusView: self)
    }
    
    private func _init() {
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerStackView)
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: topAnchor),
            containerStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        // header
        let headerTapGestureRecognizer = UITapGestureRecognizer.singleTapGestureRecognizer
        headerTapGestureRecognizer.addTarget(self, action: #selector(StatusView.headerTapGestureRecognizerHandler(_:)))
        headerContainerView.addGestureRecognizer(headerTapGestureRecognizer)
        // avatar button
        authorAvatarButton.addTarget(self, action: #selector(StatusView.authorAvatarButtonDidPressed(_:)), for: .touchUpInside)
        // media grid
        mediaGridContainerView.delegate = self
        // toolbar
        toolbar.delegate = self
        
        ThemeService.shared.theme
            .sink { [weak self] theme in
                guard let self = self else { return }
                self.update(theme: theme)
            }
            .store(in: &disposeBag)
    }
    
    func setup(style: Style) {
        guard self.style == nil else {
            assertionFailure("Should only setup once")
            return
        }
        self.style = style
        style.layout(statusView: self)
        Style.prepareForReuse(statusView: self)
    }
    
}

extension StatusView {
    enum Style {
        case inline     // for timeline
        case plain      // for thread
        case quote      // for quote
        
        func layout(statusView: StatusView) {
            switch self {
            case .inline:   layoutInline(statusView: statusView)
            case .plain:    layoutPlain(statusView: statusView)
            case .quote:    layoutQuote(statusView: statusView)
            }
        }
        
        static func prepareForReuse(statusView: StatusView) {
            statusView.headerContainerView.isHidden = true
            statusView.mediaGridContainerView.isHidden = true
            statusView.quoteStatusView?.isHidden = true
            statusView.locationContainer.isHidden = true
        }
    }
}

extension StatusView.Style {
    
    private func layoutInline(statusView: StatusView) {
        // container: V - [ header container | body container ]
        
        // header container: H - [ icon | label ]
        statusView.containerStackView.addArrangedSubview(statusView.headerContainerView)
        statusView.headerIconImageView.translatesAutoresizingMaskIntoConstraints = false
        statusView.headerTextLabel.translatesAutoresizingMaskIntoConstraints = false
        statusView.headerContainerView.addSubview(statusView.headerIconImageView)
        statusView.headerContainerView.addSubview(statusView.headerTextLabel)
        NSLayoutConstraint.activate([
            statusView.headerTextLabel.topAnchor.constraint(equalTo: statusView.headerContainerView.topAnchor),
            statusView.headerTextLabel.bottomAnchor.constraint(equalTo: statusView.headerContainerView.bottomAnchor),
            statusView.headerTextLabel.trailingAnchor.constraint(equalTo: statusView.headerContainerView.trailingAnchor),
            statusView.headerIconImageView.centerYAnchor.constraint(equalTo: statusView.headerTextLabel.centerYAnchor),
            statusView.headerIconImageView.heightAnchor.constraint(equalTo: statusView.headerTextLabel.heightAnchor, multiplier: 1.0).priority(.required - 1),
            statusView.headerIconImageView.widthAnchor.constraint(equalTo: statusView.headerIconImageView.heightAnchor, multiplier: 1.0).priority(.required - 1),
            statusView.headerTextLabel.leadingAnchor.constraint(equalTo: statusView.headerIconImageView.trailingAnchor, constant: 4),
            // align to author name below
        ])
        statusView.headerTextLabel.setContentHuggingPriority(.required - 10, for: .vertical)
        statusView.headerIconImageView.setContentHuggingPriority(.defaultLow, for: .vertical)
        statusView.headerIconImageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        // body container: H - [ authorAvatarButton | content container ]
        let bodyContainerStackView = UIStackView()
        bodyContainerStackView.axis = .horizontal
        bodyContainerStackView.spacing = StatusView.bodyContainerStackViewSpacing
        bodyContainerStackView.alignment = .top
        statusView.containerStackView.addArrangedSubview(bodyContainerStackView)
        
        // authorAvatarButton
        let authorAvatarButtonSize = CGSize(width: 44, height: 44)
        statusView.authorAvatarButton.size = authorAvatarButtonSize
        statusView.authorAvatarButton.avatarImageView.imageViewSize = authorAvatarButtonSize
        statusView.authorAvatarButton.translatesAutoresizingMaskIntoConstraints = false
        bodyContainerStackView.addArrangedSubview(statusView.authorAvatarButton)
        NSLayoutConstraint.activate([
            statusView.authorAvatarButton.widthAnchor.constraint(equalToConstant: authorAvatarButtonSize.width).priority(.required - 1),
            statusView.authorAvatarButton.heightAnchor.constraint(equalToConstant: authorAvatarButtonSize.height).priority(.required - 1),
        ])
        
        // content container: V - [ author content | contentTextView | mediaGridContainerView | quoteStatusView | … | location content | toolbar ]
        let contentContainerView = UIStackView()
        contentContainerView.axis = .vertical
        contentContainerView.spacing = 10
        bodyContainerStackView.addArrangedSubview(contentContainerView)
        
        // author content: H - [ authorNameLabel | authorUsernameLabel | padding | visibilityImageView (for Mastodon) | timestampLabel ]
        let authorContentStackView = UIStackView()
        authorContentStackView.axis = .horizontal
        authorContentStackView.spacing = 6
        contentContainerView.addArrangedSubview(authorContentStackView)
        contentContainerView.setCustomSpacing(4, after: authorContentStackView)
        UIContentSizeCategory.publisher
            .sink { category in
                authorContentStackView.axis = category > .accessibilityLarge ? .vertical : .horizontal
            }
            .store(in: &statusView._disposeBag)
        
        // authorNameLabel
        authorContentStackView.addArrangedSubview(statusView.authorNameLabel)
        statusView.authorNameLabel.setContentCompressionResistancePriority(.required - 10, for: .horizontal)
        // authorUsernameLabel
        authorContentStackView.addArrangedSubview(statusView.authorUsernameLabel)
        statusView.authorUsernameLabel.setContentCompressionResistancePriority(.required - 11, for: .horizontal)
        // padding
        authorContentStackView.addArrangedSubview(UIView())
        // timestampLabel
        authorContentStackView.addArrangedSubview(statusView.timestampLabel)
        statusView.timestampLabel.setContentHuggingPriority(.required - 9, for: .horizontal)
        statusView.timestampLabel.setContentCompressionResistancePriority(.required - 9, for: .horizontal)
        
        // set header label align to author name
        NSLayoutConstraint.activate([
            statusView.headerTextLabel.leadingAnchor.constraint(equalTo: statusView.authorNameLabel.leadingAnchor),
        ])
        
        // contentTextView
        statusView.contentTextView.translatesAutoresizingMaskIntoConstraints = false
        contentContainerView.addArrangedSubview(statusView.contentTextView)
        statusView.contentTextView.setContentHuggingPriority(.required - 10, for: .vertical)
        
        // mediaGridContainerView
        statusView.mediaGridContainerView.translatesAutoresizingMaskIntoConstraints = false
        contentContainerView.addArrangedSubview(statusView.mediaGridContainerView)
        
        // quoteStatusView
        let quoteStatusView = StatusView()
        quoteStatusView.setup(style: .quote)
        statusView.quoteStatusView = quoteStatusView
        contentContainerView.addArrangedSubview(quoteStatusView)
        
        // location content: H - [ locationMapPinImageView | locationLabel ]
        contentContainerView.addArrangedSubview(statusView.locationContainer)
        
        statusView.locationMapPinImageView.translatesAutoresizingMaskIntoConstraints = false
        statusView.locationLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // locationMapPinImageView
        statusView.locationContainer.addArrangedSubview(statusView.locationMapPinImageView)
        // locationLabel
        statusView.locationContainer.addArrangedSubview(statusView.locationLabel)
        
        NSLayoutConstraint.activate([
            statusView.locationMapPinImageView.heightAnchor.constraint(equalTo: statusView.locationLabel.heightAnchor, multiplier: 1.0).priority(.required - 1),
            statusView.locationMapPinImageView.widthAnchor.constraint(equalTo: statusView.locationMapPinImageView.heightAnchor, multiplier: 1.0).priority(.required - 1),
        ])
        statusView.locationLabel.setContentHuggingPriority(.required - 10, for: .vertical)
        statusView.locationMapPinImageView.setContentHuggingPriority(.defaultLow, for: .vertical)
        statusView.locationMapPinImageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        // toolbar
        contentContainerView.addArrangedSubview(statusView.toolbar)
        statusView.toolbar.setContentHuggingPriority(.required - 9, for: .vertical)
    }
    
    private func layoutPlain(statusView: StatusView) {
        // container: V - [ header container | author container | contentTextView | mediaGridContainerView | quoteStatusView | location content | toolbar ]

        // header container: H - [ icon | label ]
        statusView.containerStackView.addArrangedSubview(statusView.headerContainerView)
        statusView.headerIconImageView.translatesAutoresizingMaskIntoConstraints = false
        statusView.headerTextLabel.translatesAutoresizingMaskIntoConstraints = false
        statusView.headerContainerView.addSubview(statusView.headerIconImageView)
        statusView.headerContainerView.addSubview(statusView.headerTextLabel)
        NSLayoutConstraint.activate([
            statusView.headerTextLabel.topAnchor.constraint(equalTo: statusView.headerContainerView.topAnchor),
            statusView.headerTextLabel.bottomAnchor.constraint(equalTo: statusView.headerContainerView.bottomAnchor),
            statusView.headerTextLabel.trailingAnchor.constraint(equalTo: statusView.headerContainerView.trailingAnchor),
            statusView.headerIconImageView.centerYAnchor.constraint(equalTo: statusView.headerTextLabel.centerYAnchor),
            statusView.headerIconImageView.heightAnchor.constraint(equalTo: statusView.headerTextLabel.heightAnchor, multiplier: 1.0).priority(.required - 1),
            statusView.headerIconImageView.widthAnchor.constraint(equalTo: statusView.headerIconImageView.heightAnchor, multiplier: 1.0).priority(.required - 1),
            statusView.headerTextLabel.leadingAnchor.constraint(equalTo: statusView.headerIconImageView.trailingAnchor, constant: 4),
            // align to author name below
        ])
        statusView.headerTextLabel.setContentHuggingPriority(.required - 10, for: .vertical)
        statusView.headerIconImageView.setContentHuggingPriority(.defaultLow, for: .vertical)
        statusView.headerIconImageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        statusView.headerContainerView.isHidden = true

        // author content: H - [ authorAvatarButton | author info content ]
        let authorContentStackView = UIStackView()
        let authorContentStackViewSpacing: CGFloat = 10
        authorContentStackView.axis = .horizontal
        authorContentStackView.spacing = authorContentStackViewSpacing
        statusView.containerStackView.addArrangedSubview(authorContentStackView)

        // authorAvatarButton
        let authorAvatarButtonSize = CGSize(width: 44, height: 44)
        statusView.authorAvatarButton.size = authorAvatarButtonSize
        statusView.authorAvatarButton.avatarImageView.imageViewSize = authorAvatarButtonSize
        statusView.authorAvatarButton.translatesAutoresizingMaskIntoConstraints = false
        authorContentStackView.addArrangedSubview(statusView.authorAvatarButton)
        let authorAvatarButtonWidthFixLayoutConstraint = statusView.authorAvatarButton.widthAnchor.constraint(equalToConstant: authorAvatarButtonSize.width).priority(.required - 1)
        NSLayoutConstraint.activate([
            authorAvatarButtonWidthFixLayoutConstraint,
            statusView.authorAvatarButton.heightAnchor.constraint(equalTo: statusView.authorAvatarButton.widthAnchor, multiplier: 1.0).priority(.required - 1),
        ])
        
        // author info content: V - [ author info headline content | author info sub-headline content ]
        let authorInfoContentStackView = UIStackView()
        authorInfoContentStackView.axis = .vertical
        authorContentStackView.addArrangedSubview(authorInfoContentStackView)
        
        // author info headline content: H - [ authorNameLabel | padding | visibilityImageView (for Mastodon) ]
        let authorInfoHeadlineContentStackView = UIStackView()
        authorInfoHeadlineContentStackView.axis = .horizontal
        authorInfoContentStackView.addArrangedSubview(authorInfoHeadlineContentStackView)
        
        // authorNameLabel
        authorInfoHeadlineContentStackView.addArrangedSubview(statusView.authorNameLabel)
        statusView.authorNameLabel.setContentCompressionResistancePriority(.required - 10, for: .horizontal)
        // padding
        authorInfoHeadlineContentStackView.addArrangedSubview(statusView.authorNameLabel)
        // visibilityImageView
        // TODO:
        
        // set header label align to author name
        NSLayoutConstraint.activate([
            statusView.headerTextLabel.leadingAnchor.constraint(equalTo: statusView.authorAvatarButton.trailingAnchor, constant: authorContentStackViewSpacing),
        ])
        
        // author info sub-headline content: H - [ authorUsernameLabel ]
        let authorInfoSubHeadlineContentStackView = UIStackView()
        authorInfoSubHeadlineContentStackView.axis = .horizontal
        authorInfoContentStackView.addArrangedSubview(authorInfoSubHeadlineContentStackView)
        
        UIContentSizeCategory.publisher
            .sink { category in
                if category >= .extraExtraLarge {
                    authorContentStackView.axis = .vertical
                    authorContentStackView.alignment = .leading // set leading
                } else {
                    authorContentStackView.axis = .horizontal
                    authorContentStackView.alignment = .fill    // restore default
                }
            }
            .store(in: &statusView._disposeBag)
        
        // authorUsernameLabel
        authorInfoSubHeadlineContentStackView.addArrangedSubview(statusView.authorUsernameLabel)

        // contentTextView
        statusView.containerStackView.addArrangedSubview(statusView.contentTextView)
        
        // mediaGridContainerView
        statusView.containerStackView.addArrangedSubview(statusView.mediaGridContainerView)

        // quoteStatusView
        let quoteStatusView = StatusView()
        quoteStatusView.setup(style: .quote)
        statusView.quoteStatusView = quoteStatusView
        statusView.containerStackView.addArrangedSubview(quoteStatusView)
        
        // location content: H - [ locationMapPinImageView | locationLabel ]
        statusView.containerStackView.addArrangedSubview(statusView.locationContainer)
        
        statusView.locationMapPinImageView.translatesAutoresizingMaskIntoConstraints = false
        statusView.locationLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // locationMapPinImageView
        statusView.locationContainer.addArrangedSubview(statusView.locationMapPinImageView)
        // locationLabel
        statusView.locationContainer.addArrangedSubview(statusView.locationLabel)
        
        NSLayoutConstraint.activate([
            statusView.locationMapPinImageView.heightAnchor.constraint(equalTo: statusView.locationLabel.heightAnchor, multiplier: 1.0).priority(.required - 1),
            statusView.locationMapPinImageView.widthAnchor.constraint(equalTo: statusView.locationMapPinImageView.heightAnchor, multiplier: 1.0).priority(.required - 1),
        ])
        statusView.locationLabel.setContentHuggingPriority(.required - 10, for: .vertical)
        statusView.locationMapPinImageView.setContentHuggingPriority(.defaultLow, for: .vertical)
        statusView.locationMapPinImageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        // toolbar
        statusView.containerStackView.addArrangedSubview(statusView.toolbar)
        statusView.toolbar.setContentHuggingPriority(.required - 9, for: .vertical)
    }
    
    private func layoutQuote(statusView: StatusView) {
        // container: V - [ body container ]
        // set `isLayoutMarginsRelativeArrangement` not works with AutoLayout (priority issue)
        // add constraint to workaround
        statusView.containerStackView.backgroundColor = .secondarySystemBackground
        statusView.containerStackView.layer.masksToBounds = true
        statusView.containerStackView.layer.cornerCurve = .continuous
        statusView.containerStackView.layer.cornerRadius = 12
        
        // body container: V - [ author content | content container | contentTextView | mediaGridContainerView ]
        let bodyContainerStackView = UIStackView()
        bodyContainerStackView.axis = .vertical
        bodyContainerStackView.spacing = StatusView.bodyContainerStackViewSpacing
        bodyContainerStackView.translatesAutoresizingMaskIntoConstraints = false
        statusView.containerStackView.addSubview(bodyContainerStackView)
        NSLayoutConstraint.activate([
            bodyContainerStackView.topAnchor.constraint(equalTo: statusView.containerStackView.topAnchor, constant: StatusView.quoteStatusViewContainerLayoutMargin).priority(.required - 1),
            bodyContainerStackView.leadingAnchor.constraint(equalTo: statusView.containerStackView.leadingAnchor, constant: StatusView.quoteStatusViewContainerLayoutMargin).priority(.required - 1),
            statusView.containerStackView.trailingAnchor.constraint(equalTo: bodyContainerStackView.trailingAnchor, constant: StatusView.quoteStatusViewContainerLayoutMargin).priority(.required - 1),
            statusView.containerStackView.bottomAnchor.constraint(equalTo: bodyContainerStackView.bottomAnchor, constant: StatusView.quoteStatusViewContainerLayoutMargin).priority(.required - 1),
        ])
        
        // author content: H - [ authorAvatarButton | authorNameLabel | authorUsernameLabel | padding ]
        let authorContentStackView = UIStackView()
        authorContentStackView.axis = .horizontal
        bodyContainerStackView.alignment = .top
        authorContentStackView.spacing = 6
        bodyContainerStackView.addArrangedSubview(authorContentStackView)
        bodyContainerStackView.setCustomSpacing(4, after: authorContentStackView)
        
        // authorAvatarButton
        statusView.authorAvatarButton.translatesAutoresizingMaskIntoConstraints = false
        authorContentStackView.addArrangedSubview(statusView.authorAvatarButton)
        // authorNameLabel
        authorContentStackView.addArrangedSubview(statusView.authorNameLabel)
        statusView.authorNameLabel.setContentCompressionResistancePriority(.required - 10, for: .horizontal)
        // authorUsernameLabel
        authorContentStackView.addArrangedSubview(statusView.authorUsernameLabel)
        statusView.authorUsernameLabel.setContentCompressionResistancePriority(.required - 11, for: .horizontal)
        // padding
        authorContentStackView.addArrangedSubview(UIView())
        
        NSLayoutConstraint.activate([
            statusView.authorAvatarButton.heightAnchor.constraint(equalTo: statusView.authorNameLabel.heightAnchor, multiplier: 1.0).priority(.required - 10),
            statusView.authorAvatarButton.widthAnchor.constraint(equalTo: statusView.authorNameLabel.heightAnchor, multiplier: 1.0).priority(.required - 10),
        ])
        statusView.authorAvatarButton.setContentHuggingPriority(.defaultLow - 10, for: .vertical)
        statusView.authorAvatarButton.setContentHuggingPriority(.defaultLow - 10, for: .horizontal)
        statusView.authorAvatarButton.setContentCompressionResistancePriority(.defaultLow - 10, for: .vertical)
        statusView.authorAvatarButton.setContentCompressionResistancePriority(.defaultLow - 10, for: .horizontal)
        statusView.authorNameLabel.setContentCompressionResistancePriority(.required - 1, for: .vertical)
        statusView.authorNameLabel.setContentHuggingPriority(.required - 1, for: .vertical)

        // contentTextView
        statusView.contentTextView.translatesAutoresizingMaskIntoConstraints = false
        bodyContainerStackView.addArrangedSubview(statusView.contentTextView)
        statusView.contentTextView.setContentHuggingPriority(.required - 10, for: .vertical)
        statusView.contentTextView.textAttributes = [
            .font: UIFont.preferredFont(forTextStyle: .callout),
            .foregroundColor: UIColor.secondaryLabel,
        ]
        statusView.contentTextView.linkAttributes = [
            .font: UIFont.preferredFont(forTextStyle: .callout),
            .foregroundColor: Asset.Colors.Theme.daylight.color
        ]
        
        // mediaGridContainerView
        statusView.mediaGridContainerView.translatesAutoresizingMaskIntoConstraints = false
        bodyContainerStackView.addArrangedSubview(statusView.mediaGridContainerView)
    }
    
}

extension StatusView {
    
    private func update(theme: Theme) {
        headerIconImageView.tintColor = theme.accentColor
    }
    
    func setHeaderDisplay() {
        headerContainerView.isHidden = false
    }
    
    func setMediaDisplay() {
        mediaGridContainerView.isHidden = false
    }
    
    func setQuoteDisplay() {
        quoteStatusView?.isHidden = false
    }
    
    func setLocationDisplay() {
        locationContainer.isHidden = false
    }
    
    // content text Width
    var contentMaxLayoutWidth: CGFloat {
        let inset = contentLayoutInset
        return frame.width - inset.left - inset.right
    }
    
    var contentLayoutInset: UIEdgeInsets {
        guard let style = style else {
            assertionFailure("Needs setup style before use")
            return .zero
        }
        
        switch style {
        case .inline:
            let left = authorAvatarButton.size.width + StatusView.bodyContainerStackViewSpacing
            return UIEdgeInsets(top: 0, left: left, bottom: 0, right: 0)
        case .plain:
            return .zero
        case .quote:
            let margin = StatusView.quoteStatusViewContainerLayoutMargin
            return UIEdgeInsets(top: 0, left: margin, bottom: 0, right: margin)
        }
    }

}

extension StatusView {
    @objc private func headerTapGestureRecognizerHandler(_ sender: UITapGestureRecognizer) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        delegate?.statusView(self, headerDidPressed: headerContainerView)
    }
    
    @objc private func authorAvatarButtonDidPressed(_ button: UIButton) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        delegate?.statusView(self, authorAvatarButtonDidPressed: authorAvatarButton)
    }
}

// MARK: - MediaGridContainerViewDelegate
extension StatusView: MediaGridContainerViewDelegate {
    func mediaGridContainerView(_ container: MediaGridContainerView, didTapMediaView mediaView: MediaView, at index: Int) {
        delegate?.statusView(self, mediaGridContainerView: container, didTapMediaView: mediaView, at: index)
    }
}

// MARK: - StatusToolbarDelegate
extension StatusView: StatusToolbarDelegate {
    func statusToolbar(_ statusToolbar: StatusToolbar, actionDidPressed action: StatusToolbar.Action) {
        delegate?.statusView(self, statusToolbar: statusToolbar, actionDidPressed: action)
    }
}

// MARK: - StatusViewDelegate
// relay for quoteStatsView
extension StatusView: StatusViewDelegate {
    func statusView(_ statusView: StatusView, headerDidPressed header: UIView) {
        assertionFailure()
    }
    
    func statusView(_ statusView: StatusView, authorAvatarButtonDidPressed button: AvatarButton) {
        guard statusView === quoteStatusView else {
            assertionFailure()
            return
        }
        
        delegate?.statusView(self, quoteStatusView: statusView, authorAvatarButtonDidPressed: button)
    }
    
    func statusView(_ statusView: StatusView, quoteStatusView: StatusView, authorAvatarButtonDidPressed button: AvatarButton) {
        assertionFailure()
    }
    
    func statusView(_ statusView: StatusView, mediaGridContainerView containerView: MediaGridContainerView, didTapMediaView mediaView: MediaView, at index: Int) {
        guard statusView === quoteStatusView else {
            assertionFailure()
            return
        }
        
        delegate?.statusView(self, quoteStatusView: statusView, mediaGridContainerView: containerView, didTapMediaView: mediaView, at: index)
    }
    
    func statusView(_ statusView: StatusView, quoteStatusView: StatusView, mediaGridContainerView containerView: MediaGridContainerView, didTapMediaView mediaView: MediaView, at index: Int) {
        assertionFailure()
    }
    
    func statusView(_ statusView: StatusView, statusToolbar: StatusToolbar, actionDidPressed action: StatusToolbar.Action) {
        assertionFailure()
    }
    
}
