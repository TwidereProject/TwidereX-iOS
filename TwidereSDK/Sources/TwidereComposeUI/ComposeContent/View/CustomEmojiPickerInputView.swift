//
//  CustomEmojiPickerInputView.swift
//  
//
//  Created by MainasuK on 2021-11-28.
//

import os.log
import UIKit

public protocol CustomEmojiPickerInputViewDelegate: AnyObject {
    func customEmojiPickerInputView(_ inputView: CustomEmojiPickerInputView, didSelectItemAt indexPath: IndexPath)
}

public final class CustomEmojiPickerInputView: UIInputView {
    
    let logger = Logger(subsystem: "CustomEmojiPickerInputView", category: "View")
    
    public weak var delegate: CustomEmojiPickerInputViewDelegate?
        
    public private(set) lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.register(CustomEmojiPickerItemCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: CustomEmojiPickerItemCollectionViewCell.self))
        collectionView.register(CustomEmojiPickerHeaderCollectionReusableView.self, forSupplementaryViewOfKind: String(describing: CustomEmojiPickerHeaderCollectionReusableView.self), withReuseIdentifier: String(describing: CustomEmojiPickerHeaderCollectionReusableView.self))
        collectionView.backgroundColor = .secondarySystemBackground
        return collectionView
    }()
    
    public let activityIndicatorView = UIActivityIndicatorView(style: .large)
    
    public override init(frame: CGRect, inputViewStyle: UIInputView.Style) {
        super.init(frame: frame, inputViewStyle: inputViewStyle)
        _init()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension CustomEmojiPickerInputView {
    private func _init() {
        allowsSelfSizing = true
        
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(activityIndicatorView)
        NSLayoutConstraint.activate([
            activityIndicatorView.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.startAnimating()
        
        collectionView.delegate = self
    }
}

extension CustomEmojiPickerInputView {
    func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .absolute(CustomEmojiPickerItemCollectionViewCell.itemSize.width),
                                             heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.edgeSpacing = NSCollectionLayoutEdgeSpacing(leading: .flexible(4), top: .flexible(4), trailing: .flexible(0), bottom: .flexible(0))
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .absolute(CustomEmojiPickerItemCollectionViewCell.itemSize.height))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 5
        section.contentInsetsReference = .readableContent
        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0)

        let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .estimated(44)),
            elementKind: String(describing: CustomEmojiPickerHeaderCollectionReusableView.self),
            alignment: .top)
        sectionHeader.pinToVisibleBounds = true
        sectionHeader.zIndex = 2
        section.boundarySupplementaryItems = [sectionHeader]

        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }
}

// MARK: - UIInputViewAudioFeedback
extension CustomEmojiPickerInputView: UIInputViewAudioFeedback {
    public var enableInputClicksWhenVisible: Bool {
        return true
    }
}

// MARK; - UICollectionViewDelegate
extension CustomEmojiPickerInputView: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): select item at \(indexPath.debugDescription)")

        UIDevice.current.playInputClick()
        
        delegate?.customEmojiPickerInputView(self, didSelectItemAt: indexPath)
    }
}
