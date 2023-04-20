//
//  TimelineLoaderTableViewCell.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-4.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import Combine
import TwidereCore

public class TimelineLoaderTableViewCell: UITableViewCell {
    
    public static let cellHeight: CGFloat = 48
    
    var disposeBag = Set<AnyCancellable>()
    
    let loadMoreButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = Asset.Colors.hightLight.color
        button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        button.setTitle(L10n.Common.Controls.Timeline.loadMore, for: .normal)
        button.setTitleColor(Asset.Colors.hightLight.color, for: .normal)
        button.setTitleColor(Asset.Colors.hightLight.color.withAlphaComponent(0.8), for: .highlighted)
        return button
    }()
    
    public let activityIndicatorView: UIActivityIndicatorView = {
        let activityIndicatorView = UIActivityIndicatorView(style: .medium)
        activityIndicatorView.tintColor = .systemFill
        activityIndicatorView.hidesWhenStopped = true
        return activityIndicatorView
    }()
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag.removeAll()
    }
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
    func _init() {
        selectionStyle = .none
        
        loadMoreButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(loadMoreButton)
        NSLayoutConstraint.activate([
            loadMoreButton.topAnchor.constraint(equalTo: contentView.topAnchor),
            loadMoreButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: loadMoreButton.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: loadMoreButton.bottomAnchor),
            loadMoreButton.heightAnchor.constraint(equalToConstant: TimelineLoaderTableViewCell.cellHeight).priority(.defaultHigh),
        ])
        
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(activityIndicatorView)
        NSLayoutConstraint.activate([
            activityIndicatorView.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        
        loadMoreButton.isHidden = true
        activityIndicatorView.isHidden = true
    }
    
}

