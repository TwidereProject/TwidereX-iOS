//
//  TimelineMiddleLoaderTableViewCell.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-8.
//

import UIKit
import Combine

final class TimelineMiddleLoaderTableViewCell: UITableViewCell {
    
    var disposeBag = Set<AnyCancellable>()
    
    let loadMoreButton: UIButton = {
        let button = UIButton()
        button.setInsets(forContentPadding: .zero, imageTitlePadding: 4)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.imageView?.tintColor = Asset.Colors.hightLight.color
        button.setImage(Asset.ObjectTools.icRoundRefresh.image.withRenderingMode(.alwaysTemplate), for: .normal)
        button.setTitle("Load More", for: .normal)
        button.setTitleColor(Asset.Colors.hightLight.color, for: .normal)
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
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag.removeAll()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension TimelineMiddleLoaderTableViewCell {
    
    private func _init() {
        backgroundColor = .secondarySystemBackground
        
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
            activityIndicatorView.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        
        let separatorLine = UIView.separatorLine
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separatorLine)
        NSLayoutConstraint.activate([
            separatorLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: separatorLine.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: separatorLine.bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: UIView.separatorLineHeight(of: separatorLine))
        ])
    }
    
}

#if DEBUG
import SwiftUI

struct TimelineMiddleLoaderTableViewCell_Previews: PreviewProvider {
    static var previews: some View {
        UIViewPreview(width: 375) {
            TimelineMiddleLoaderTableViewCell()
        }
        .previewLayout(.fixed(width: 375, height: 80))
    }
}
#endif
