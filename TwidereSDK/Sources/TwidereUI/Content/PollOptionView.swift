//
//  PollOptionView.swift
//  
//
//  Created by MainasuK on 2021-11-29.
//

import os.log
import Foundation
import SwiftUI
import Combine
import MastodonMeta
import CoreDataStack

public struct PollOptionView: View {
    
    @ObservedObject public var viewModel: ViewModel
    public let selectAction: (ViewModel) -> Void
    
    var bodyFont: UIFont { TextStyle.pollOptionTitle.font }
    var rowHeight: CGFloat {
        let height = abs(bodyFont.ascender) + abs(bodyFont.descender)
        return max(markViewMinHeight + 2 * markViewPadding, height)
    }
    var markViewMinHeight: CGFloat { 20.0 }
    var markViewPadding: CGFloat { 4.0 }
    
    var markView: some View {
        GeometryReader { proxy in
            let tintColor = viewModel.canSelect ? Asset.Colors.hightLight.color : .systemBackground
            let dimension = proxy.size.width
            CheckmarkView(
                tintColor: tintColor,
                borderWidth: ceil(dimension / 15),
                cornerRadius: viewModel.isMulitpleChoice ? dimension / 6 : dimension / 2,
                check: viewModel.isOptionVoted || viewModel.isSelected
            )
        }
    }
    
    public var body: some View {
        Button {
            selectAction(viewModel)
        } label: {
            let rowHeight = self.rowHeight
            let rowCornerRadius: CGFloat = {
                if viewModel.isMulitpleChoice {
                    return rowHeight / 6
                } else {
                    return rowHeight / 2
                }
            }()
            HStack(spacing: .zero) {
                markView
                    .padding(markViewPadding)
                    .frame(width: rowHeight, height: rowHeight)
                    .opacity(viewModel.canSelect || viewModel.isOptionVoted ? 1 : 0)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .center) {
                        LabelRepresentable(
                            metaContent: viewModel.content,
                            textStyle: .pollOptionTitle,
                            setupLabel: { label in
                                label.setContentHuggingPriority(.required, for: .horizontal)
                                label.setContentCompressionResistancePriority(.required, for: .horizontal)
                            }
                        )
                        .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                    }
                }   // end ScrollView
                // TODO: https://developer.apple.com/documentation/swiftui/view/scrollbouncebehavior(_:axes:)?changes=latest_minor
                Text(viewModel.percentageText)
                    .font(Font(bodyFont))
                    .foregroundColor(.secondary)
                    .monospacedDigit()
                    .padding(.horizontal, 6)
                    .opacity(viewModel.isResultReveal ? 1 : 0)
            }
            .frame(height: rowHeight)
            .background(
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Color(uiColor: Asset.Colors.hightLight.color.withAlphaComponent(0.15))
                        // note:
                        // Use offset method to keep the perfect circle shape on edges.
                        // So the edge of the bar with percenage likes 0.1 will display as circle
                        // but not rounded square
                        let alpha = viewModel.isOptionVoted ? 0.75 : 0.25
                        let color = Asset.Colors.hightLight.color.withAlphaComponent(alpha)
                        let offsetX = proxy.size.width * (1 - viewModel.percentage)
                        Color(uiColor: color)
                            .cornerRadius(rowCornerRadius)
                            .offset(x: -offsetX)    // tweak position
                            .animation(.easeInOut, value: viewModel.percentage)
                            .opacity(viewModel.isResultReveal ? 1 : 0)
                    }
                    .compositingGroup()
                    .cornerRadius(rowCornerRadius)  // clip
                }
            )
        }
        .buttonStyle(.borderless)
    }
}

extension PollOptionView {
    public class ViewModel: ObservableObject, Identifiable {
        
        public var id: Int { index }
        
        // input
        private let authContext: AuthContext?
        @MainActor private let pollOption: PollOptionObject
        
        public let index: Int
        public let content: MetaContent
        public let isMulitpleChoice: Bool
        public let isMyself: Bool
        
        @Published public var isClosed = false
        @Published public var totalVotes: Int = 0
        @Published public var votes: Int = 0
        @Published public var isOptionVoted = false
        @Published public var isPollVoted = false
        @Published public var isSelected: Bool = false
        
        public var canSelect: Bool {
            if isMyself { return false }
            if isClosed { return false }
            if case .twitter = pollOption { return false }
            if isPollVoted || isOptionVoted { return false }
            return true
        }
        public var isResultReveal: Bool {
            return !canSelect
        }
        
        // output
        private static let percentageFormatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 2
            formatter.numberStyle = .percent
            return formatter
        }()
        public var percentage: Double {
            guard totalVotes > 0 else { return 0.0 }
            return Double(votes) / Double(totalVotes)
        }
        public var percentageText: String {
            let _text = Self.percentageFormatter.string(from: NSNumber(value: percentage)) ?? nil
            return _text ?? ""
        }
        
        public init(
            authContext: AuthContext?,
            pollOption: PollOptionObject,
            isMyself: Bool
        ) {
            self.authContext = authContext
            self.pollOption = pollOption
            self.isMyself = isMyself
            
            assert(Thread.isMainThread)
            switch pollOption {
            case .twitter(let option):
                index = Int(option.position)
                content = PlaintextMetaContent(string: option.label)
                isClosed = true     // cannot vote for Twitter
                isMulitpleChoice = false
                isSelected = false
                votes = Int(option.votes)
                option.publisher(for: \.votes)
                    .map { Int($0) }
                    .assign(to: &$votes)
            case .mastodon(let option):
                index = Int(option.index)
                content = {
                    do {
                        let content = MastodonContent(content: option.title, emojis: option.poll.status.emojisTransient.asDictionary)
                        let metaContent = try MastodonMetaContent.convert(document: content)
                        return metaContent
                    } catch {
                        return PlaintextMetaContent(string: option.title)
                    }
                }()
                isMulitpleChoice = option.poll.multiple
                option.poll.publisher(for: \.expired)
                    .assign(to: &$isClosed)
                votes = Int(option.votesCount)
                option.publisher(for: \.votesCount)
                    .map { Int($0) }
                    .assign(to: &$votes)
                option.publisher(for: \.isSelected)
                    .assign(to: &$isSelected)
            }
            
            switch (authContext?.authenticationContext, pollOption) {
            case (.twitter, .twitter):
                break
            case (.mastodon(let authenticationContext), .mastodon(let option)):
                // bind isVoted
                option.publisher(for: \.voteBy)
                    .map { voteBy in
                        voteBy.contains(where: { $0.id == authenticationContext.userID && $0.domain == authenticationContext.domain })
                    }
                    .assign(to: &$isOptionVoted)
                option.poll.publisher(for: \.voteBy)
                    .map { voteBy in
                        voteBy.contains(where: { $0.id == authenticationContext.userID && $0.domain == authenticationContext.domain })
                    }
                    .assign(to: &$isPollVoted)
            default:
                break
            }
        }   // end init
    }   // end class
}


//public protocol PollOptionViewDelegate: AnyObject {
//    func pollOptionView(_ pollOptionView: PollOptionView, deleteBackwardResponseTextField textField: DeleteBackwardResponseTextField, textBeforeDelete: String?)
//}
//
//public final class PollOptionView: UIView {
//
//    static let height: CGFloat = 36
//
//    public weak var delegate: PollOptionViewDelegate?
//    private(set) var style: Style?
//
//    var disposeBag = Set<AnyCancellable>()
//    public private(set) lazy var viewModel: ViewModel = {
//        let viewModel = ViewModel()
//        viewModel.bind(view: self)
//        return viewModel
//    }()
//
//    let containerView = UIView()
//
//    let stripProgressView = StripProgressView()
//
//    let selectionImageView: UIImageView = {
//        let imageView = UIImageView()
//        return imageView
//    }()
//
//    public let titleMetaLabel = MetaLabel(style: .pollOptionTitle)
//
//    public let percentageMetaLabel = MetaLabel(style: .pollOptionPercentage)
//
//    // TODO: MetaTextField?
//    public let textField: DeleteBackwardResponseTextField = {
//        let textField = DeleteBackwardResponseTextField()
//        textField.font = .systemFont(ofSize: 16, weight: .regular)
//        textField.textColor = .label
//        textField.text = "Choice"
//        textField.textAlignment = UIApplication.shared.userInterfaceLayoutDirection == .leftToRight ? .left : .right
//        return textField
//    }()
//
//    public func prepareForReuse() {
//        viewModel.objects.removeAll()
//        viewModel.percentage = nil
//        stripProgressView.setProgress(0, animated: false)
//    }
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
//}
//
//extension PollOptionView {
//
//    private func _init() {
//        textField.deleteBackwardDelegate = self
//
//        // Accessibility
//        // hint: Poll option
//        accessibilityHint = L10n.Accessibility.Common.Status.pollOptionOrdinalPrefix
//    }
//
//    public override func layoutSubviews() {
//        super.layoutSubviews()
//
//        setupCorner()
//    }
//
//    func setupCorner() {
//        switch viewModel.corner {
//        case .none:
//            containerView.layer.masksToBounds = false
//            stripProgressView.cornerRadius = 0
//        case .radius(let radius):
//            containerView.layer.masksToBounds = true
//            guard radius < bounds.height / 2 else {
//                fallthrough
//            }
//            containerView.layer.cornerCurve = .continuous
//            containerView.layer.cornerRadius = radius
//            stripProgressView.cornerRadius = radius
//        case .circle:
//            let radius = bounds.height / 2
//            containerView.layer.masksToBounds = true
//            containerView.layer.cornerCurve = .circular
//            containerView.layer.cornerRadius = radius
//            stripProgressView.cornerRadius = radius
//        }
//    }
//
//    public func setup(style: Style) {
//        guard self.style == nil else {
//            assertionFailure("Should only setup once")
//            return
//        }
//        self.style = style
//        self.viewModel.style = style
//        style.layout(view: self)
//    }
//
//    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
//        super.traitCollectionDidChange(previousTraitCollection)
//
//        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
//            textField.layer.borderColor = UIColor.secondaryLabel.cgColor
//        }
//    }
//
//}
//
//extension PollOptionView {
//    public enum Style {
//        case plain
//        case edit
//
//        func layout(view: PollOptionView) {
//            switch self {
//            case .plain:        layoutPlain(view: view)
//            case .edit:         layoutEdit(view: view)
//            }
//        }
//    }
//}
//
//extension PollOptionView.Style {
//    private func layoutPlain(view: PollOptionView) {
//        view.containerView.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(view.containerView)
//        NSLayoutConstraint.activate([
//            view.containerView.topAnchor.constraint(equalTo: view.topAnchor),
//            view.containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            view.containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            view.containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//        ])
//        view.containerView.backgroundColor = Asset.Colors.hightLight.color.withAlphaComponent(0.08)
//
//        view.stripProgressView.translatesAutoresizingMaskIntoConstraints = false
//        view.containerView.addSubview(view.stripProgressView)
//        NSLayoutConstraint.activate([
//            view.stripProgressView.topAnchor.constraint(equalTo: view.containerView.topAnchor),
//            view.stripProgressView.leadingAnchor.constraint(equalTo: view.containerView.leadingAnchor),
//            view.stripProgressView.trailingAnchor.constraint(equalTo: view.containerView.trailingAnchor),
//            view.stripProgressView.bottomAnchor.constraint(equalTo: view.containerView.bottomAnchor),
//        ])
//
//        view.selectionImageView.translatesAutoresizingMaskIntoConstraints = false
//        view.containerView.addSubview(view.selectionImageView)
//        NSLayoutConstraint.activate([
//            view.selectionImageView.topAnchor.constraint(equalTo: view.containerView.topAnchor, constant: 6),
//            view.selectionImageView.leadingAnchor.constraint(equalTo: view.containerView.leadingAnchor, constant: 6),
//            view.containerView.bottomAnchor.constraint(equalTo: view.selectionImageView.bottomAnchor, constant: 6),
//            view.selectionImageView.widthAnchor.constraint(equalToConstant: 24).priority(.required - 1),
//            view.selectionImageView.heightAnchor.constraint(equalToConstant: 24).priority(.required - 1),
//        ])
//
//        view.titleMetaLabel.translatesAutoresizingMaskIntoConstraints = false
//        view.containerView.addSubview(view.titleMetaLabel)
//        NSLayoutConstraint.activate([
//            view.titleMetaLabel.leadingAnchor.constraint(equalTo: view.selectionImageView.trailingAnchor, constant: 4),
//            view.titleMetaLabel.centerYAnchor.constraint(equalTo: view.containerView.centerYAnchor),
//        ])
//        view.titleMetaLabel.setContentHuggingPriority(.defaultLow - 10, for: .horizontal)
//
//        view.percentageMetaLabel.translatesAutoresizingMaskIntoConstraints = false
//        view.containerView.addSubview(view.percentageMetaLabel)
//        NSLayoutConstraint.activate([
//            view.percentageMetaLabel.leadingAnchor.constraint(equalTo: view.titleMetaLabel.trailingAnchor, constant: 4),
//            view.containerView.trailingAnchor.constraint(equalTo: view.percentageMetaLabel.trailingAnchor, constant: 8),
//            view.percentageMetaLabel.centerYAnchor.constraint(equalTo: view.containerView.centerYAnchor),
//        ])
//        view.percentageMetaLabel.setContentHuggingPriority(.required - 10, for: .horizontal)
//        view.percentageMetaLabel.setContentCompressionResistancePriority(.required - 2, for: .horizontal)
//
//        view.titleMetaLabel.isUserInteractionEnabled = false
//        view.percentageMetaLabel.isUserInteractionEnabled = false
//    }
//
//    private func layoutEdit(view: PollOptionView) {
//        view.containerView.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(view.containerView)
//        NSLayoutConstraint.activate([
//            view.containerView.topAnchor.constraint(equalTo: view.topAnchor),
//            view.containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            view.containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            view.containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//        ])
//
//        view.textField.translatesAutoresizingMaskIntoConstraints = false
//        view.containerView.addSubview(view.textField)
//        NSLayoutConstraint.activate([
//            view.textField.topAnchor.constraint(equalTo: view.containerView.topAnchor),
//            view.textField.leadingAnchor.constraint(equalTo: view.containerView.leadingAnchor),
//            view.textField.trailingAnchor.constraint(equalTo: view.containerView.trailingAnchor),
//            view.textField.bottomAnchor.constraint(equalTo: view.containerView.bottomAnchor),
//        ])
//
//        view.containerView.layer.masksToBounds = true
//        view.containerView.layer.cornerRadius = 6
//        view.containerView.layer.cornerCurve = .continuous
//        view.containerView.layer.borderColor = UIColor.secondaryLabel.cgColor
//        view.containerView.layer.borderWidth = UIView.separatorLineHeight(of: view)
//    }
//
//}
//
//// MARK; - DeleteBackwardResponseTextFieldDelegate
//extension PollOptionView: DeleteBackwardResponseTextFieldDelegate {
//    public func deleteBackwardResponseTextField(_ textField: DeleteBackwardResponseTextField, textBeforeDelete: String?) {
//        delegate?.pollOptionView(self, deleteBackwardResponseTextField: textField, textBeforeDelete: textBeforeDelete)
//    }
//}
//
//#if DEBUG
//import SwiftUI
//struct PollOptionView_Preview: PreviewProvider {
//    static var previews: some View {
//        Group {
//            UIViewPreview(width: 400, height: 36) {
//                let pollOptionView = PollOptionView()
//                pollOptionView.setup(style: .edit)
//                return pollOptionView
//            }
//            .frame(width: 400, height: 36)
//            .padding(10)
//            .previewLayout(.sizeThatFits)
//            .previewDisplayName("Edit")
//            UIViewPreview(width: 400, height: 36) {
//                let pollOptionView = PollOptionView()
//                pollOptionView.setup(style: .plain)
//                return pollOptionView
//            }
//            .frame(width: 400, height: 36)
//            .padding(10)
//            .previewLayout(.sizeThatFits)
//            .previewDisplayName("Plain")
//        }
//    }
//}
//#endif
