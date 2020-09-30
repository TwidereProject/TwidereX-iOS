//
//  TimelineBottomLoaderTableViewCell.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-8.
//

import UIKit
import Combine

final class TimelineBottomLoaderTableViewCell: UITableViewCell {
    
    var disposeBag = Set<AnyCancellable>()
    
    let loadMoreButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = .systemFont(ofSize: 13)
        button.setTitle("Load More…", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.setTitleColor(UIColor.systemBlue.withAlphaComponent(0.5), for: .highlighted)
        return button
    }()
    
    let activityIndicatorView: UIActivityIndicatorView = {
        let activityIndicatorView = UIActivityIndicatorView(style: .medium)
        activityIndicatorView.tintColor = .systemFill
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.startAnimating()
        return activityIndicatorView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension TimelineBottomLoaderTableViewCell {
    
    private func _init() {
        loadMoreButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(loadMoreButton)
        NSLayoutConstraint.activate([
            loadMoreButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            loadMoreButton.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            contentView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: loadMoreButton.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: loadMoreButton.bottomAnchor, constant: 8),
        ])
        
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(activityIndicatorView)
        NSLayoutConstraint.activate([
            activityIndicatorView.topAnchor.constraint(equalTo: topAnchor),
            activityIndicatorView.centerXAnchor.constraint(equalTo: centerXAnchor),
            bottomAnchor.constraint(equalTo: activityIndicatorView.bottomAnchor),
        ])
    }
    
}

