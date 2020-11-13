//
//  TimelinePostActionToolbar.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-17.
//

import os.log
import UIKit

protocol TimelinePostActionToolbarDelegate: class {
    func timelinePostActionToolbar(_ toolbar: TimelinePostActionToolbar, replayButtonDidPressed sender: UIButton)
    func timelinePostActionToolbar(_ toolbar: TimelinePostActionToolbar, retweetButtonDidPressed sender: UIButton)
    func timelinePostActionToolbar(_ toolbar: TimelinePostActionToolbar, favoriteButtonDidPressed sender: UIButton)
    func timelinePostActionToolbar(_ toolbar: TimelinePostActionToolbar, shareButtonDidPressed sender: UIButton)
}

final class TimelinePostActionToolbar: UIView {
    
    weak var delegate: TimelinePostActionToolbarDelegate?
    
    static let height: CGFloat = 40
    static let buttonTitleImagePadding: CGFloat = 4
    
    var retweetButtonHighligh: Bool = false {
        didSet {
            retweetButtonHighlightStateDidChange(to: retweetButtonHighligh)
        }
    }
    
    var likeButtonHighlight: Bool = false {
        didSet {
            likeButtonHighlightStateDidChange(to: likeButtonHighlight)
        }
    }
    
    let replyButton: UIButton = {
        let button = HitTestExpandedButton()
        button.tintColor = .secondaryLabel
        button.titleLabel?.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        button.setImage(Asset.Arrows.arrowTurnUpLeft.image.withRenderingMode(.alwaysTemplate), for: .normal)
        button.setTitle("", for: .normal)
        button.setTitleColor(.secondaryLabel, for: .normal)
        button.setInsets(forContentPadding: .zero, imageTitlePadding: TimelinePostActionToolbar.buttonTitleImagePadding)
        button.contentHorizontalAlignment = .leading
        return button
    }()
    
    let retweetButton: UIButton = {
        let button = HitTestExpandedButton(type: .custom)
        button.tintColor = .secondaryLabel
        button.titleLabel?.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        button.contentHorizontalAlignment = .leading
        button.setImage(Asset.Media.repeat.image.withRenderingMode(.alwaysTemplate), for: .normal)
        button.setTitle("", for: .normal)
        button.setTitleColor(.secondaryLabel, for: .normal)
        button.setInsets(forContentPadding: .zero, imageTitlePadding: TimelinePostActionToolbar.buttonTitleImagePadding)
        return button
    }()
    
    let favoriteButton: UIButton = {
        let button = HitTestExpandedButton(type: .custom)
        button.tintColor = .secondaryLabel
        button.titleLabel?.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        button.contentHorizontalAlignment = .leading
        button.setImage(Asset.Health.heart.image.withRenderingMode(.alwaysTemplate), for: .normal)
        button.setTitle("", for: .normal)
        button.setTitleColor(.secondaryLabel, for: .normal)
        button.setInsets(forContentPadding: .zero, imageTitlePadding: TimelinePostActionToolbar.buttonTitleImagePadding)
        return button
    }()
    
    let shareButton: UIButton = {
        let button = HitTestExpandedButton()
        button.tintColor = .secondaryLabel
        button.titleLabel?.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        button.contentHorizontalAlignment = .trailing
        button.setImage(Asset.Arrows.squareAndArrowUpMini.image.withRenderingMode(.alwaysTemplate), for: .normal)
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension TimelinePostActionToolbar {
    
    private func _init() {
        let containerStackView = UIStackView()
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerStackView)
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: topAnchor),
            containerStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: containerStackView.trailingAnchor),
            bottomAnchor.constraint(equalTo: containerStackView.bottomAnchor),
        ])
        
        containerStackView.axis = .horizontal
        containerStackView.distribution = .fill
        
        replyButton.translatesAutoresizingMaskIntoConstraints = false
        retweetButton.translatesAutoresizingMaskIntoConstraints = false
        favoriteButton.translatesAutoresizingMaskIntoConstraints = false
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.addArrangedSubview(replyButton)
        containerStackView.addArrangedSubview(retweetButton)
        containerStackView.addArrangedSubview(favoriteButton)
        containerStackView.addArrangedSubview(shareButton)
        NSLayoutConstraint.activate([
            replyButton.heightAnchor.constraint(equalToConstant: 40).priority(.defaultHigh),
            replyButton.heightAnchor.constraint(equalTo: retweetButton.heightAnchor).priority(.defaultHigh),
            replyButton.heightAnchor.constraint(equalTo: favoriteButton.heightAnchor).priority(.defaultHigh),
            replyButton.heightAnchor.constraint(equalTo: shareButton.heightAnchor).priority(.defaultHigh),
            replyButton.widthAnchor.constraint(equalTo: retweetButton.widthAnchor).priority(.defaultHigh),
            replyButton.widthAnchor.constraint(equalTo: favoriteButton.widthAnchor).priority(.defaultHigh),
        ])
        shareButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        shareButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        
        replyButton.addTarget(self, action: #selector(TimelinePostActionToolbar.replyButtonDidPressed(_:)), for: .touchUpInside)
        retweetButton.addTarget(self, action: #selector(TimelinePostActionToolbar.retweetButtonDidPressed(_:)), for: .touchUpInside)
        favoriteButton.addTarget(self, action: #selector(TimelinePostActionToolbar.favoriteButtonDidPressed(_:)), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(TimelinePostActionToolbar.shareButtonDidPressed(_:)), for: .touchUpInside)
    }
}

extension TimelinePostActionToolbar {

    @objc private func replyButtonDidPressed(_ sender: UIButton) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.timelinePostActionToolbar(self, replayButtonDidPressed: sender)
    }
    
    @objc private func retweetButtonDidPressed(_ sender: UIButton) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.timelinePostActionToolbar(self, retweetButtonDidPressed: sender)
    }
    
    @objc private func favoriteButtonDidPressed(_ sender: UIButton) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.timelinePostActionToolbar(self, favoriteButtonDidPressed: sender)
    }
    
    @objc private func shareButtonDidPressed(_ sender: UIButton) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.timelinePostActionToolbar(self, shareButtonDidPressed: sender)
    }

}

extension TimelinePostActionToolbar {
    
    private func retweetButtonHighlightStateDidChange(to isHighlight: Bool) {
        let tintColor = isHighlight ? Asset.Colors.hightLight.color : .secondaryLabel
        retweetButton.tintColor = tintColor
        retweetButton.setTitleColor(tintColor, for: .normal)
        retweetButton.setTitleColor(tintColor.withAlphaComponent(0.8), for: .highlighted)
    }
    
    private func likeButtonHighlightStateDidChange(to isHighlight: Bool) {
        let tintColor = isHighlight ? Asset.Colors.heartPink.color : .secondaryLabel
        let buttonImage = isHighlight ? Asset.Health.heartFill.image.withRenderingMode(.alwaysTemplate) :
            Asset.Health.heart.image.withRenderingMode(.alwaysTemplate)
        favoriteButton.tintColor = tintColor
        favoriteButton.setImage(buttonImage, for: .normal)
        favoriteButton.setTitleColor(tintColor, for: .normal)
        favoriteButton.setTitleColor(tintColor.withAlphaComponent(0.8), for: .highlighted)
    }
    
}

#if DEBUG
import SwiftUI

struct TimelinePostActionToolbar_Previews: PreviewProvider {
    static var previews: some View {
        UIViewPreview(width: 300) {
            let toolbar = TimelinePostActionToolbar()
            return toolbar
        }
        .previewLayout(.fixed(width: 300, height: 100))
    }
}
#endif

