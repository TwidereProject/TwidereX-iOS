//
//  ReplyStatusView.swift
//  
//
//  Created by MainasuK on 2022-5-18.
//

import UIKit
import Combine

public final class ReplyStatusView: UIView {
    
    public var disposeBag = Set<AnyCancellable>()
    private var observations = Set<NSKeyValueObservation>()
    
    public let statusView = StatusView()
    public private(set)var widthLayoutConstraint: NSLayoutConstraint!
    
    public let conversationLinkLineView = SeparatorLineView()
        
    public override var intrinsicContentSize: CGSize {
        return statusView.frame.size
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension ReplyStatusView {
    private func _init() {
        widthLayoutConstraint = widthAnchor.constraint(equalToConstant: frame.width)
        
        statusView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(statusView)
        NSLayoutConstraint.activate([
            statusView.topAnchor.constraint(equalTo: topAnchor),
            statusView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: statusView.trailingAnchor),
            statusView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        statusView.setup(style: .composeReply)
        
        conversationLinkLineView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(conversationLinkLineView)
        NSLayoutConstraint.activate([
            conversationLinkLineView.topAnchor.constraint(equalTo: statusView.authorAvatarButton.bottomAnchor, constant: 2),
            conversationLinkLineView.centerXAnchor.constraint(equalTo: statusView.authorAvatarButton.centerXAnchor),
            bottomAnchor.constraint(equalTo: conversationLinkLineView.bottomAnchor),
            conversationLinkLineView.widthAnchor.constraint(equalToConstant: 1),
        ])
        
        // trigger UIViewRepresentable size update
        statusView
            .observe(\.bounds, options: [.initial, .new]) { [weak self] statusView, _ in
                guard let self = self else { return }
                print(statusView.frame)
                self.invalidateIntrinsicContentSize()
            }
            .store(in: &observations)
    }
}
