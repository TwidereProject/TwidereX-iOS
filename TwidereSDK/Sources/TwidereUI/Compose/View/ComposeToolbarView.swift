//
//  ComposeToolbarView.swift
//  
//
//  Created by MainasuK on 2021/11/18.
//

import os.log
import UIKit
import TwidereLocalization

public protocol ComposeToolbarViewDelegate: AnyObject {
    func composeToolBarView(_ composeToolBarView: ComposeToolbarView, mediaButtonPressed button: UIButton, mediaSelectionType type: ComposeToolbarView.MediaSelectionType)
    func composeToolBarView(_ composeToolBarView: ComposeToolbarView, emojiButtonPressed button: UIButton)
    func composeToolBarView(_ composeToolBarView: ComposeToolbarView, pollButtonPressed button: UIButton)
    func composeToolBarView(_ composeToolBarView: ComposeToolbarView, mentionButtonPressed button: UIButton)
    func composeToolBarView(_ composeToolBarView: ComposeToolbarView, hashtagButtonPressed button: UIButton)
    func composeToolBarView(_ composeToolBarView: ComposeToolbarView, localButtonPressed button: UIButton)
}

final public class ComposeToolbarView: UIView {
    
    let logger = Logger(subsystem: "ComposeToolbarView", category: "View")
    public weak var delegate: ComposeToolbarViewDelegate?
    
    public let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()
    
    public let container: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 16
        return stackView
    }()
    
    public private(set) lazy var mediaButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(Action.media.image(of: .normal), for: .normal)
        button.tintColor = .secondaryLabel
        return button
    }()
    
    public private(set) lazy var emojiButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(Action.emoji.image(of: .normal), for: .normal)
        button.tintColor = .secondaryLabel
        return button
    }()
    
    public private(set) lazy var pollButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(Action.poll.image(of: .normal), for: .normal)
        button.tintColor = .secondaryLabel
        return button
    }()
    
    public private(set) lazy var mentionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(Action.mention.image(of: .normal), for: .normal)
        button.tintColor = .secondaryLabel
        return button
    }()
    
    public private(set) lazy var hashtagButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(Action.hashtag.image(of: .normal), for: .normal)
        button.tintColor = .secondaryLabel
        return button
    }()
    
    public private(set) lazy var localButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(Action.location.image(of: .normal), for: .normal)
        button.tintColor = .secondaryLabel
        return button
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension ComposeToolbarView {
    private func _init() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.frameLayoutGuide.topAnchor.constraint(equalTo: topAnchor),
            scrollView.frameLayoutGuide.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.frameLayoutGuide.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.frameLayoutGuide.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.frameLayoutGuide.heightAnchor.constraint(equalTo: scrollView.contentLayoutGuide.heightAnchor).priority(.required - 1),
        ])
        
        container.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 12),
            container.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            scrollView.contentLayoutGuide.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: 12),
            scrollView.contentLayoutGuide.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: 16),
        ])
        
        container.addArrangedSubview(mediaButton)
        container.addArrangedSubview(emojiButton)
        container.addArrangedSubview(pollButton)
        container.addArrangedSubview(mentionButton)
        container.addArrangedSubview(hashtagButton)
        container.addArrangedSubview(localButton)

        let spacer = UIView()
        container.addArrangedSubview(spacer)

        mediaButton.menu = createMediaContextMenu(button: mediaButton)
        mediaButton.showsMenuAsPrimaryAction = true
        emojiButton.addTarget(self, action: #selector(ComposeToolbarView.emojiButtonPressed(_:)), for: .touchUpInside)
        pollButton.addTarget(self, action: #selector(ComposeToolbarView.pollButtonPressed(_:)), for: .touchUpInside)
        mentionButton.addTarget(self, action: #selector(ComposeToolbarView.mentionButtonPressed(_:)), for: .touchUpInside)
        hashtagButton.addTarget(self, action: #selector(ComposeToolbarView.hashtagButtonPressed(_:)), for: .touchUpInside)
        localButton.addTarget(self, action: #selector(ComposeToolbarView.localButtonPressed(_:)), for: .touchUpInside)


    }
}

extension ComposeToolbarView {
    public enum MediaSelectionType: String {
        case camera
        case photoLibrary
        case browse
    }
    
    private func createMediaContextMenu(button: UIButton) -> UIMenu {
        var children: [UIMenuElement] = []
        let photoLibraryAction = UIAction(
            title: L10n.Common.Controls.Ios.photoLibrary,
            image: UIImage(systemName: "rectangle.on.rectangle"),
            identifier: nil,
            discoverabilityTitle: nil,
            attributes: [],
            state: .off
        ) { [weak self, weak button] _ in
            guard let self = self else { return }
            guard let button = button else { return }
            self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): select .photoLibrary")
            self.delegate?.composeToolBarView(self, mediaButtonPressed: button, mediaSelectionType: .photoLibrary)
        }
        children.append(photoLibraryAction)
        
//        if UIImagePickerController.isSourceTypeAvailable(.camera) {
//            let cameraAction = UIAction(title: L10n.Scene.Compose.MediaSelection.camera, image: UIImage(systemName: "camera"), identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off, handler: { [weak self] _ in
//                guard let self = self else { return }
//                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: mediaSelectionType: .camera", ((#file as NSString).lastPathComponent), #line, #function)
//                self.delegate?.composeToolbarView(self, cameraButtonDidPressed: self.mediaButton, mediaSelectionType: .camera)
//            })
//            children.append(cameraAction)
//        }
//        let browseAction = UIAction(title: L10n.Scene.Compose.MediaSelection.browse, image: UIImage(systemName: "ellipsis"), identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off) { [weak self] _ in
//            guard let self = self else { return }
//            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: mediaSelectionType: .browse", ((#file as NSString).lastPathComponent), #line, #function)
//            self.delegate?.composeToolbarView(self, cameraButtonDidPressed: self.mediaButton, mediaSelectionType: .browse)
//        }
//        children.append(browseAction)
        
        return UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: children)
    }
}

extension ComposeToolbarView {
    @objc private func emojiButtonPressed(_ sender: UIButton) {
        delegate?.composeToolBarView(self, emojiButtonPressed: sender)
    }
    
    @objc private func pollButtonPressed(_ sender: UIButton) {
        delegate?.composeToolBarView(self, pollButtonPressed: sender)
    }
    
    @objc private func mentionButtonPressed(_ sender: UIButton) {
        delegate?.composeToolBarView(self, mentionButtonPressed: sender)
    }
    
    @objc private func hashtagButtonPressed(_ sender: UIButton) {
        delegate?.composeToolBarView(self, hashtagButtonPressed: sender)
    }
    
    @objc private func localButtonPressed(_ sender: UIButton) {
        delegate?.composeToolBarView(self, localButtonPressed: sender)
    }
}
