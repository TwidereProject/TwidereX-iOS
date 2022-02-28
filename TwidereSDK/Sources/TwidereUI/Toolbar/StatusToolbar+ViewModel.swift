//
//  StatusToolbar+ViewModel.swift
//  
//
//  Created by MainasuK on 2022-2-23.
//

import UIKit
import Combine
import CoreDataStack
import TwidereAsset

extension StatusToolbar {
    public final class ViewModel: ObservableObject {
        var disposeBag = Set<AnyCancellable>()
        
        @Published public var traitCollectionDidChange = CurrentValueSubject<Void, Never>(Void())
        @Published public var platform: Platform = .none

        @Published public var replyCount: Int = 0
        @Published public var isReplyEnabled = true
        
        @Published public var repostCount: Int = 0
        @Published public var isRepostEnabled = true
        @Published public var isRepostHighlighted = true
        
        @Published public var likeCount: Int = 0
        // @Published public var isLikeEnabled = true
        @Published public var isLikeHighlighted = true
        
        func bind(view: StatusToolbar) {
            // reply
            Publishers.CombineLatest(
                $replyCount,
                $isReplyEnabled
            )
            .sink { count, isEnabled in
                // title
                let text = ViewModel.metricText(count: count)
                switch view.style {
                case .none:
                    break
                case .inline:
                    view.replyButton.setTitle(text, for: .normal)
                    view.replyButton.accessibilityHint = L10n.Count.reply(count)
                case .plain:
                    view.replyButton.accessibilityHint =  nil
                }
                view.replyButton.accessibilityLabel = L10n.Accessibility.Common.Status.Actions.reply
                
                // isEnabled
                view.replyButton.isEnabled = isEnabled
            }
            .store(in: &disposeBag)
            // repost
            Publishers.CombineLatest3(
                $repostCount,
                $isRepostEnabled,
                $platform
            )
            .sink { count, isEnabled, platform in
                // title
                let text = ViewModel.metricText(count: count)
                switch view.style {
                case .none:
                    break
                case .inline:
                    view.repostButton.setTitle(text, for: .normal)
                    view.repostButton.accessibilityHint = L10n.Count.reblog(count)
                case .plain:
                    view.repostButton.accessibilityHint =  nil
                }
                
                switch platform {
                case .none:
                    view.repostButton.accessibilityLabel = nil
                case .twitter:
                    view.repostButton.accessibilityLabel = L10n.Common.Controls.Status.Actions.retweet
                case .mastodon:
                    view.repostButton.accessibilityLabel = L10n.Common.Controls.Status.Actions.boost
                }
                
                // isEnabled
                view.repostButton.isEnabled = isEnabled
            }
            .store(in: &disposeBag)
            Publishers.CombineLatest(
                $isRepostHighlighted,
                $traitCollectionDidChange
            )
            .sink { isHighlighted, _ in
                // isHighlighted
                let tintColor = isHighlighted ? Asset.Scene.Status.Toolbar.repost.color : .secondaryLabel
                view.repostButton.tintColor = tintColor
                view.repostButton.setTitleColor(tintColor, for: .normal)
                view.repostButton.setTitleColor(tintColor.withAlphaComponent(0.8), for: .highlighted)
                if isHighlighted {
                    view.repostButton.accessibilityTraits.insert(.selected)
                } else {
                    view.repostButton.accessibilityTraits.remove(.selected)
                }
            }
            .store(in: &disposeBag)
            // like
            $likeCount
                .sink { count in
                    // title
                    let text = ViewModel.metricText(count: count)
                    switch view.style {
                    case .none:
                        break
                    case .inline:
                        view.likeButton.setTitle(text, for: .normal)
                        view.likeButton.accessibilityHint = L10n.Count.reply(count)
                    case .plain:
                        view.likeButton.accessibilityHint =  nil
                        // no titile
                    }
                    view.likeButton.accessibilityLabel = L10n.Accessibility.Common.Status.Actions.like
                }
                .store(in: &disposeBag)
            Publishers.CombineLatest(
                $isLikeHighlighted,
                $traitCollectionDidChange
            )
            .sink { isHighlighted, _ in
                // isHighlighted
                let tintColor = isHighlighted ? Asset.Scene.Status.Toolbar.like.color : .secondaryLabel
                view.likeButton.tintColor = tintColor
                view.likeButton.setTitleColor(tintColor, for: .normal)
                view.likeButton.setTitleColor(tintColor.withAlphaComponent(0.8), for: .highlighted)
                switch view.style {
                case .none:
                    break
                case .inline:
                    let image: UIImage = isHighlighted ? Asset.Health.heartFillMini.image : Asset.Health.heartMini.image
                    view.likeButton.setImage(image.withRenderingMode(.alwaysTemplate), for: .normal)
                case .plain:
                    let image: UIImage = isHighlighted ? Asset.Health.heartFill.image : Asset.Health.heart.image
                    view.likeButton.setImage(image.withRenderingMode(.alwaysTemplate), for: .normal)
                }
                if isHighlighted {
                    view.likeButton.accessibilityTraits.insert(.selected)
                } else {
                    view.likeButton.accessibilityTraits.remove(.selected)
                }
            }
            .store(in: &disposeBag)
        }
        
        private static func metricText(count: Int) -> String {
            guard count > 0 else { return "" }
            return StatusToolbar.numberMetricFormatter.string(from: count) ?? ""
        }
    }
}

extension StatusToolbar {

    public func setupReply(count: Int, isEnabled: Bool) {
        viewModel.replyCount = count
        viewModel.isReplyEnabled = isEnabled
    }
    
    public func setupRepost(count: Int, isEnabled: Bool, isHighlighted: Bool) {
        viewModel.repostCount = count
        viewModel.isRepostEnabled = isEnabled
        viewModel.isRepostHighlighted = isHighlighted
    }
    
    public func setupLike(count: Int, isHighlighted: Bool) {
        viewModel.likeCount = count
        viewModel.isLikeHighlighted = isHighlighted
    }
    
    public struct MenuContext {
        let shareText: String?
        let shareLink: String?
        let displayDeleteAction: Bool
    }
    
    public func setupMenu(menuContext: MenuContext) {
        menuButton.menu = {
            var children: [UIMenuElement] = [
                UIAction(
                    title: L10n.Common.Controls.Status.Actions.copyText.capitalized,
                    image: UIImage(systemName: "doc.on.doc"),
                    identifier: nil,
                    discoverabilityTitle: nil,
                    attributes: [],
                    state: .off
                ) { _ in
                    guard let text = menuContext.shareText else { return }
                    UIPasteboard.general.string = text
                },
                UIAction(
                    title: L10n.Common.Controls.Status.Actions.copyLink.capitalized,
                    image: UIImage(systemName: "link"),
                    identifier: nil,
                    discoverabilityTitle: nil,
                    attributes: [],
                    state: .off
                ) { _ in
                    guard let text = menuContext.shareLink else { return }
                    UIPasteboard.general.string = text
                },
                UIAction(
                    title: L10n.Common.Controls.Status.Actions.shareLink.capitalized,
                    image: UIImage(systemName: "square.and.arrow.up"),
                    identifier: nil,
                    discoverabilityTitle: nil,
                    attributes: [],
                    state: .off
                ) { [weak self] _ in
                    guard let self = self else { return }
                    self.delegate?.statusToolbar(self, actionDidPressed: .menu, button: self.menuButton)
                }
            ]
            
            if menuContext.displayDeleteAction {
                let removeAction = UIAction(
                    title: L10n.Common.Controls.Actions.delete,
                    image: UIImage(systemName: "minus.circle"),
                    identifier: nil,
                    discoverabilityTitle: nil,
                    attributes: .destructive,
                    state: .off
                ) { [weak self] _ in
                    guard let self = self else { return }
                    self.delegate?.statusToolbar(self, menuActionDidPressed: .remove, menuButton: self.menuButton)
                }
                children.append(removeAction)
            }
            
            return UIMenu(title: "", options: [], children: children)
        }()
        
        
        menuButton.showsMenuAsPrimaryAction = true
        menuButton.accessibilityLabel = L10n.Accessibility.Common.Status.Actions.menu
    }
    
}
