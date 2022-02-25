//
//  StatusMetricsDashboardView.swift
//  
//
//  Created by MainasuK on 2021-12-7.
//

import os.log
import UIKit
import CoreDataStack
import TwidereCommon
import TwidereCore

public protocol StatusMetricsDashboardViewDelegate: AnyObject {
    func statusMetricsDashboardView(_ statusMetricsDashboardView: StatusMetricsDashboardView, actionDidPressed action: StatusMetricsDashboardView.Action)
}

public final class StatusMetricsDashboardView: UIView {
    
    public static let numberMetricFormatter = NumberMetricFormatter()
    
    let logger = Logger(subsystem: "StatusMetricsDashboardView", category: "View")
    
    public weak var delegate: StatusMetricsDashboardViewDelegate?
    
    public private(set) lazy var viewModel: ViewModel = {
        let viewModel = ViewModel()
        viewModel.bind(view: self)
        return viewModel
    }()
    
    public let container = UIStackView()
    public let metaContainer = UIStackView()

    public let timestampLabel: PlainLabel = {
        let label = PlainLabel(style: .statusMetrics)
        label.textAlignment = .center
        return label
    }()
    
    let sourceLabel: PlainLabel = {
        let label = PlainLabel(style: .statusMetrics)
        label.textAlignment = .center
        return label
    }()
    

    public let dashboardContainer = UIStackView()
    public let replyButton     = HitTestExpandedButton()
    public let repostButton    = HitTestExpandedButton()
    public let quoteButton     = HitTestExpandedButton()
    public let likeButton      = HitTestExpandedButton()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension StatusMetricsDashboardView {
    private func _init() {
        container.translatesAutoresizingMaskIntoConstraints = false
        addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        container.axis = .vertical 
        container.distribution = .fill
        container.alignment = .center
        
        metaContainer.axis = .horizontal
        metaContainer.spacing = 4
        container.addArrangedSubview(metaContainer)
        metaContainer.addArrangedSubview(timestampLabel)
        metaContainer.addArrangedSubview(sourceLabel)
        
        dashboardContainer.axis = .horizontal
        dashboardContainer.spacing = 20
        dashboardContainer.distribution = .fillEqually
        container.addArrangedSubview(dashboardContainer)
        
        let buttons = [replyButton, repostButton, quoteButton, likeButton]
        buttons.forEach { button in
            button.tintColor = .secondaryLabel
            button.titleLabel?.font = .monospacedDigitSystemFont(ofSize: 14, weight: .regular)
            button.setTitle("", for: .normal)
            button.setTitleColor(.secondaryLabel, for: .normal)
            button.setInsets(forContentPadding: .zero, imageTitlePadding: 4)
            button.addTarget(self, action: #selector(StatusMetricsDashboardView.buttonDidPressed(_:)), for: .touchUpInside)
            
            // TODO: coordinate to the user list
            button.accessibilityTraits = .staticText
        }
        
        replyButton.setImage(Asset.Arrows.arrowTurnUpLeftMini.image.withRenderingMode(.alwaysTemplate), for: .normal)
        repostButton.setImage(Asset.Media.repeatMini.image.withRenderingMode(.alwaysTemplate), for: .normal)
        quoteButton.setImage(Asset.TextFormatting.textQuoteMini.image.withRenderingMode(.alwaysTemplate), for: .normal)
        likeButton.setImage(Asset.Health.heartFillMini.image.withRenderingMode(.alwaysTemplate), for: .normal)
        
        let leadingPadding = UIView()
        dashboardContainer.addArrangedSubview(leadingPadding)
        replyButton.translatesAutoresizingMaskIntoConstraints = false
        repostButton.translatesAutoresizingMaskIntoConstraints = false
        quoteButton.translatesAutoresizingMaskIntoConstraints = false
        likeButton.translatesAutoresizingMaskIntoConstraints = false
        dashboardContainer.addArrangedSubview(replyButton)
        dashboardContainer.addArrangedSubview(repostButton)
        dashboardContainer.addArrangedSubview(quoteButton)
        dashboardContainer.addArrangedSubview(likeButton)
        let trailingPadding = UIView()
        dashboardContainer.addArrangedSubview(trailingPadding)
        
        NSLayoutConstraint.activate([
            replyButton.heightAnchor.constraint(equalToConstant: 44).priority(.required - 10),
            replyButton.heightAnchor.constraint(equalTo: repostButton.heightAnchor).priority(.defaultHigh),
            replyButton.heightAnchor.constraint(equalTo: quoteButton.heightAnchor).priority(.defaultHigh),
            replyButton.heightAnchor.constraint(equalTo: likeButton.heightAnchor).priority(.defaultHigh),
        ])
        
    }
}

extension StatusMetricsDashboardView {
    public enum Action: String, CaseIterable {
        case reply
        case repost
        case quote
        case like
    }
}

extension StatusMetricsDashboardView {
    @objc private func buttonDidPressed(_ sender: UIButton) {
        let _action: Action?
        switch sender {
        case replyButton:       _action = .reply
        case repostButton:      _action = .repost
        case quoteButton:       _action = .quote
        case likeButton:        _action = .like
        default:                _action = nil
        }
        
        guard let action = _action else {
            assertionFailure()
            return
        }
        
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): \(action.rawValue) button pressed")
        delegate?.statusMetricsDashboardView(self, actionDidPressed: action)
    }
    
}

extension StatusMetricsDashboardView {

    public func setDashboardDisplay() {
        dashboardContainer.isHidden = false
    }
    
}

#if DEBUG
import SwiftUI
struct StatusMetricsDashboardView_Preview: PreviewProvider {
    static var previews: some View {
        UIViewPreview {
            StatusMetricsDashboardView()
        }
    }
}
#endif
