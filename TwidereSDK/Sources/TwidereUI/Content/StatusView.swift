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
import SwiftUI
import Kingfisher
import MetaTextKit
import MetaTextArea
import MetaLabel
import TwidereCore

public protocol StatusViewDelegate: AnyObject {
//    func statusView(_ statusView: StatusView, headerDidPressed header: UIView)
//
//    func statusView(_ statusView: StatusView, authorAvatarButtonDidPressed button: AvatarButton)
//    func statusView(_ statusView: StatusView, quoteStatusView: StatusView, authorAvatarButtonDidPressed button: AvatarButton)
//
//    func statusView(_ statusView: StatusView, expandContentButtonDidPressed button: UIButton)
    func statusView(_ viewModel: StatusView.ViewModel, toggleContentDisplay isReveal: Bool)

//
//    func statusView(_ statusView: StatusView, metaTextAreaView: MetaTextAreaView, didSelectMeta meta: Meta)
//    func statusView(_ statusView: StatusView, quoteStatusView: StatusView, metaTextAreaView: MetaTextAreaView, didSelectMeta meta: Meta)

    // media
    func statusView(_ viewModel: StatusView.ViewModel, previewActionForMediaViewModel mediaViewModel: MediaView.ViewModel)
    func statusView(_ viewModel: StatusView.ViewModel, previewActionForMediaViewModel mediaViewModel: MediaView.ViewModel, previewActionContext: ContextMenuInteractionPreviewActionContext)
    func statusView(_ viewModel: StatusView.ViewModel, toggleContentWarningOverlayDisplay isReveal: Bool)
//    func statusView(_ statusView: StatusView, quoteStatusView: StatusView, mediaGridContainerView containerView: MediaGridContainerView, didTapMediaView mediaView: MediaView, at index: Int)
//
    func statusView(_ viewModel: StatusView.ViewModel, pollVoteActionForViewModel pollViewModel: PollView.ViewModel)
    func statusView(_ viewModel: StatusView.ViewModel, pollUpdateIfNeedsForViewModel pollViewModel: PollView.ViewModel)
    func statusView(_ viewModel: StatusView.ViewModel, pollViewModel: PollView.ViewModel, pollOptionDidSelectForViewModel optionViewModel: PollOptionView.ViewModel)

//    func statusView(_ statusView: StatusView, quoteStatusViewDidPressed quoteStatusView: StatusView)
//
    func statusView(_ viewModel: StatusView.ViewModel, statusToolbarViewModel: StatusToolbarView.ViewModel, statusToolbarButtonDidPressed action: StatusToolbarView.Action)
//    func statusView(_ statusView: StatusView, statusToolbar: StatusToolbar, menuActionDidPressed action: StatusToolbar.MenuAction, menuButton button: UIButton)
//
//    func statusView(_ statusView: StatusView, translateButtonDidPressed button: UIButton)
    
    func statusView(_ viewModel: StatusView.ViewModel, viewHeightDidChange: Void)

//
//    // a11y
//    func statusView(_ statusView: StatusView, accessibilityActivate: Void)
}

public struct StatusView: View {
    
    static let logger = Logger(subsystem: "StatusView", category: "View")
    var logger: Logger { StatusView.logger }
    
    static var hangingAvatarButtonDimension: CGFloat { 44.0 }
    static var hangingAvatarButtonTrailingSapcing: CGFloat { 10.0 }
    
    @ObservedObject public private(set) var viewModel: ViewModel
    
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @State private var visibilityIconImageDimension = CGFloat.zero
    
    public init(viewModel: StatusView.ViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack {
            if let repostViewModel = viewModel.repostViewModel {
                // header
                if let statusHeaderViewModel = repostViewModel.statusHeaderViewModel {
                    StatusHeaderView(viewModel: statusHeaderViewModel)
                }
                // post
                StatusView(viewModel: repostViewModel)
            } else {
                HStack(alignment: .top, spacing: .zero) {
                    if viewModel.hasHangingAvatar {
                        avatarButton
                            .padding(.trailing, StatusView.hangingAvatarButtonTrailingSapcing)
                    }
                    let contentSpacing: CGFloat = 4
                    VStack(spacing: contentSpacing) {
                        // authorView
                        authorView
                            .padding(.horizontal, viewModel.margin)
                        if viewModel.spoilerContent != nil {
                            spoilerContentView
                                .padding(.horizontal, viewModel.margin)
                            if !viewModel.isContentEmpty {
                                Button {
                                    // force to trigger view update without animation
                                    withAnimation(.none) {
                                        viewModel.isContentSensitiveToggled.toggle()
                                    }
                                    viewModel.delegate?.statusView(viewModel, toggleContentDisplay: !viewModel.isContentReveal)
                                } label: {
                                    HStack {
                                        Image(uiImage: Asset.Editing.ellipsisLarge.image.withRenderingMode(.alwaysTemplate))
                                            .background(Color(uiColor: .tertiarySystemFill))
                                            .clipShape(Capsule())
                                        Spacer()
                                    }
                                }
                                .buttonStyle(.borderless)
                                .id(UUID())     // fix animation issue
                                .padding(.horizontal, viewModel.margin)
                            }
                        }
                        // content
                        if viewModel.isContentReveal {
                            contentView
                                .padding(.horizontal, viewModel.margin)
                        }
                        // media
                        if !viewModel.mediaViewModels.isEmpty {
                            MediaGridContainerView(
                                viewModels: viewModel.mediaViewModels,
                                idealWidth: contentWidth,
                                idealHeight: 280,
                                previewAction: { mediaViewModel in
                                    viewModel.delegate?.statusView(viewModel, previewActionForMediaViewModel: mediaViewModel)
                                },
                                previewActionWithContext: { mediaViewModel, context in
                                    viewModel.delegate?.statusView(viewModel, previewActionForMediaViewModel: mediaViewModel, previewActionContext: context)
                                }
                            )
                            .clipShape(RoundedRectangle(cornerRadius: MediaGridContainerView.cornerRadius))
                            .overlay {
                                ContentWarningOverlayView(isReveal: viewModel.isMediaContentWarningOverlayReveal) {
                                    viewModel.delegate?.statusView(viewModel, toggleContentWarningOverlayDisplay: !viewModel.isMediaContentWarningOverlayReveal)
                                }
                                .cornerRadius(MediaGridContainerView.cornerRadius)
                            }
                            .padding(.horizontal, viewModel.margin)
                        }
                        // poll
                        if let pollViewModel = viewModel.pollViewModel {
                            PollView(
                                viewModel: pollViewModel,
                                selectAction: { optionViewModel in
                                    viewModel.delegate?.statusView(viewModel, pollViewModel: pollViewModel, pollOptionDidSelectForViewModel: optionViewModel)
                                }, voteAction: { pollViewModel in
                                    viewModel.delegate?.statusView(viewModel, pollVoteActionForViewModel: pollViewModel)
                                }
                            )
                            .padding(.horizontal, viewModel.margin)
                            .onAppear {
                                viewModel.delegate?.statusView(viewModel, pollUpdateIfNeedsForViewModel: pollViewModel)
                            }
                        }
                        // quote
                        if let quoteViewModel = viewModel.quoteViewModel {
                            StatusView(viewModel: quoteViewModel)
                                .background {
                                    Color(uiColor: .label.withAlphaComponent(0.04))
                                }
                                .cornerRadius(12)
                        }
                        if viewModel.hasToolbar {
                            toolbarView
                                .padding(.top, -contentSpacing)
                        }
                    }   // end VStack
                    .overlay(alignment: .bottom) {
                        switch viewModel.kind {
                        case .timeline, .repost, .conversationRoot, .conversationThread:
                            VStack(spacing: .zero) {
                                Spacer()
                                Divider()
                                Color.clear
                                    .frame(height: 1)
                            }
                        default:
                            EmptyView()
                        }
                    }
                }   // end HStack
                .padding(.top, viewModel.margin)                                    // container margin
                .padding(.bottom, viewModel.hasToolbar ? .zero : viewModel.margin)  // container margin
                .overlay {
                    if viewModel.isBottomConversationLinkLineViewDisplay {
                        HStack(alignment: .top, spacing: .zero) {
                            VStack(spacing: 0) {
                                Color.clear
                                    .frame(width: StatusView.hangingAvatarButtonDimension, height: StatusView.hangingAvatarButtonDimension)
                                Rectangle()
                                    .foregroundColor(Color(uiColor: .separator))
                                    .background(.clear)
                                    .frame(width: 1)
                            }
                            Spacer()
                        }   // end HStack
                    }   // end if
                }   // end overlay
            }   // end if … else …
        }   // end VStack
        .padding(.top, viewModel.cellTopMargin)
        .onReceive(viewModel.$isContentSensitiveToggled) { _ in
            // trigger tableView reload to update the cell height
            viewModel.delegate?.statusView(viewModel, viewHeightDidChange: Void())
        }
    }

}

extension StatusView {
    var contentWidth: CGFloat {
        let width: CGFloat = {
            switch viewModel.kind {
            case .conversationRoot:
                return viewModel.viewLayoutFrame.readableContentLayoutFrame.width - 2 * viewModel.margin
            default:
                return viewModel.viewLayoutFrame.readableContentLayoutFrame.width - 2 * viewModel.margin - StatusView.hangingAvatarButtonDimension - StatusView.hangingAvatarButtonTrailingSapcing
            }
        }()
        return max(width, .leastNonzeroMagnitude)
    }
    
    public var authorView: some View {
        HStack(alignment: .center) {
            if !viewModel.hasHangingAvatar {
                // avatar
                avatarButton
            }
            // info
            let infoLayout = dynamicTypeSize < .accessibility1 ?
                AnyLayout(HStackLayout(alignment: .center, spacing: 6)) :
                AnyLayout(VStackLayout(alignment: .leading, spacing: .zero))
            infoLayout {
                let nameLayout = dynamicTypeSize < .accessibility1 ?
                    AnyLayout(HStackLayout(alignment: .bottom, spacing: 6)) :
                    AnyLayout(VStackLayout(alignment: .leading, spacing: .zero))
                nameLayout {
                    // name
                    LabelRepresentable(
                        metaContent: viewModel.authorName,
                        textStyle: .statusAuthorName,
                        setupLabel: { label in
                            label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
                            label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
                        }
                    )
                    .fixedSize(horizontal: false, vertical: true)
                    .layoutPriority(0.618)
                    // username
                    LabelRepresentable(
                        metaContent: PlaintextMetaContent(string: "@" + viewModel.authorUsernme),
                        textStyle: .statusAuthorUsername,
                        setupLabel: { label in
                            label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
                            label.setContentCompressionResistancePriority(.defaultLow - 100, for: .horizontal)
                        }
                    )
                    .fixedSize(horizontal: false, vertical: true)
                    .layoutPriority(0.382)
                }
                .frame(alignment: .leading)
                Spacer()
                HStack(spacing: 6) {
                    // mastodon visibility
                    if let visibilityIconImage = viewModel.visibilityIconImage, visibilityIconImageDimension > 0 {
                        let dimension = ceil(visibilityIconImageDimension * 0.8)
                        Color.clear
                            .frame(width: dimension)
                            .overlay {
                                VectorImageView(image: visibilityIconImage, tintColor: TextStyle.statusTimestamp.textColor)
                                    .frame(width: dimension, height: dimension)
                            }
                    }
                    // timestamp
                    if let timestampLabelViewModel = viewModel.timestampLabelViewModel {
                        TimestampLabelView(viewModel: timestampLabelViewModel)
                            .background(GeometryReader { proxy in
                                Color.clear.preference(
                                    key: ViewHeightKey.self,
                                    value: proxy.frame(in: .local).size.height
                                )
                            })
                            .onPreferenceChange(ViewHeightKey.self) { height in
                                self.visibilityIconImageDimension = height
                            }
                    }
                }
            }
            .background(GeometryReader { proxy in
                Color.clear.preference(
                    key: ViewHeightKey.self,
                    value: proxy.frame(in: .local).size.height
                )
            })
            .onPreferenceChange(ViewHeightKey.self) { height in
                self.viewModel.authorAvatarDimension = height
            }
            // add spacer to make the infoLayout leading align
            if dynamicTypeSize < .accessibility1 {
                // do nothing
            } else {
                Spacer()
            }
        }   // end HStack
    }
    
    public var avatarButton: some View {
        Button {
            
        } label: {
            let dimension: CGFloat = {
                switch viewModel.kind {
                case .quote:
                    return viewModel.authorAvatarDimension
                default:
                    return StatusView.hangingAvatarButtonDimension
                }
            }()
            KFImage(viewModel.avatarURL)
                .placeholder { progress in
                    Color(uiColor: .placeholderText)
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: dimension, height: dimension)
                .clipShape(Circle())
        }
        .buttonStyle(.borderless)
    }
    
    public var spoilerContentView: some View {
        VStack(alignment: .leading, spacing: .zero) {
            TextViewRepresentable(
                metaContent: viewModel.spoilerContent ?? PlaintextMetaContent(string: ""),
                textStyle: .statusContent,
                width: contentWidth
            )
            .frame(width: contentWidth)
        }
    }
    
    public var contentView: some View {
        VStack(alignment: .leading, spacing: .zero) {
            TextViewRepresentable(
                metaContent: viewModel.content,
                textStyle: .statusContent,
                width: contentWidth
            )
            .frame(width: contentWidth)
        }
    }
    
    var toolbarView: some View {
        StatusToolbarView(
            viewModel: viewModel.toolbarViewModel,
            menuActions: {
                var actions: [StatusToolbarView.Action] = []
                // copyText
                actions.append(.copyText)
                // copyLink
                actions.append(.copyLink)
                // shareLink
                actions.append(.shareLink)
                // save media
                if !viewModel.mediaViewModels.isEmpty {
                    actions.append(.saveMedia)
                }
                // translate
                actions.append(.translate)
                if viewModel.canDelete {
                    actions.append(.delete)
                }
                return actions
            }(),
            handler: { action in
                viewModel.delegate?.statusView(
                    viewModel,
                    statusToolbarViewModel: viewModel.toolbarViewModel,
                    statusToolbarButtonDidPressed: action
                )
            }
        )
        .frame(height: 48)
    }
}

//public final class StatusView: UIView {
//    
//    private var _disposeBag = Set<AnyCancellable>() // which lifetime same to view scope
//    public var disposeBag = Set<AnyCancellable>()          // clear when reuse
//    
//    public weak var delegate: StatusViewDelegate?
//
//    public static let bodyContainerStackViewSpacing: CGFloat = 10
//    public static let quoteStatusViewContainerLayoutMargin: CGFloat = 12
//    
//    let logger = Logger(subsystem: "StatusView", category: "View")
//    
//    public private(set) var style: Style?
//    
//    public private(set) lazy var viewModel: ViewModel = {
//        let viewModel = ViewModel()
//        viewModel.bind(statusView: self)
//        return viewModel
//    }()
//    
//    // container
//    public let containerStackView: UIStackView = {
//        let stackView = UIStackView()
//        stackView.axis = .vertical
//        stackView.spacing = 8
//        return stackView
//    }()
//    
//    // header
//    public let headerContainerView = UIView()
//    public let headerIconImageView = UIImageView()
//    public static var headerTextLabelStyle: TextStyle { .statusHeader }
//    public let headerTextLabel: MetaLabel = {
//        let label = MetaLabel(style: .statusHeader)
//        label.isUserInteractionEnabled = false
//        return label
//    }()
//    
//    // avatar
//    public let authorAvatarButton = AvatarButton()
//    
//    // author
//    public static var authorNameLabelStyle: TextStyle { .statusAuthorName }
//    public let authorNameLabel: MetaLabel = {
//        let label = MetaLabel(style: StatusView.authorNameLabelStyle)
//        label.accessibilityTraits = .staticText
//        return label
//    }()
//    public let lockImageView: UIImageView = {
//        let imageView = UIImageView()
//        imageView.tintColor = .secondaryLabel
//        imageView.contentMode = .scaleAspectFill
//        imageView.image = Asset.ObjectTools.lockMiniInline.image.withRenderingMode(.alwaysTemplate)
//        return imageView
//    }()
//    public let authorUsernameLabel = PlainLabel(style: .statusAuthorUsername)
//    public let visibilityImageView: UIImageView = {
//        let imageView = UIImageView()
//        imageView.tintColor = .secondaryLabel
//        imageView.contentMode = .scaleAspectFill
//        imageView.image = Asset.ObjectTools.globeMiniInline.image.withRenderingMode(.alwaysTemplate)
//        return imageView
//    }()
//    public let timestampLabel = PlainLabel(style: .statusTimestamp)
//    
//    // spoiler
//    public let spoilerContentTextView: MetaTextAreaView = {
//        let textView = MetaTextAreaView()
//        textView.textAttributes = [
//            .font: UIFont.preferredFont(forTextStyle: .body),
//            .foregroundColor: UIColor.label.withAlphaComponent(0.8),
//        ]
//        textView.linkAttributes = [
//            .font: UIFont.preferredFont(forTextStyle: .body),
//            .foregroundColor: Asset.Colors.Theme.daylight.color
//        ]
//        return textView
//    }()
//    
//    public let expandContentButtonContainer: UIStackView = {
//        let stackView = UIStackView()
//        stackView.axis = .horizontal
//        stackView.alignment = .leading
//        return stackView
//    }()
//    public let expandContentButton: HitTestExpandedButton = {
//        let button = HitTestExpandedButton(type: .system)
//        button.setImage(Asset.Editing.ellipsisLarge.image.withRenderingMode(.alwaysTemplate), for: .normal)
//        button.layer.masksToBounds = true
//        button.layer.cornerRadius = 10
//        button.layer.cornerCurve = .circular
//        button.backgroundColor = .tertiarySystemFill
//        return button
//    }()
//    
//    // content
//    public let contentTextView: MetaTextAreaView = {
//        let textView = MetaTextAreaView()
//        textView.textAttributes = [
//            .font: UIFont.preferredFont(forTextStyle: .body),
//            .foregroundColor: UIColor.label.withAlphaComponent(0.8),
//        ]
//        textView.linkAttributes = [
//            .font: UIFont.preferredFont(forTextStyle: .body),
//            .foregroundColor: Asset.Colors.Theme.daylight.color
//        ]
//        return textView
//    }()
//    
//    // translate
//    let translateButtonContainer = UIStackView()
//    public let translateButton: UIButton = {
//        let button = HitTestExpandedButton(type: .system)
//        button.titleLabel?.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 14, weight: .medium))
//        button.setTitle(L10n.Common.Controls.Status.Actions.translate, for: .normal)
//        return button
//    }()
//    
//    // media
//    public let mediaGridContainerView = MediaGridContainerView()
//    
//    // poll
//    public let pollTableView: UITableView = {
//        let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
//        tableView.register(PollOptionTableViewCell.self, forCellReuseIdentifier: String(describing: PollOptionTableViewCell.self))
//        tableView.isScrollEnabled = false
//        tableView.estimatedRowHeight = 36
//        tableView.tableFooterView = UIView()
//        tableView.backgroundColor = .clear
//        tableView.separatorStyle = .none
//        return tableView
//    }()
//    public var pollTableViewHeightLayoutConstraint: NSLayoutConstraint!
//    public var pollTableViewDiffableDataSource: UITableViewDiffableDataSource<PollSection, PollItem>?
//    
//    public let pollVoteInfoContainerView = UIStackView()
//    public let pollVoteDescriptionLabel = PlainLabel(style: .pollVoteDescription)
//    public let pollVoteButton: HitTestExpandedButton = {
//        let button = HitTestExpandedButton(type: .system)
//        button.setTitle(L10n.Common.Controls.Status.Actions.vote, for: .normal)
//        button.setTitleColor(Asset.Colors.hightLight.color, for: .normal)
//        button.setTitleColor(.secondaryLabel, for: .disabled)
//        return button
//    }()
//    public let pollVoteActivityIndicatorView: UIActivityIndicatorView = {
//        let activityIndicatorView = UIActivityIndicatorView(style: .medium)
//        activityIndicatorView.hidesWhenStopped = true
//        activityIndicatorView.tintColor = .secondaryLabel
//        return activityIndicatorView
//    }()
//    
//    // quote
//    public private(set) var quoteStatusView: StatusView? {
//        didSet {
//            if let quoteStatusView = quoteStatusView {
//                quoteStatusView.delegate = self
//                
//                let quoteTapGestureRecognizer = UITapGestureRecognizer.singleTapGestureRecognizer
//                quoteTapGestureRecognizer.delegate = self
//                quoteTapGestureRecognizer.addTarget(self, action: #selector(StatusView.quoteStatusViewDidPressed(_:)))
//                quoteStatusView.addGestureRecognizer(quoteTapGestureRecognizer)
//            }
//        }
//    }
//    
//    // location
//    public let locationContainer: UIStackView = {
//        let stackView = UIStackView()
//        stackView.axis = .horizontal
//        stackView.spacing = 6
//        return stackView
//    }()
//    public let locationMapPinImageView: UIImageView = {
//        let imageView = UIImageView()
//        imageView.tintColor = .secondaryLabel
//        return imageView
//    }()
//    public let locationLabel = PlainLabel(style: .statusLocation)
//
//    // metrics
//    public let metricsDashboardView = StatusMetricsDashboardView()
//    
//    // toolbar
//    public let toolbar = StatusToolbar()
//    
//    // reply settings
//    public let replySettingBannerView = ReplySettingBannerView()
//    
//    public override init(frame: CGRect) {
//        super.init(frame: frame)
//        _init()
//    }
//    
//    public required init?(coder: NSCoder) {
//        super.init(coder: coder)
//        _init()
//    }
//    
//    public override func willMove(toWindow newWindow: UIWindow?) {
//        super.willMove(toWindow: newWindow)
//        assert(style != nil, "Needs setup style before use")
//    }
//    
//    deinit {
//        viewModel.disposeBag.removeAll()
//    }
//    
//}
//
//extension StatusView {
//    
//    public func prepareForReuse() {
//        disposeBag.removeAll()
//        viewModel.objects.removeAll()
//        viewModel.authorAvatarImageURL = nil
//        authorAvatarButton.avatarImageView.cancelTask()
//        quoteStatusView?.prepareForReuse()
//        mediaGridContainerView.prepareForReuse()
//        if var snapshot = pollTableViewDiffableDataSource?.snapshot() {
//            snapshot.deleteAllItems()
//            pollTableViewDiffableDataSource?.applySnapshotUsingReloadData(snapshot)
//        }
//        Style.prepareForReuse(statusView: self)
//    }
//    
//    private func _init() {
//        containerStackView.translatesAutoresizingMaskIntoConstraints = false
//        addSubview(containerStackView)
//        NSLayoutConstraint.activate([
//            containerStackView.topAnchor.constraint(equalTo: topAnchor),
//            containerStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
//            containerStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
//            containerStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
//        ])
//        
//        // header
//        let headerTapGestureRecognizer = UITapGestureRecognizer.singleTapGestureRecognizer
//        headerTapGestureRecognizer.addTarget(self, action: #selector(StatusView.headerTapGestureRecognizerHandler(_:)))
//        headerContainerView.addGestureRecognizer(headerTapGestureRecognizer)
//        
//        // avatar button
//        authorAvatarButton.accessibilityLabel = L10n.Accessibility.Common.Status.authorAvatar
//        authorAvatarButton.accessibilityHint = L10n.Accessibility.VoiceOver.doubleTapToOpenProfile
//        authorAvatarButton.addTarget(self, action: #selector(StatusView.authorAvatarButtonDidPressed(_:)), for: .touchUpInside)
//        
//        // expand content
//        expandContentButton.addTarget(self, action: #selector(StatusView.expandContentButtonDidPressed(_:)), for: .touchUpInside)
//        
//        // content
//        contentTextView.delegate = self
//        
//        // translateButton
//        translateButton.addTarget(self, action: #selector(StatusView.translateButtonDidPressed(_:)), for: .touchUpInside)
//        
//        // media grid
//        mediaGridContainerView.delegate = self
//        
//        // poll
//        pollTableView.translatesAutoresizingMaskIntoConstraints = false
//        pollTableViewHeightLayoutConstraint = pollTableView.heightAnchor.constraint(equalToConstant: 36).priority(.required - 10)
//        NSLayoutConstraint.activate([
//            pollTableViewHeightLayoutConstraint,
//        ])
//        pollTableView.delegate = self
//        pollVoteButton.addTarget(self, action: #selector(StatusView.pollVoteButtonDidPressed(_:)), for: .touchUpInside)
//        
//        // toolbar
//        toolbar.delegate = self
//        
//        // theme
//        ThemeService.shared.theme
//            .sink { [weak self] theme in
//                guard let self = self else { return }
//                self.update(theme: theme)
//            }
//            .store(in: &disposeBag)
//    }
//    
//    public func setup(style: Style) {
//        guard self.style == nil else {
//            assertionFailure("Should only setup once")
//            return
//        }
//        self.style = style
//        style.layout(statusView: self)
//        Style.prepareForReuse(statusView: self)
//    }
//    
//}
//
//extension StatusView {
//    public enum Style {
//        case inline             // for timeline
//        case plain              // for thread
//        case quote              // for quote
//        case composeReply       // for compose
//        
//        func layout(statusView: StatusView) {
//            switch self {
//            case .inline:           layoutInline(statusView: statusView)
//            case .plain:            layoutPlain(statusView: statusView)
//            case .quote:            layoutQuote(statusView: statusView)
//            case .composeReply:     layoutComposeReply(statusView: statusView)
//            }
//        }
//        
//        static func prepareForReuse(statusView: StatusView) {
//            statusView.headerContainerView.isHidden = true
//            statusView.lockImageView.isHidden = true
//            statusView.visibilityImageView.isHidden = true
//            statusView.spoilerContentTextView.isHidden = true
//            statusView.expandContentButtonContainer.isHidden = true
//            statusView.translateButtonContainer.isHidden = true
//            statusView.mediaGridContainerView.isHidden = true
//            statusView.pollTableView.isHidden = true
//            statusView.pollVoteInfoContainerView.isHidden = true
//            statusView.pollVoteActivityIndicatorView.isHidden = true
//            statusView.quoteStatusView?.isHidden = true
//            statusView.locationContainer.isHidden = true
//            statusView.replySettingBannerView.isHidden = true
//        }
//    }
//}
//
//extension StatusView.Style {
//    
//    private func layoutInline(statusView: StatusView) {
//        // container: V - [ header container | body container ]
//        
//        // header container: H - [ icon | label ]
//        statusView.containerStackView.addArrangedSubview(statusView.headerContainerView)
//        statusView.headerIconImageView.translatesAutoresizingMaskIntoConstraints = false
//        statusView.headerTextLabel.translatesAutoresizingMaskIntoConstraints = false
//        statusView.headerContainerView.addSubview(statusView.headerIconImageView)
//        statusView.headerContainerView.addSubview(statusView.headerTextLabel)
//        NSLayoutConstraint.activate([
//            statusView.headerTextLabel.topAnchor.constraint(equalTo: statusView.headerContainerView.topAnchor),
//            statusView.headerTextLabel.bottomAnchor.constraint(equalTo: statusView.headerContainerView.bottomAnchor),
//            statusView.headerTextLabel.trailingAnchor.constraint(equalTo: statusView.headerContainerView.trailingAnchor),
//            statusView.headerIconImageView.centerYAnchor.constraint(equalTo: statusView.headerTextLabel.centerYAnchor),
//            statusView.headerIconImageView.heightAnchor.constraint(equalTo: statusView.headerTextLabel.heightAnchor, multiplier: 1.0).priority(.required - 1),
//            statusView.headerIconImageView.widthAnchor.constraint(equalTo: statusView.headerIconImageView.heightAnchor, multiplier: 1.0).priority(.required - 1),
//            statusView.headerTextLabel.leadingAnchor.constraint(equalTo: statusView.headerIconImageView.trailingAnchor, constant: 4),
//            // align to author name below
//        ])
//        statusView.headerTextLabel.setContentHuggingPriority(.required - 10, for: .vertical)
//        statusView.headerIconImageView.setContentHuggingPriority(.defaultLow, for: .vertical)
//        statusView.headerIconImageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
//        
//        // body container: H - [ authorAvatarButton | content container ]
//        let bodyContainerStackView = UIStackView()
//        bodyContainerStackView.axis = .horizontal
//        bodyContainerStackView.spacing = StatusView.bodyContainerStackViewSpacing
//        bodyContainerStackView.alignment = .top
//        statusView.containerStackView.addArrangedSubview(bodyContainerStackView)
//        
//        // authorAvatarButton
//        let authorAvatarButtonSize = CGSize(width: 44, height: 44)
//        statusView.authorAvatarButton.size = authorAvatarButtonSize
//        statusView.authorAvatarButton.avatarImageView.imageViewSize = authorAvatarButtonSize
//        statusView.authorAvatarButton.translatesAutoresizingMaskIntoConstraints = false
//        bodyContainerStackView.addArrangedSubview(statusView.authorAvatarButton)
//        NSLayoutConstraint.activate([
//            statusView.authorAvatarButton.widthAnchor.constraint(equalToConstant: authorAvatarButtonSize.width).priority(.required - 1),
//            statusView.authorAvatarButton.heightAnchor.constraint(equalToConstant: authorAvatarButtonSize.height).priority(.required - 1),
//        ])
//        
//        // content container: V - [ author content | contentTextView | mediaGridContainerView | quoteStatusView | … | location content | toolbar ]
//        let contentContainerView = UIStackView()
//        contentContainerView.axis = .vertical
//        contentContainerView.spacing = 10
//        bodyContainerStackView.addArrangedSubview(contentContainerView)
//        
//        // author content: H - [ authorNameLabel | lockImageView | authorUsernameLabel | padding | visibilityImageView (for Mastodon) | timestampLabel ]
//        let authorContentStackView = UIStackView()
//        authorContentStackView.axis = .horizontal
//        authorContentStackView.spacing = 6
//        contentContainerView.addArrangedSubview(authorContentStackView)
//        contentContainerView.setCustomSpacing(4, after: authorContentStackView)
//        UIContentSizeCategory.publisher
//            .sink { category in
//                authorContentStackView.axis = category > .accessibilityLarge ? .vertical : .horizontal
//                authorContentStackView.alignment = category > .accessibilityLarge ? .leading : .fill
//            }
//            .store(in: &statusView._disposeBag)
//        
//        // authorNameLabel
//        authorContentStackView.addArrangedSubview(statusView.authorNameLabel)
//        statusView.authorNameLabel.setContentHuggingPriority(.required - 10, for: .horizontal)
//        statusView.authorNameLabel.setContentCompressionResistancePriority(.required - 10, for: .horizontal)
//        // lockImageView
//        statusView.lockImageView.translatesAutoresizingMaskIntoConstraints = false
//        authorContentStackView.addArrangedSubview(statusView.lockImageView)
//        // authorUsernameLabel
//        authorContentStackView.addArrangedSubview(statusView.authorUsernameLabel)
//        NSLayoutConstraint.activate([
//            statusView.lockImageView.heightAnchor.constraint(equalTo: statusView.authorUsernameLabel.heightAnchor).priority(.required - 10),
//        ])
//        statusView.lockImageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
//        statusView.lockImageView.setContentCompressionResistancePriority(.required - 10, for: .horizontal)
//        statusView.authorUsernameLabel.setContentCompressionResistancePriority(.required - 11, for: .horizontal)
//        // padding
//        authorContentStackView.addArrangedSubview(UIView())
//        // visibilityImageView
//        authorContentStackView.addArrangedSubview(statusView.visibilityImageView)
//        statusView.visibilityImageView.setContentHuggingPriority(.required - 9, for: .horizontal)
//        statusView.visibilityImageView.setContentCompressionResistancePriority(.required - 9, for: .horizontal)
//        // timestampLabel
//        authorContentStackView.addArrangedSubview(statusView.timestampLabel)
//        statusView.timestampLabel.setContentHuggingPriority(.required - 8, for: .horizontal)
//        statusView.timestampLabel.setContentCompressionResistancePriority(.required - 8, for: .horizontal)
//        
//        // set header label align to author name
//        NSLayoutConstraint.activate([
//            statusView.headerTextLabel.leadingAnchor.constraint(equalTo: statusView.authorNameLabel.leadingAnchor),
//        ])
//        
//        // spoilerContentTextView
//        contentContainerView.addArrangedSubview(statusView.spoilerContentTextView)
//        statusView.spoilerContentTextView.setContentHuggingPriority(.required - 9, for: .vertical)
//        statusView.spoilerContentTextView.setContentCompressionResistancePriority(.required - 10, for: .vertical)
//        
//        contentContainerView.addArrangedSubview(statusView.expandContentButtonContainer)
//        statusView.expandContentButton.translatesAutoresizingMaskIntoConstraints = false
//        statusView.expandContentButtonContainer.addArrangedSubview(statusView.expandContentButton)
//        statusView.expandContentButtonContainer.addArrangedSubview(UIView())
//        
//        // contentTextView
//        // statusView.contentTextView.translatesAutoresizingMaskIntoConstraints = false
//        contentContainerView.addArrangedSubview(statusView.contentTextView)
//        statusView.contentTextView.setContentHuggingPriority(.required - 10, for: .vertical)
//        
//        // mediaGridContainerView
//        statusView.mediaGridContainerView.translatesAutoresizingMaskIntoConstraints = false
//        contentContainerView.addArrangedSubview(statusView.mediaGridContainerView)
//        
//        // pollTableView
//        contentContainerView.addArrangedSubview(statusView.pollTableView)
//        
//        statusView.pollVoteInfoContainerView.axis = .horizontal
//        statusView.pollVoteInfoContainerView.addArrangedSubview(statusView.pollVoteDescriptionLabel)
//        statusView.pollVoteInfoContainerView.addArrangedSubview(UIView())       // spacer
//        statusView.pollVoteInfoContainerView.addArrangedSubview(statusView.pollVoteButton)
//        statusView.pollVoteButton.setContentHuggingPriority(.required - 10, for: .horizontal)
//        statusView.pollVoteButton.setContentCompressionResistancePriority(.required - 9, for: .horizontal)
//        statusView.pollVoteInfoContainerView.addArrangedSubview(statusView.pollVoteActivityIndicatorView)
//        statusView.pollVoteInfoContainerView.setContentHuggingPriority(.required - 11, for: .horizontal)
//        statusView.pollVoteInfoContainerView.setContentCompressionResistancePriority(.required - 10, for: .horizontal)
//        contentContainerView.addArrangedSubview(statusView.pollVoteInfoContainerView)
//        
//        // quoteStatusView
//        let quoteStatusView = StatusView()
//        quoteStatusView.setup(style: .quote)
//        statusView.quoteStatusView = quoteStatusView
//        contentContainerView.addArrangedSubview(quoteStatusView)
//        
//        // location content: H - [ locationMapPinImageView | locationLabel ]
//        contentContainerView.addArrangedSubview(statusView.locationContainer)
//
//        statusView.locationMapPinImageView.translatesAutoresizingMaskIntoConstraints = false
//        statusView.locationLabel.translatesAutoresizingMaskIntoConstraints = false
//        
//        // locationMapPinImageView
//        statusView.locationContainer.addArrangedSubview(statusView.locationMapPinImageView)
//        // locationLabel
//        statusView.locationContainer.addArrangedSubview(statusView.locationLabel)
//        
//        NSLayoutConstraint.activate([
//            statusView.locationMapPinImageView.heightAnchor.constraint(equalTo: statusView.locationLabel.heightAnchor, multiplier: 1.0).priority(.required - 1),
//            statusView.locationMapPinImageView.widthAnchor.constraint(equalTo: statusView.locationMapPinImageView.heightAnchor, multiplier: 1.0).priority(.required - 1),
//        ])
//        statusView.locationLabel.setContentHuggingPriority(.required - 10, for: .vertical)
//        statusView.locationMapPinImageView.setContentHuggingPriority(.defaultLow, for: .vertical)
//        statusView.locationMapPinImageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
//        
//        // toolbar
//        contentContainerView.addArrangedSubview(statusView.toolbar)
//        statusView.toolbar.setContentHuggingPriority(.required - 9, for: .vertical)
//    }
//    
//    private func layoutPlain(statusView: StatusView) {
//        // container: V - [ header container | author container | contentTextView | mediaGridContainerView | quoteStatusView | location content | toolbar ]
//
//        // header container: H - [ icon | label ]
//        statusView.containerStackView.addArrangedSubview(statusView.headerContainerView)
//        statusView.headerIconImageView.translatesAutoresizingMaskIntoConstraints = false
//        statusView.headerTextLabel.translatesAutoresizingMaskIntoConstraints = false
//        statusView.headerContainerView.addSubview(statusView.headerIconImageView)
//        statusView.headerContainerView.addSubview(statusView.headerTextLabel)
//        NSLayoutConstraint.activate([
//            statusView.headerTextLabel.topAnchor.constraint(equalTo: statusView.headerContainerView.topAnchor),
//            statusView.headerTextLabel.bottomAnchor.constraint(equalTo: statusView.headerContainerView.bottomAnchor),
//            statusView.headerTextLabel.trailingAnchor.constraint(equalTo: statusView.headerContainerView.trailingAnchor),
//            statusView.headerIconImageView.centerYAnchor.constraint(equalTo: statusView.headerTextLabel.centerYAnchor),
//            statusView.headerIconImageView.heightAnchor.constraint(equalTo: statusView.headerTextLabel.heightAnchor, multiplier: 1.0).priority(.required - 1),
//            statusView.headerIconImageView.widthAnchor.constraint(equalTo: statusView.headerIconImageView.heightAnchor, multiplier: 1.0).priority(.required - 1),
//            statusView.headerTextLabel.leadingAnchor.constraint(equalTo: statusView.headerIconImageView.trailingAnchor, constant: 4),
//            // align to author name below
//        ])
//        statusView.headerTextLabel.setContentHuggingPriority(.required - 10, for: .vertical)
//        statusView.headerIconImageView.setContentHuggingPriority(.defaultLow, for: .vertical)
//        statusView.headerIconImageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
//        statusView.headerContainerView.isHidden = true
//
//        // author content: H - [ authorAvatarButton | author info content ]
//        let authorContentStackView = UIStackView()
//        let authorContentStackViewSpacing: CGFloat = 10
//        authorContentStackView.axis = .horizontal
//        authorContentStackView.spacing = authorContentStackViewSpacing
//        statusView.containerStackView.addArrangedSubview(authorContentStackView)
//
//        // authorAvatarButton
//        let authorAvatarButtonSize = CGSize(width: 44, height: 44)
//        statusView.authorAvatarButton.size = authorAvatarButtonSize
//        statusView.authorAvatarButton.avatarImageView.imageViewSize = authorAvatarButtonSize
//        statusView.authorAvatarButton.translatesAutoresizingMaskIntoConstraints = false
//        authorContentStackView.addArrangedSubview(statusView.authorAvatarButton)
//        let authorAvatarButtonWidthFixLayoutConstraint = statusView.authorAvatarButton.widthAnchor.constraint(equalToConstant: authorAvatarButtonSize.width).priority(.required - 1)
//        NSLayoutConstraint.activate([
//            authorAvatarButtonWidthFixLayoutConstraint,
//            statusView.authorAvatarButton.heightAnchor.constraint(equalTo: statusView.authorAvatarButton.widthAnchor, multiplier: 1.0).priority(.required - 1),
//        ])
//        
//        // author info content: V - [ author info headline content | author info sub-headline content ]
//        let authorInfoContentStackView = UIStackView()
//        authorInfoContentStackView.axis = .vertical
//        authorContentStackView.addArrangedSubview(authorInfoContentStackView)
//        
//        // author info headline content: H - [ authorNameLabel | lockImageView | padding | visibilityImageView (for Mastodon) ]
//        let authorInfoHeadlineContentStackView = UIStackView()
//        authorInfoHeadlineContentStackView.axis = .horizontal
//        authorInfoHeadlineContentStackView.spacing = 2
//        authorInfoContentStackView.addArrangedSubview(authorInfoHeadlineContentStackView)
//        
//        // authorNameLabel
//        authorInfoHeadlineContentStackView.addArrangedSubview(statusView.authorNameLabel)
//        statusView.authorNameLabel.setContentCompressionResistancePriority(.required - 10, for: .horizontal)
//        // lockImageView
//        statusView.lockImageView.translatesAutoresizingMaskIntoConstraints = false
//        authorInfoHeadlineContentStackView.addArrangedSubview(statusView.lockImageView)
//        NSLayoutConstraint.activate([
//            statusView.lockImageView.heightAnchor.constraint(equalTo: statusView.authorNameLabel.heightAnchor).priority(.required - 10),
//        ])
//        statusView.lockImageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
//        statusView.lockImageView.setContentCompressionResistancePriority(.required - 10, for: .horizontal)
//        // padding
//        authorInfoHeadlineContentStackView.addArrangedSubview(UIView())
//        // visibilityImageView
//        authorInfoHeadlineContentStackView.addArrangedSubview(statusView.visibilityImageView)
//        statusView.visibilityImageView.setContentHuggingPriority(.required - 9, for: .horizontal)
//        statusView.visibilityImageView.setContentCompressionResistancePriority(.required - 9, for: .horizontal)
//        
//        // set header label align to author name
//        NSLayoutConstraint.activate([
//            statusView.headerTextLabel.leadingAnchor.constraint(equalTo: statusView.authorAvatarButton.trailingAnchor, constant: authorContentStackViewSpacing),
//        ])
//        
//        // author info sub-headline content: H - [ authorUsernameLabel ]
//        let authorInfoSubHeadlineContentStackView = UIStackView()
//        authorInfoSubHeadlineContentStackView.axis = .horizontal
//        authorInfoContentStackView.addArrangedSubview(authorInfoSubHeadlineContentStackView)
//        
//        UIContentSizeCategory.publisher
//            .sink { category in
//                if category >= .extraExtraLarge {
//                    authorContentStackView.axis = .vertical
//                    authorContentStackView.alignment = .leading // set leading
//                } else {
//                    authorContentStackView.axis = .horizontal
//                    authorContentStackView.alignment = .fill    // restore default
//                }
//            }
//            .store(in: &statusView._disposeBag)
//        
//        // authorUsernameLabel
//        authorInfoSubHeadlineContentStackView.addArrangedSubview(statusView.authorUsernameLabel)
//        
//        // spoilerContentTextView
//        statusView.containerStackView.addArrangedSubview(statusView.spoilerContentTextView)
//        statusView.spoilerContentTextView.setContentCompressionResistancePriority(.required - 10, for: .vertical)
//        statusView.spoilerContentTextView.setContentHuggingPriority(.required - 9, for: .vertical)
//        
//        statusView.containerStackView.addArrangedSubview(statusView.expandContentButtonContainer)
//        statusView.expandContentButton.translatesAutoresizingMaskIntoConstraints = false
//        statusView.expandContentButtonContainer.addArrangedSubview(statusView.expandContentButton)
//        statusView.expandContentButtonContainer.addArrangedSubview(UIView())
//
//        // contentTextView
//        statusView.containerStackView.addArrangedSubview(statusView.contentTextView)
//        
//        // translateButtonContainer: H - [ translateButton | (spacer) ]
//        statusView.translateButtonContainer.axis = .horizontal
//        statusView.containerStackView.addArrangedSubview(statusView.translateButtonContainer)
//        
//        statusView.translateButtonContainer.addArrangedSubview(statusView.translateButton)
//        statusView.translateButtonContainer.addArrangedSubview(UIView())
//        statusView.translateButton.setContentHuggingPriority(.required - 1, for: .vertical)
//        statusView.translateButton.setContentCompressionResistancePriority(.required - 1, for: .vertical)
//        
//        // mediaGridContainerView
//        statusView.containerStackView.addArrangedSubview(statusView.mediaGridContainerView)
//        
//        // pollTableView
//        statusView.containerStackView.addArrangedSubview(statusView.pollTableView)
//        
//        statusView.pollVoteInfoContainerView.axis = .horizontal
//        statusView.pollVoteInfoContainerView.addArrangedSubview(statusView.pollVoteDescriptionLabel)
//        statusView.pollVoteInfoContainerView.addArrangedSubview(UIView())       // spacer
//        statusView.pollVoteInfoContainerView.addArrangedSubview(statusView.pollVoteButton)
//        statusView.pollVoteButton.setContentHuggingPriority(.required - 10, for: .horizontal)
//        statusView.pollVoteButton.setContentCompressionResistancePriority(.required - 9, for: .horizontal)
//        statusView.pollVoteInfoContainerView.addArrangedSubview(statusView.pollVoteActivityIndicatorView)
//        statusView.pollVoteInfoContainerView.setContentHuggingPriority(.required - 11, for: .horizontal)
//        statusView.pollVoteInfoContainerView.setContentCompressionResistancePriority(.required - 10, for: .horizontal)
//        statusView.containerStackView.addArrangedSubview(statusView.pollVoteInfoContainerView)
//
//        // quoteStatusView
//        let quoteStatusView = StatusView()
//        quoteStatusView.setup(style: .quote)
//        statusView.quoteStatusView = quoteStatusView
//        statusView.containerStackView.addArrangedSubview(quoteStatusView)
//        
//        // location content: H - [ padding | locationMapPinImageView | locationLabel | padding ]
//        statusView.containerStackView.addArrangedSubview(statusView.locationContainer)
//        
//        statusView.locationMapPinImageView.translatesAutoresizingMaskIntoConstraints = false
//        statusView.locationLabel.translatesAutoresizingMaskIntoConstraints = false
//        
//        // locationLeadingPadding
//        let locationLeadingPadding = UIView()
//        locationLeadingPadding.translatesAutoresizingMaskIntoConstraints = false
//        statusView.locationContainer.addArrangedSubview(locationLeadingPadding)
//        // locationMapPinImageView
//        statusView.locationContainer.addArrangedSubview(statusView.locationMapPinImageView)
//        // locationLabel
//        statusView.locationContainer.addArrangedSubview(statusView.locationLabel)
//        // locationTrailingPadding
//        let locationTrailingPadding = UIView()
//        locationTrailingPadding.translatesAutoresizingMaskIntoConstraints = false
//        statusView.locationContainer.addArrangedSubview(locationTrailingPadding)
//        
//        // center alignment
//        NSLayoutConstraint.activate([
//            locationLeadingPadding.widthAnchor.constraint(equalTo: locationTrailingPadding.widthAnchor).priority(.defaultHigh),
//        ])
//        
//        NSLayoutConstraint.activate([
//            statusView.locationMapPinImageView.heightAnchor.constraint(equalTo: statusView.locationLabel.heightAnchor, multiplier: 1.0).priority(.required - 1),
//            statusView.locationMapPinImageView.widthAnchor.constraint(equalTo: statusView.locationMapPinImageView.heightAnchor, multiplier: 1.0).priority(.required - 1),
//        ])
//        statusView.locationLabel.setContentHuggingPriority(.required - 10, for: .vertical)
//        statusView.locationMapPinImageView.setContentHuggingPriority(.defaultLow, for: .vertical)
//        statusView.locationMapPinImageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
//        
//        // metrics
//        statusView.containerStackView.addArrangedSubview(statusView.metricsDashboardView)
//        
//        UIContentSizeCategory.publisher
//            .sink { category in
//                if category >= .extraExtraLarge {
//                    statusView.metricsDashboardView.metaContainer.axis = .vertical
//                } else {
//                    statusView.metricsDashboardView.metaContainer.axis = .horizontal
//                }
//            }
//            .store(in: &statusView._disposeBag)
//        
//        // toolbar
//        statusView.containerStackView.addArrangedSubview(statusView.toolbar)
//        statusView.toolbar.setContentHuggingPriority(.required - 9, for: .vertical)
//        
//        // reply settings
//        statusView.containerStackView.addArrangedSubview(statusView.replySettingBannerView)
//    }
//    
//    private func layoutQuote(statusView: StatusView) {
//        // container: V - [ body container ]
//        // set `isLayoutMarginsRelativeArrangement` not works with AutoLayout (priority issue)
//        // add constraint to workaround
//        statusView.containerStackView.backgroundColor = .secondarySystemBackground
//        statusView.containerStackView.layer.masksToBounds = true
//        statusView.containerStackView.layer.cornerCurve = .continuous
//        statusView.containerStackView.layer.cornerRadius = 12
//        
//        // body container: V - [ author content | content container | contentTextView | mediaGridContainerView ]
//        let bodyContainerStackView = UIStackView()
//        bodyContainerStackView.axis = .vertical
//        bodyContainerStackView.spacing = StatusView.bodyContainerStackViewSpacing
//        bodyContainerStackView.translatesAutoresizingMaskIntoConstraints = false
//        statusView.containerStackView.addSubview(bodyContainerStackView)
//        NSLayoutConstraint.activate([
//            bodyContainerStackView.topAnchor.constraint(equalTo: statusView.containerStackView.topAnchor, constant: StatusView.quoteStatusViewContainerLayoutMargin).priority(.required - 1),
//            bodyContainerStackView.leadingAnchor.constraint(equalTo: statusView.containerStackView.leadingAnchor, constant: StatusView.quoteStatusViewContainerLayoutMargin).priority(.required - 1),
//            statusView.containerStackView.trailingAnchor.constraint(equalTo: bodyContainerStackView.trailingAnchor, constant: StatusView.quoteStatusViewContainerLayoutMargin).priority(.required - 1),
//            statusView.containerStackView.bottomAnchor.constraint(equalTo: bodyContainerStackView.bottomAnchor, constant: StatusView.quoteStatusViewContainerLayoutMargin).priority(.required - 1),
//        ])
//        
//        // author content: H - [ authorAvatarButton | authorNameLabel | lockImageView | authorUsernameLabel | padding ]
//        let authorContentStackView = UIStackView()
//        authorContentStackView.axis = .horizontal
//        bodyContainerStackView.alignment = .top
//        authorContentStackView.spacing = 6
//        bodyContainerStackView.addArrangedSubview(authorContentStackView)
//        bodyContainerStackView.setCustomSpacing(4, after: authorContentStackView)
//        
//        // authorAvatarButton
//        statusView.authorAvatarButton.translatesAutoresizingMaskIntoConstraints = false
//        authorContentStackView.addArrangedSubview(statusView.authorAvatarButton)
//        // authorNameLabel
//        authorContentStackView.addArrangedSubview(statusView.authorNameLabel)
//        statusView.authorNameLabel.setContentCompressionResistancePriority(.required - 10, for: .horizontal)
//        // lockImageView
//        statusView.lockImageView.translatesAutoresizingMaskIntoConstraints = false
//        authorContentStackView.addArrangedSubview(statusView.lockImageView)
//        // authorUsernameLabel
//        authorContentStackView.addArrangedSubview(statusView.authorUsernameLabel)
//        NSLayoutConstraint.activate([
//            statusView.lockImageView.heightAnchor.constraint(equalTo: statusView.authorUsernameLabel.heightAnchor).priority(.required - 10),
//        ])
//        statusView.lockImageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
//        statusView.lockImageView.setContentCompressionResistancePriority(.required - 10, for: .horizontal)
//        statusView.authorUsernameLabel.setContentCompressionResistancePriority(.required - 11, for: .horizontal)
//        // padding
//        authorContentStackView.addArrangedSubview(UIView())
//        
//        NSLayoutConstraint.activate([
//            statusView.authorAvatarButton.heightAnchor.constraint(equalTo: statusView.authorNameLabel.heightAnchor, multiplier: 1.0).priority(.required - 10),
//            statusView.authorAvatarButton.widthAnchor.constraint(equalTo: statusView.authorNameLabel.heightAnchor, multiplier: 1.0).priority(.required - 10),
//        ])
//        // low priority for intrinsic size hugging
//        statusView.authorAvatarButton.setContentHuggingPriority(.defaultLow - 10, for: .vertical)
//        statusView.authorAvatarButton.setContentHuggingPriority(.defaultLow - 10, for: .horizontal)
//        // high priority but lower then layout constraint for size compression
//        statusView.authorAvatarButton.setContentCompressionResistancePriority(.required - 11, for: .vertical)
//        statusView.authorAvatarButton.setContentCompressionResistancePriority(.required - 11, for: .horizontal)
//        statusView.authorNameLabel.setContentCompressionResistancePriority(.required - 1, for: .vertical)
//        statusView.authorNameLabel.setContentHuggingPriority(.required - 1, for: .vertical)
//
//        // contentTextView
//        statusView.contentTextView.translatesAutoresizingMaskIntoConstraints = false
//        bodyContainerStackView.addArrangedSubview(statusView.contentTextView)
//        statusView.contentTextView.setContentHuggingPriority(.required - 10, for: .vertical)
//        statusView.contentTextView.textAttributes = [
//            .font: UIFont.preferredFont(forTextStyle: .callout),
//            .foregroundColor: UIColor.secondaryLabel,
//        ]
//        statusView.contentTextView.linkAttributes = [
//            .font: UIFont.preferredFont(forTextStyle: .callout),
//            .foregroundColor: Asset.Colors.Theme.daylight.color
//        ]
//        
//        // mediaGridContainerView
//        statusView.mediaGridContainerView.translatesAutoresizingMaskIntoConstraints = false
//        bodyContainerStackView.addArrangedSubview(statusView.mediaGridContainerView)
//    }
//    
//    func layoutComposeReply(statusView: StatusView) {
//        // container: V - [ body container ]
//        
//        // body container: H - [ authorAvatarButton | content container ]
//        let bodyContainerStackView = UIStackView()
//        bodyContainerStackView.axis = .horizontal
//        bodyContainerStackView.spacing = StatusView.bodyContainerStackViewSpacing
//        bodyContainerStackView.alignment = .top
//        statusView.containerStackView.addArrangedSubview(bodyContainerStackView)
//        
//        // authorAvatarButton
//        let authorAvatarButtonSize = CGSize(width: 44, height: 44)
//        statusView.authorAvatarButton.size = authorAvatarButtonSize
//        statusView.authorAvatarButton.avatarImageView.imageViewSize = authorAvatarButtonSize
//        statusView.authorAvatarButton.translatesAutoresizingMaskIntoConstraints = false
//        bodyContainerStackView.addArrangedSubview(statusView.authorAvatarButton)
//        NSLayoutConstraint.activate([
//            statusView.authorAvatarButton.widthAnchor.constraint(equalToConstant: authorAvatarButtonSize.width).priority(.required - 1),
//            statusView.authorAvatarButton.heightAnchor.constraint(equalToConstant: authorAvatarButtonSize.height).priority(.required - 1),
//        ])
//        
//        // content container: V - [ author content | contentTextView | mediaGridContainerView | quoteStatusView | … | location content | toolbar ]
//        let contentContainerView = UIStackView()
//        contentContainerView.axis = .vertical
//        contentContainerView.spacing = 10
//        bodyContainerStackView.addArrangedSubview(contentContainerView)
//        
//        // author content: H - [ authorNameLabel | lockImageView | authorUsernameLabel | padding | visibilityImageView (for Mastodon) | timestampLabel ]
//        let authorContentStackView = UIStackView()
//        authorContentStackView.axis = .horizontal
//        authorContentStackView.spacing = 6
//        contentContainerView.addArrangedSubview(authorContentStackView)
//        contentContainerView.setCustomSpacing(4, after: authorContentStackView)
//        UIContentSizeCategory.publisher
//            .sink { category in
//                authorContentStackView.axis = category > .accessibilityLarge ? .vertical : .horizontal
//            }
//            .store(in: &statusView._disposeBag)
//        
//        // authorNameLabel
//        authorContentStackView.addArrangedSubview(statusView.authorNameLabel)
//        statusView.authorNameLabel.setContentCompressionResistancePriority(.required - 10, for: .horizontal)
//        // lockImageView
//        statusView.lockImageView.translatesAutoresizingMaskIntoConstraints = false
//        authorContentStackView.addArrangedSubview(statusView.lockImageView)
//        // authorUsernameLabel
//        authorContentStackView.addArrangedSubview(statusView.authorUsernameLabel)
//        NSLayoutConstraint.activate([
//            statusView.lockImageView.heightAnchor.constraint(equalTo: statusView.authorUsernameLabel.heightAnchor).priority(.required - 10),
//        ])
//        statusView.lockImageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
//        statusView.lockImageView.setContentCompressionResistancePriority(.required - 10, for: .horizontal)
//        statusView.authorUsernameLabel.setContentCompressionResistancePriority(.required - 11, for: .horizontal)
//        // padding
//        authorContentStackView.addArrangedSubview(UIView())
//        // visibilityImageView
//        authorContentStackView.addArrangedSubview(statusView.visibilityImageView)
//        statusView.visibilityImageView.setContentHuggingPriority(.required - 9, for: .horizontal)
//        statusView.visibilityImageView.setContentCompressionResistancePriority(.required - 9, for: .horizontal)
//        // timestampLabel
//        authorContentStackView.addArrangedSubview(statusView.timestampLabel)
//        statusView.timestampLabel.setContentHuggingPriority(.required - 9, for: .horizontal)
//        statusView.timestampLabel.setContentCompressionResistancePriority(.required - 9, for: .horizontal)
//        
//        // spoilerContentTextView
//        contentContainerView.addArrangedSubview(statusView.spoilerContentTextView)
//        statusView.spoilerContentTextView.setContentCompressionResistancePriority(.required - 10, for: .vertical)
//        statusView.spoilerContentTextView.setContentHuggingPriority(.required - 9, for: .vertical)
//        
//        contentContainerView.addArrangedSubview(statusView.expandContentButtonContainer)
//        statusView.expandContentButton.translatesAutoresizingMaskIntoConstraints = false
//        statusView.expandContentButtonContainer.addArrangedSubview(statusView.expandContentButton)
//        statusView.expandContentButtonContainer.addArrangedSubview(UIView())
//        
//        // contentTextView
//        statusView.contentTextView.translatesAutoresizingMaskIntoConstraints = false
//        contentContainerView.addArrangedSubview(statusView.contentTextView)
//        statusView.contentTextView.setContentHuggingPriority(.required - 10, for: .vertical)
//        
//        // mediaGridContainerView
//        statusView.mediaGridContainerView.translatesAutoresizingMaskIntoConstraints = false
//        contentContainerView.addArrangedSubview(statusView.mediaGridContainerView)
//        
//        // quoteStatusView
//        let quoteStatusView = StatusView()
//        quoteStatusView.setup(style: .quote)
//        statusView.quoteStatusView = quoteStatusView
//        contentContainerView.addArrangedSubview(quoteStatusView)
//        
//        // location content: H - [ locationMapPinImageView | locationLabel ]
//        contentContainerView.addArrangedSubview(statusView.locationContainer)
//        
//        statusView.locationMapPinImageView.translatesAutoresizingMaskIntoConstraints = false
//        statusView.locationLabel.translatesAutoresizingMaskIntoConstraints = false
//        
//        // locationMapPinImageView
//        statusView.locationContainer.addArrangedSubview(statusView.locationMapPinImageView)
//        // locationLabel
//        statusView.locationContainer.addArrangedSubview(statusView.locationLabel)
//        
//        NSLayoutConstraint.activate([
//            statusView.locationMapPinImageView.heightAnchor.constraint(equalTo: statusView.locationLabel.heightAnchor, multiplier: 1.0).priority(.required - 1),
//            statusView.locationMapPinImageView.widthAnchor.constraint(equalTo: statusView.locationMapPinImageView.heightAnchor, multiplier: 1.0).priority(.required - 1),
//        ])
//        statusView.locationLabel.setContentHuggingPriority(.required - 10, for: .vertical)
//        statusView.locationMapPinImageView.setContentHuggingPriority(.defaultLow, for: .vertical)
//        statusView.locationMapPinImageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
//    }
//    
//}
//
//extension StatusView {
//    
//    private func update(theme: Theme) {
//        headerIconImageView.tintColor = theme.accentColor
//    }
//    
//    public func setHeaderDisplay() {
//        headerContainerView.isHidden = false
//    }
//    
//    public func setLockDisplay() {
//        lockImageView.isHidden = false
//    }
//    
//    public func setVisibilityDisplay() {
//        visibilityImageView.isHidden = false
//    }
//    
//    public func setSpoilerDisplay() {
//        spoilerContentTextView.isHidden = false
//        expandContentButtonContainer.isHidden = false
//    }
//    
//    public func setTranslateButtonDisplay() {
//        translateButtonContainer.isHidden = false
//    }
//    
//    public func setMediaDisplay() {
//        mediaGridContainerView.isHidden = false
//    }
//    
//    public func setPollDisplay() {
//        pollTableView.isHidden = false
//        pollVoteInfoContainerView.isHidden = false
//    }
//    
//    public func setQuoteDisplay() {
//        quoteStatusView?.isHidden = false
//    }
//    
//    public func setLocationDisplay() {
//        locationContainer.isHidden = false
//    }
//    
//    public func setReplySettingsDisplay() {
//        replySettingBannerView.isHidden = false
//    }
//    
//    // content text Width
//    public var contentMaxLayoutWidth: CGFloat {
//        let inset = contentLayoutInset
//        return frame.width - inset.left - inset.right
//    }
//    
//    public var contentLayoutInset: UIEdgeInsets {
//        guard let style = style else {
//            assertionFailure("Needs setup style before use")
//            return .zero
//        }
//        
//        switch style {
//        case .inline, .composeReply:
//            let left = authorAvatarButton.size.width + StatusView.bodyContainerStackViewSpacing
//            return UIEdgeInsets(top: 0, left: left, bottom: 0, right: 0)
//        case .plain:
//            return .zero
//        case .quote:
//            let margin = StatusView.quoteStatusViewContainerLayoutMargin
//            return UIEdgeInsets(top: 0, left: margin, bottom: 0, right: margin)
//        }
//    }
//
//}
//
//extension StatusView {
//    @objc private func headerTapGestureRecognizerHandler(_ sender: UITapGestureRecognizer) {
//        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
//        delegate?.statusView(self, headerDidPressed: headerContainerView)
//    }
//    
//    @objc private func authorAvatarButtonDidPressed(_ sender: UIButton) {
//        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
//        delegate?.statusView(self, authorAvatarButtonDidPressed: authorAvatarButton)
//    }
//    
//    @objc private func expandContentButtonDidPressed(_ sender: UIButton) {
//        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
//        delegate?.statusView(self, expandContentButtonDidPressed: sender)
//    }
//    
//    @objc private func pollVoteButtonDidPressed(_ sender: UIButton) {
//        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
//        delegate?.statusView(self, pollVoteButtonDidPressed: sender)
//    }
//    
//    @objc private func quoteStatusViewDidPressed(_ sender: UITapGestureRecognizer) {
//        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
//        guard let quoteStatusView = quoteStatusView else { return }
//        delegate?.statusView(self, quoteStatusViewDidPressed: quoteStatusView)
//    }
//    
//    @objc private func quoteAuthorAvatarButtonDidPressed(_ sender: UITapGestureRecognizer) {
//        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
//        guard let quoteStatusView = quoteStatusView else { return }
//        delegate?.statusView(self, quoteStatusView: quoteStatusView, authorAvatarButtonDidPressed: quoteStatusView.authorAvatarButton)
//    }
//    
//    @objc private func translateButtonDidPressed(_ sender: UIButton) {
//        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
//        delegate?.statusView(self, translateButtonDidPressed: sender)
//    }
//}
//
//// MARK: - MetaTextAreaViewDelegate
//extension StatusView: MetaTextAreaViewDelegate {
//    public func metaTextAreaView(_ metaTextAreaView: MetaTextAreaView, didSelectMeta meta: Meta) {
//        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public))")
//        delegate?.statusView(self, metaTextAreaView: metaTextAreaView, didSelectMeta: meta)
//    }
//}
//
//// MARK: - MediaGridContainerViewDelegate
//extension StatusView: MediaGridContainerViewDelegate {
//    public func mediaGridContainerView(_ container: MediaGridContainerView, didTapMediaView mediaView: MediaView, at index: Int) {
//        delegate?.statusView(self, mediaGridContainerView: container, didTapMediaView: mediaView, at: index)
//    }
//    
//    public func mediaGridContainerView(_ container: MediaGridContainerView, toggleContentWarningOverlayViewDisplay contentWarningOverlayView: ContentWarningOverlayView) {
//        delegate?.statusView(self, mediaGridContainerView: container, toggleContentWarningOverlayViewDisplay: contentWarningOverlayView)
//    }
//}
//
//// MARK: - StatusToolbarDelegate
//extension StatusView: StatusToolbarDelegate {
//    public func statusToolbar(_ statusToolbar: StatusToolbar, actionDidPressed action: StatusToolbar.Action, button: UIButton) {
//        delegate?.statusView(self, statusToolbar: statusToolbar, actionDidPressed: action, button: button)
//    }
//    
//    public func statusToolbar(_ statusToolbar: StatusToolbar, menuActionDidPressed action: StatusToolbar.MenuAction, menuButton button: UIButton) {
//        delegate?.statusView(self, statusToolbar: statusToolbar, menuActionDidPressed: action, menuButton: button)
//    }
//}
//
//// MARK: - StatusViewDelegate
//// relay for quoteStatsView
//extension StatusView: StatusViewDelegate {
//    
//    public func statusView(_ statusView: StatusView, headerDidPressed header: UIView) {
//        assertionFailure()
//    }
//    
//    public func statusView(_ statusView: StatusView, authorAvatarButtonDidPressed button: AvatarButton) {
//        guard statusView === quoteStatusView else {
//            assertionFailure()
//            return
//        }
//        
//        delegate?.statusView(self, quoteStatusView: statusView, authorAvatarButtonDidPressed: button)
//    }
//    
//    public func statusView(_ statusView: StatusView, quoteStatusView: StatusView, authorAvatarButtonDidPressed button: AvatarButton) {
//        assertionFailure()
//    }
//    
//    public func statusView(_ statusView: StatusView, metaTextAreaView: MetaTextAreaView, didSelectMeta meta: Meta) {
//        guard statusView === quoteStatusView else {
//            assertionFailure()
//            return
//        }
//        
//        delegate?.statusView(self, quoteStatusView: statusView, metaTextAreaView: metaTextAreaView, didSelectMeta: meta)
//    }
//    
//    public func statusView(_ statusView: StatusView, expandContentButtonDidPressed button: UIButton) {
//        assertionFailure()
//    }
//    
//    public func statusView(_ statusView: StatusView, quoteStatusView: StatusView, metaTextAreaView: MetaTextAreaView, didSelectMeta meta: Meta) {
//        assertionFailure()
//    }
//    
//    public func statusView(_ statusView: StatusView, mediaGridContainerView containerView: MediaGridContainerView, didTapMediaView mediaView: MediaView, at index: Int) {
//        guard statusView === quoteStatusView else {
//            assertionFailure()
//            return
//        }
//        
//        delegate?.statusView(self, quoteStatusView: statusView, mediaGridContainerView: containerView, didTapMediaView: mediaView, at: index)
//    }
//    
//    public func statusView(_ statusView: StatusView, pollTableView tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        assertionFailure()
//    }
//    
//    public func statusView(_ statusView: StatusView, pollVoteButtonDidPressed button: UIButton) {
//        assertionFailure()
//    }
//    
//    public func statusView(_ statusView: StatusView, quoteStatusView: StatusView, mediaGridContainerView containerView: MediaGridContainerView, didTapMediaView mediaView: MediaView, at index: Int) {
//        assertionFailure()
//    }
//    
//    public func statusView(_ statusView: StatusView, mediaGridContainerView containerView: MediaGridContainerView, toggleContentWarningOverlayViewDisplay contentWarningOverlayView: ContentWarningOverlayView) {
//        assertionFailure()
//    }
//    
//    public func statusView(_ statusView: StatusView, quoteStatusViewDidPressed quoteStatusView: StatusView) {
//        assertionFailure()
//    }
//    
//    public func statusView(_ statusView: StatusView, statusToolbar: StatusToolbar, actionDidPressed action: StatusToolbar.Action, button: UIButton) {
//        assertionFailure()
//    }
//    
//    public func statusView(_ statusView: StatusView, statusToolbar: StatusToolbar, menuActionDidPressed action: StatusToolbar.MenuAction, menuButton button: UIButton) {
//        assertionFailure()
//    }
//    
//    public func statusView(_ statusView: StatusView, translateButtonDidPressed button: UIButton) {
//        assertionFailure()
//    }
//    
//    public func statusView(_ statusView: StatusView, accessibilityActivate: Void) {
//        assertionFailure()
//    }
//    
//}
//
//// MARK: - UITableViewDelegate
//extension StatusView: UITableViewDelegate {
//    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): select \(indexPath.debugDescription)")
//        
//        switch tableView {
//        case pollTableView:
//            delegate?.statusView(self, pollTableView: tableView, didSelectRowAt: indexPath)
//        default:
//            assertionFailure()
//        }
//    }
//}
//
//// MARK: - UIGestureRecognizerDelegate
//extension StatusView: UIGestureRecognizerDelegate {
//    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
//        if let view = touch.view, view is AvatarButton {
//            return false
//        }
//        
//        return true
//    }
//}
