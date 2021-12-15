//
//  MediaInfoDescriptionView.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-5.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import MetaTextKit
import MetaTextArea
import TwidereUI

protocol MediaInfoDescriptionViewDelegate: AnyObject {
    func mediaInfoDescriptionView(_ mediaInfoDescriptionView: MediaInfoDescriptionView, avatarButtonDidPressed button: UIButton)
    func mediaInfoDescriptionView(_ mediaInfoDescriptionView: MediaInfoDescriptionView, contentTextViewDidPressed textView: MetaTextAreaView)
    func mediaInfoDescriptionView(_ mediaInfoDescriptionView: MediaInfoDescriptionView, nameMetaLabelDidPressed metaLabel: MetaLabel)
    func mediaInfoDescriptionView(_ mediaInfoDescriptionView: MediaInfoDescriptionView, statusToolbar: StatusToolbar, actionDidPressed action: StatusToolbar.Action, button: UIButton)
    func mediaInfoDescriptionView(_ mediaInfoDescriptionView: MediaInfoDescriptionView, statusToolbar: StatusToolbar, menuActionDidPressed action: StatusToolbar.MenuAction, menuButton button: UIButton)
}

final class MediaInfoDescriptionView: UIView {
    
    static let avatarImageViewSize = CGSize(width: 32, height: 32)
    
    let logger = Logger(subsystem: "MediaInfoDescriptionView", category: "View")
    
    weak var delegate: MediaInfoDescriptionViewDelegate?
    
    var disposeBag = Set<AnyCancellable>()
    private(set) lazy var viewModel: ViewModel = {
        let viewModel = ViewModel()
        viewModel.bind(view: self)
        return viewModel
    }()
    
    let avatarView: ProfileAvatarView = {
        let avatarView = ProfileAvatarView()
        avatarView.dimension = 32
        return avatarView
    }()
    
    let nameMetaLabel: MetaLabel = {
        let label = MetaLabel(style: .mediaDescriptionAuthorName)
        label.configure(content: PlaintextMetaContent(string: "Alice"))
        return label
    }()
    
    let contentTextView: MetaTextAreaView = {
        let textView = MetaTextAreaView()
        textView.textAttributes = [
            .font: UIFont.preferredFont(forTextStyle: .caption1),
            .foregroundColor: UIColor.white.withAlphaComponent(0.8),
        ]
        textView.linkAttributes = [
            .font: UIFont.preferredFont(forTextStyle: .caption1),
            .foregroundColor: Asset.Colors.hightLight.color,
        ]
        textView.textContainer.maximumNumberOfLines = 2
        textView.textLayoutManager.textContainer?.maximumNumberOfLines = 2
        return textView
    }()
    
    let toolbar: StatusToolbar = {
        let toolbar = StatusToolbar()
        toolbar.setup(style: .plain)
        return toolbar
    }()
    
    let contentTextViewTapGestureRecognizer = UITapGestureRecognizer.singleTapGestureRecognizer
    let nameMetaLabelTapGestureRecognizer = UITapGestureRecognizer.singleTapGestureRecognizer
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension MediaInfoDescriptionView {
    
    private func _init() {
        backgroundColor = UIColor.systemBackground.withAlphaComponent(0.5)
        
        // container: [ video control | content | bottom container ]
        let containerStackView = UIStackView()
        containerStackView.axis = .vertical
        containerStackView.spacing = 8
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerStackView)
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            containerStackView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            readableContentGuide.trailingAnchor.constraint(equalTo: containerStackView.trailingAnchor),
            safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: containerStackView.bottomAnchor, constant: 8),
        ])
        
        
        // FIXME: contentTextView line limit should set to 2
        // containerStackView.addArrangedSubview(contentTextView)
        // contentTextView.setContentHuggingPriority(.defaultHigh + 1, for: .vertical)
        
        // bottom container: [ avatar | name | (padding) | toolbar ]
        let bottomContainerStackView = UIStackView()
        containerStackView.addArrangedSubview(bottomContainerStackView)
        bottomContainerStackView.axis = .horizontal
        bottomContainerStackView.spacing = 8
        bottomContainerStackView.alignment = .center
        
        bottomContainerStackView.addArrangedSubview(avatarView)
        bottomContainerStackView.addArrangedSubview(nameMetaLabel)
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        bottomContainerStackView.addArrangedSubview(toolbar)
        NSLayoutConstraint.activate([
            toolbar.widthAnchor.constraint(equalToConstant: 180).priority(.defaultHigh),
        ])
        
        avatarView.avatarButton.addTarget(self, action: #selector(MediaInfoDescriptionView.avatarButtonDidPressed(_:)), for: .touchUpInside)
        
        contentTextViewTapGestureRecognizer.addTarget(self, action: #selector(MediaInfoDescriptionView.contentTextViewDidPressed(_:)))
        contentTextView.isUserInteractionEnabled = false
        contentTextView.addGestureRecognizer(contentTextViewTapGestureRecognizer)
        
        nameMetaLabelTapGestureRecognizer.addTarget(self, action: #selector(MediaInfoDescriptionView.nameMetaLabelDidPressed(_:)))
        nameMetaLabel.addGestureRecognizer(nameMetaLabelTapGestureRecognizer)
        
        toolbar.delegate = self
    }
    
}

extension MediaInfoDescriptionView {
    
    @objc private func avatarButtonDidPressed(_ sender: UIButton) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        delegate?.mediaInfoDescriptionView(self, avatarButtonDidPressed: sender)
    }
    
    @objc private func contentTextViewDidPressed(_ sender: UITapGestureRecognizer) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        assert(sender.view === contentTextView)
        delegate?.mediaInfoDescriptionView(self, contentTextViewDidPressed: contentTextView)
    }
    
    @objc private func nameMetaLabelDidPressed(_ sender: UITapGestureRecognizer) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        assert(sender.view === nameMetaLabel)
        delegate?.mediaInfoDescriptionView(self, nameMetaLabelDidPressed: nameMetaLabel)
    }

}

// MARK: - StatusToolbarDelegate
extension MediaInfoDescriptionView: StatusToolbarDelegate {
    func statusToolbar(_ statusToolbar: StatusToolbar, actionDidPressed action: StatusToolbar.Action, button: UIButton) {
        delegate?.mediaInfoDescriptionView(self, statusToolbar: statusToolbar, actionDidPressed: action, button: button)
    }
    
    func statusToolbar(_ statusToolbar: StatusToolbar, menuActionDidPressed action: StatusToolbar.MenuAction, menuButton button: UIButton) {
        delegate?.mediaInfoDescriptionView(self, statusToolbar: statusToolbar, menuActionDidPressed: action, menuButton: button)
    }
}

#if DEBUG
import SwiftUI

struct MediaInfoDescriptionView_Previews: PreviewProvider {
    static var previews: some View {
        UIViewPreview(width: 375) {
            MediaInfoDescriptionView()
        }
        .background(Color.white)
        .preferredColorScheme(.dark)
        .previewLayout(.fixed(width: 375, height: 200))
    }
}
#endif
