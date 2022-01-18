//
//  ComposeAttachmentTableViewCell.swift
//  
//
//  Created by MainasuK on 2021/11/19.
//

import UIKit
import TwidereCommon
import TwidereLocalization
import AlamofireImage
import TwidereUI

public protocol ComposeAttachmentTableViewCellDelegate: AnyObject {
    func composeAttachmentTableViewCell(_ cell: ComposeAttachmentTableViewCell, contextMenuAction: ComposeAttachmentTableViewCell.ContextMenuAction, for item: ComposeAttachmentTableViewCell.Item)
}

final public class ComposeAttachmentTableViewCell: UITableViewCell {
    
    public weak var delegate: ComposeAttachmentTableViewCellDelegate?
        
    private static func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .absolute(ComposeAttachmentCollectionViewCell.dimension), heightDimension: .absolute(ComposeAttachmentCollectionViewCell.dimension))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        group.interItemSpacing = .fixed(10)
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsetsReference = .layoutMargins
        section.interGroupSpacing = 10
        section.orthogonalScrollingBehavior = .continuous
        return UICollectionViewCompositionalLayout(section: section)
    }

    private(set) var collectionViewHeightLayoutConstraint: NSLayoutConstraint!
    public let collectionView: UICollectionView = {
        let collectionViewLayout = ComposeAttachmentTableViewCell.createLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        collectionView.register(ComposeAttachmentCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: ComposeAttachmentCollectionViewCell.self))
        collectionView.backgroundColor = .clear
        collectionView.layer.masksToBounds = false
        return collectionView
    }()
    
    public private(set) var diffableDataSource: UICollectionViewDiffableDataSource<Section, Item>!

    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension ComposeAttachmentTableViewCell {
    public enum Section: Hashable {
        case main
    }
    
    public enum Item: Hashable {
        case attachment(viewModel: AttachmentViewModel)
    }
    
    public enum ContextMenuAction {
        case remove
    }
}

extension ComposeAttachmentTableViewCell {
    
    private func _init() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        // contentView.preservesSuperviewLayoutMargins = true
        collectionView.preservesSuperviewLayoutMargins = true
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: 16),
            collectionView.heightAnchor.constraint(equalToConstant: ComposeAttachmentCollectionViewCell.dimension).priority(.required - 1),
        ])
        
        diffableDataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item in
            switch item {
            case .attachment(let viewModel):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ComposeAttachmentCollectionViewCell.self), for: indexPath) as! ComposeAttachmentCollectionViewCell
                viewModel.$thumbnail
                    .receive(on: DispatchQueue.main)
                    .sink { [weak cell] thumbnail in
                        guard let cell = cell else { return }
                        let scale = cell.window?.screen.scale ?? 3
                        cell.imageView.image = thumbnail?.af.imageAspectScaled(
                            toFill: ComposeAttachmentCollectionViewCell.imageViewSize,
                            scale: scale
                        )
                    }
                    .store(in: &cell.disposeBag)
                viewModel.$output
                    .receive(on: DispatchQueue.main)
                    .sink { [weak cell] output in
                        guard let cell = cell else { return }
                        
                        cell.activityIndicatorView.stopAnimating()
                        switch output {
                        case .video:
                            cell.setPlayerBadgeDisplay()
                        case .image:
                            break
                        case nil:
                            cell.activityIndicatorView.startAnimating()
                        }
                    }
                    .store(in: &cell.disposeBag)
                    
                return cell
            }
        }
        collectionView.delegate = self
    }
    
}

// MARK: - UICollectionViewDelegate
extension ComposeAttachmentTableViewCell: UICollectionViewDelegate {
    
    public func collectionView(
        _ collectionView: UICollectionView,
        contextMenuConfigurationForItemAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        guard let item = self.diffableDataSource.itemIdentifier(for: indexPath),
              case let .attachment(attachmentViewModel) = item else {
            return nil
        }
        
        let contextMenuConfiguration = TimelineTableViewCellContextMenuConfiguration(identifier: nil) { () -> UIViewController? in
            guard let thumbnail = attachmentViewModel.thumbnail else { return nil }
            let previewProvider = ContextMenuImagePreviewViewController()
            let contextMenuImagePreviewViewModel = ContextMenuImagePreviewViewModel(
                aspectRatio: thumbnail.size,
                thumbnail: thumbnail
            )
            previewProvider.viewModel = contextMenuImagePreviewViewModel
            return previewProvider
        } actionProvider: { _ -> UIMenu? in
            let removeAction = UIAction(
                title: L10n.Common.Controls.Actions.remove,
                image: UIImage(systemName: "minus.circle"),
                identifier: nil,
                discoverabilityTitle: nil,
                attributes: .destructive,
                state: .off
            ) { [weak self] _ in
                guard let self = self else { return }
                self.delegate?.composeAttachmentTableViewCell(self, contextMenuAction: .remove, for: item)
            }
            
            return UIMenu(title: "", image: nil, identifier: nil, options: [], children: [
                removeAction
            ])
        }
        contextMenuConfiguration.indexPath = indexPath
        return contextMenuConfiguration
    }
    
    public func collectionView(
        _ collectionView: UICollectionView,
        previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration
    ) -> UITargetedPreview? {
        return targetedPreview(in: collectionView, configuration: configuration)
    }
    
    public func collectionView(
        _ collectionView: UICollectionView,
        previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration
    ) -> UITargetedPreview? {
        return targetedPreview(in: collectionView, configuration: configuration)
    }
    
    private func targetedPreview(
        in collectionView: UICollectionView,
        configuration: UIContextMenuConfiguration
    ) -> UITargetedPreview? {
        guard let configuration = configuration as? TimelineTableViewCellContextMenuConfiguration else {
            assertionFailure()
            return nil
        }
        guard let indexPath = configuration.indexPath else { return nil }
        guard let cell = collectionView.cellForItem(at: indexPath) as? ComposeAttachmentCollectionViewCell else { return nil }
        return UITargetedPreview(view: cell.imageView, parameters: UIPreviewParameters())
    }
}
