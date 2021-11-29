//
//  ComposePollTableViewCell.swift
//  
//
//  Created by MainasuK on 2021-11-29.
//

import UIKit
import Combine
import TwidereCore
import TwidereUI
import MetaTextKit
import MastodonMeta

public protocol ComposePollTableViewCellDelegate: AnyObject {
    func composePollTableViewCell(_ cell: ComposePollTableViewCell, pollOptionCollectionViewCell collectionViewCell: ComposePollOptionCollectionViewCell, textFieldDidBeginEditing textField: UITextField)
    func composePollTableViewCell(_ cell: ComposePollTableViewCell, pollOptionCollectionViewCell collectionViewCell: ComposePollOptionCollectionViewCell, textFieldDidReturn: UITextField)
    func composePollTableViewCell(_ cell: ComposePollTableViewCell, pollOptionCollectionViewCell collectionViewCell: ComposePollOptionCollectionViewCell, textBeforeDeleteBackward text: String?)
}

public final class ComposePollTableViewCell: UITableViewCell {
    
    var observations = Set<NSKeyValueObservation>()
    
    weak var delegate: ComposePollTableViewCellDelegate?

//    weak var customEmojiPickerInputViewModel: CustomEmojiPickerInputViewModel?
//    weak var delegate: ComposeStatusPollTableViewCellDelegate?
//    weak var composeStatusPollOptionCollectionViewCellDelegate: ComposeStatusPollOptionCollectionViewCellDelegate?
//    weak var composeStatusPollOptionAppendEntryCollectionViewCellDelegate: ComposeStatusPollOptionAppendEntryCollectionViewCellDelegate?
//    weak var composeStatusPollExpiresOptionCollectionViewCellDelegate: ComposeStatusPollExpiresOptionCollectionViewCellDelegate?

    private static func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(44))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(44))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsetsReference = .readableContent
        return UICollectionViewCompositionalLayout(section: section)
    }
    
    public let collectionView: UICollectionView = {
        let collectionViewLayout = ComposePollTableViewCell.createLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        collectionView.register(ComposePollOptionCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: ComposePollOptionCollectionViewCell.self))
//        collectionView.register(ComposeStatusPollOptionAppendEntryCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: ComposeStatusPollOptionAppendEntryCollectionViewCell.self))
//        collectionView.register(ComposeStatusPollExpiresOptionCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: ComposeStatusPollExpiresOptionCollectionViewCell.self))
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = false
        collectionView.isScrollEnabled = false
        // collectionView.dragInteractionEnabled = true
        return collectionView
    }()
    public internal(set) var collectionViewHeightLayoutConstraint: NSLayoutConstraint!
    let collectionViewHeightDidUpdate = PassthroughSubject<Void, Never>()
    
    public private(set) var diffableDataSource: UICollectionViewDiffableDataSource<PollSection, PollItem>?
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension ComposePollTableViewCell {
    
    private func _init() {
        let collectionViewLeadingMargin: CGFloat = ComposeInputTableViewCell.avatarImageViewSize.width
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(collectionView)
        collectionViewHeightLayoutConstraint = collectionView.heightAnchor.constraint(equalToConstant: 100).priority(.required - 1)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: contentView.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor, constant: collectionViewLeadingMargin),
            collectionView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            collectionViewHeightLayoutConstraint,
        ])
        
        diffableDataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item in
            switch item {
            case .option(let option):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ComposePollOptionCollectionViewCell.self), for: indexPath) as! ComposePollOptionCollectionViewCell
                cell.pollOptionView.textField.text = option.option
                cell.pollOptionView.textField.placeholder = "Choice \(indexPath.row + 1)"      // TODO: i18n
                cell.delegate = self
                return cell
            case .expireConfiguration(let configuration):
                return UICollectionViewCell()
            case .multipleConfiguration(let configuration):
                return UICollectionViewCell()
            }
        }
    }
    
}

// MARK: - ComposePollOptionCollectionViewCellDelegate
extension ComposePollTableViewCell: ComposePollOptionCollectionViewCellDelegate {
    public func composePollOptionCollectionViewCell(_ cell: ComposePollOptionCollectionViewCell, textFieldDidBeginEditing textField: UITextField) {
        delegate?.composePollTableViewCell(self, pollOptionCollectionViewCell: cell, textFieldDidBeginEditing: textField)
    }
    
    public func composePollOptionCollectionViewCell(_ cell: ComposePollOptionCollectionViewCell, textFieldDidReturn textField: UITextField) {
        delegate?.composePollTableViewCell(self, pollOptionCollectionViewCell: cell, textFieldDidReturn: textField)
    }
    
    public func composePollOptionCollectionViewCell(_ cell: ComposePollOptionCollectionViewCell, textField: DeleteBackwardResponseTextField, textBeforeDelete: String?) {
        delegate?.composePollTableViewCell(self, pollOptionCollectionViewCell: cell, textBeforeDeleteBackward: textBeforeDelete)
    }
}
