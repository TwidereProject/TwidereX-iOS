//
//  DataSourceProvider+StatusViewTableViewCellDelegate.swift
//
//
//  Created by Cirno MainasuK on 2021-9-6.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import MetaTextArea
import Meta

// MARK: - header
extension StatusViewTableViewCellDelegate where Self: DataSourceProvider & AuthContextProvider {
    func tableViewCell(
        _ cell: UITableViewCell,
        viewModel: TwidereUI.StatusView.ViewModel,
        statusHeaderViewModel: TwidereUI.StatusHeaderView.ViewModel,
        headerDidPressed: Void
    ) {
        Task {
            guard let user = viewModel.author?.asRecord else { return }
            await DataSourceFacade.coordinateToProfileScene(
                provider: self,
                user: user
            )
        }   // end Task
    }
}

// MARK: - avatar button
extension StatusViewTableViewCellDelegate where Self: DataSourceProvider & AuthContextProvider {
    func tableViewCell(
        _ cell: UITableViewCell,
        viewModel: TwidereUI.StatusView.ViewModel,
        userAvatarButtonDidPressed user: TwidereCore.UserRecord
    ) {
        Task {
            await DataSourceFacade.coordinateToProfileScene(
                provider: self,
                user: user
            )
        }   // end Task
    }
}

// MARK: - content
extension StatusViewTableViewCellDelegate where Self: DataSourceProvider & AuthContextProvider {
    func tableViewCell(_ cell: UITableViewCell, viewModel: StatusView.ViewModel, toggleContentDisplay isReveal: Bool) {
        Task { @MainActor in
            guard let status = viewModel.status?.asRecord else { return }

            try await DataSourceFacade.responseToToggleContentSensitiveAction(
                provider: self,
                target: .status,
                status: status
            )
        }   // end Task
    }
    
    func tableViewCell(_ cell: UITableViewCell, viewModel: StatusView.ViewModel, textViewDidSelectMeta meta: Meta?) {
        Task { @MainActor in
            guard let status = viewModel.status?.asRecord else { return }
            
            guard let meta = meta else {
                switch viewModel.kind {
                case .conversationRoot:
                    return
                default:
                    await DataSourceFacade.coordinateToStatusThreadScene(
                        provider: self,
                        kind: .status(status)
                    )
                    return
                }
            }
            
            await DataSourceFacade.responseToMetaText(
                provider: self,
                status: status,
                didSelectMeta: meta
            )
        }   // end Task
    }
}

// MARK: - media
extension StatusViewTableViewCellDelegate where Self: DataSourceProvider & AuthContextProvider & MediaPreviewableViewController {
    @MainActor
    func tableViewCell(
        _ cell: UITableViewCell,
        viewModel: StatusView.ViewModel,
        mediaViewModel: MediaView.ViewModel,
        action: MediaView.ViewModel.Action
    ) {
        assert(Thread.isMainThread)
        DataSourceFacade.responseToMediaViewAction(
            provider: self,
            statusViewModel: viewModel,
            mediaViewModel: mediaViewModel,
            action: action
        )
    }

    func tableViewCell(
        _ cell: UITableViewCell,
        viewModel: StatusView.ViewModel,
        toggleContentWarningOverlayDisplay isReveal: Bool
    ) {
        Task {
            guard let status = viewModel.status?.asRecord else { return }
            try await DataSourceFacade.responseToToggleMediaSensitiveAction(
                provider: self,
                target: .status,
                status: status
            )
        }   // end Task
    }
}

// MARK: - poll
extension StatusViewTableViewCellDelegate where Self: DataSourceProvider & AuthContextProvider {
    func tableViewCell(
        _ cell: UITableViewCell,
        viewModel: StatusView.ViewModel,
        pollVoteActionForViewModel pollViewModel: PollView.ViewModel
    ) {
        Task {
            guard let status = viewModel.status?.asRecord else { return }
            try await DataSourceFacade.responseToStatusPollVote(
                provider: self,
                status: status
            )
        }   // end Task
    }
    
    func tableViewCell(
        _ cell: UITableViewCell,
        viewModel: StatusView.ViewModel,
        pollUpdateIfNeedsForViewModel pollViewModel: PollView.ViewModel
    ) {
        Task {
            guard await pollViewModel.needsUpdate else {
                logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Poll] not needs update. skip")
                return
            }
            guard let status = viewModel.status?.asRecord else { return }
            try await DataSourceFacade.responseToStatusPollUpdate(
                provider: self,
                status: status
            )
        }   // end Task
    }

    
    func tableViewCell(
        _ cell: UITableViewCell,
        viewModel: StatusView.ViewModel,
        pollViewModel: PollView.ViewModel,
        pollOptionDidSelectForViewModel optionViewModel: PollOptionView.ViewModel
    ) {
        Task {
            guard let status = viewModel.status?.asRecord else { return }
            await DataSourceFacade.responseToStatusPollOption(
                provider: self,
                target: .status,
                status: status,
                didSelectRowAt: optionViewModel.index
            )
        }   // end Task
    }

//    func tableViewCell(_ cell: UITableViewCell, statusView: StatusView, pollTableView tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        Task {
//            let source = DataSourceItem.Source(tableViewCell: cell, indexPath: nil)
//            guard let item = await item(from: source) else {
//                assertionFailure()
//                return
//            }
//            guard let status = await item.status(in: self.context.managedObjectContext) else {
//                assertionFailure("only works for status data provider")
//                return
//            }
//            await DataSourceFacade.responseToStatusPollOption(
//                provider: self,
//                target: .status,
//                status: status,
//                didSelectRowAt: indexPath
//            )
//        }
//    }
//
//    func tableViewCell(_ cell: UITableViewCell, statusView: StatusView, pollVoteButtonDidPressed button: UIButton) {
//        Task {
//            let source = DataSourceItem.Source(tableViewCell: cell, indexPath: nil)
//            guard let item = await item(from: source) else {
//                assertionFailure()
//                return
//            }
//            guard let status = await item.status(in: self.context.managedObjectContext) else {
//                assertionFailure("only works for status data provider")
//                return
//            }
//            await DataSourceFacade.responseToStatusPollOption(
//                provider: self,
//                target: .status,
//                status: status,
//                voteButtonDidPressed: button
//            )
//        }
//    }
}

// MARK: - quote
extension StatusViewTableViewCellDelegate where Self: DataSourceProvider & AuthContextProvider {
    func tableViewCell(
        _ cell: UITableViewCell,
        viewModel: StatusView.ViewModel,
        quoteStatusViewDidPressed quoteViewModel: StatusView.ViewModel
    ) {
        guard let status = quoteViewModel.status?.asRecord else { return }
        Task {
            await DataSourceFacade.coordinateToStatusThreadScene(
                provider: self,
                kind: .status(status)
            )
        }   // end Task
    }
}

// MARK: - metric
extension StatusViewTableViewCellDelegate where Self: DataSourceProvider & AuthContextProvider {
    func tableViewCell(
        _ cell: UITableViewCell,
        viewModel: StatusView.ViewModel,
        statusMetricViewModel: StatusMetricView.ViewModel,
        statusMetricButtonDidPressed action: StatusMetricView.Action
    ) {
        Task {
            guard let status = viewModel.status?.asRecord else { return }
            // TODO:
        }   // end Task
    }
}

// MARK: - toolbar
extension StatusViewTableViewCellDelegate where Self: DataSourceProvider & AuthContextProvider {
    func tableViewCell(
        _ cell: UITableViewCell,
        viewModel: StatusView.ViewModel,
        statusToolbarViewModel: StatusToolbarView.ViewModel,
        statusToolbarButtonDidPressed action: StatusToolbarView.Action
    ) {
        Task {
            guard let status = viewModel.status?.asRecord else { return }
            await DataSourceFacade.responseToStatusToolbar(
                provider: self,
                viewModel: viewModel,
                statusToolbarViewModel: statusToolbarViewModel,
                status: status,
                action: action
            )
        }   // end Task
    }

//    func tableViewCell(
//        _ cell: UITableViewCell,
//        statusView: StatusView,
//        statusToolbar: StatusToolbar,
//        menuActionDidPressed action: StatusToolbar.MenuAction,
//        menuButton button: UIButton
//    ) {
//        Task {
//            let source = DataSourceItem.Source(tableViewCell: cell, indexPath: nil)
//            guard let item = await item(from: source) else {
//                assertionFailure()
//                return
//            }
//            guard let status = await item.status(in: self.context.managedObjectContext) else {
//                assertionFailure("only works for status data provider")
//                return
//            }
//
//            switch action {
//            case .saveMedia:
//                let mediaViewConfigurations = await statusView.viewModel.mediaViewConfigurations
//                let impactFeedbackGenerator = await UIImpactFeedbackGenerator(style: .light)
//                let notificationFeedbackGenerator = await UINotificationFeedbackGenerator()
//
//                do {
//                    await impactFeedbackGenerator.impactOccurred()
//                    for configuration in mediaViewConfigurations {
//                        guard let url = configuration.downloadURL.flatMap({ URL(string: $0) }) else { continue }
//                        try await context.photoLibraryService.save(source: .remote(url: url), resourceType: configuration.resourceType)
//                    }
//                    await context.photoLibraryService.presentSuccessNotification(title: L10n.Common.Alerts.PhotoSaved.title)
//                    await notificationFeedbackGenerator.notificationOccurred(.success)
//                } catch {
//                    await context.photoLibraryService.presentFailureNotification(
//                        error: error,
//                        title: L10n.Common.Alerts.PhotoSaveFail.title,
//                        message: L10n.Common.Alerts.PhotoSaveFail.message
//                    )
//                    await notificationFeedbackGenerator.notificationOccurred(.error)
//                }
//            case .translate:
//                try await DataSourceFacade.responseToStatusTranslate(
//                    provider: self,
//                    status: status
//                )
//            case .share:
//                await DataSourceFacade.responseToStatusShareAction(
//                    provider: self,
//                    status: status,
//                    button: button
//                )
//            case .remove:
//                try await DataSourceFacade.responseToRemoveStatusAction(
//                    provider: self,
//                    target: .status,
//                    status: status,
//                    authenticationContext: self.authContext.authenticationContext
//                )
//            #if DEBUG
//            case .copyID:
//                let _statusID: String? = await context.managedObjectContext.perform {
//                    guard let status = status.object(in: self.context.managedObjectContext) else { return nil }
//                    return status.id
//                }
//                if let statusID = _statusID {
//                    UIPasteboard.general.string = statusID
//                }
//            #endif
//            case .appearEvent:
//                let _record = await DataSourceFacade.status(
//                    managedObjectContext: context.managedObjectContext,
//                    status: status,
//                    target: .status
//                )
//                guard let record = _record else {
//                    return
//                }
//
//                await DataSourceFacade.recordStatusHistory(
//                    denpendency: self,
//                    status: record
//                )
//            }   // end switch
//        }   // end Task
//    }   // end func

}

extension StatusViewTableViewCellDelegate where Self: DataSourceProvider {
//    func tableViewCell(_ cell: UITableViewCell, statusView: StatusView, translateButtonDidPressed button: UIButton) {
//        Task {
//            let source = DataSourceItem.Source(tableViewCell: cell, indexPath: nil)
//            guard let item = await item(from: source) else {
//                return
//            }
//            guard let status = await item.status(in: self.context.managedObjectContext) else {
//                assertionFailure("only works for status data provider")
//                return
//            }
//
//            try await DataSourceFacade.responseToStatusTranslate(
//                provider: self,
//                status: status
//            )
//        }   // end Task
//    }
}

extension StatusViewTableViewCellDelegate where Self: DataSourceProvider {
    func tableViewCell(_ cell: UITableViewCell, viewModel: StatusView.ViewModel, viewHeightDidChange: Void) {
        // Manually update self resize
        UIView.performWithoutAnimation {
            cell.invalidateIntrinsicContentSize()
        }
    }
}

// MARK: - a11y
extension StatusViewTableViewCellDelegate where Self: DataSourceProvider & AuthContextProvider {

//    func tableViewCell(_ cell: UITableViewCell, statusView: StatusView, accessibilityActivate: Void) {
//        Task {
//            let source = DataSourceItem.Source(tableViewCell: cell, indexPath: nil)
//            guard let item = await item(from: source) else {
//                return
//            }
//            switch item {
//            case .status(let status):
//                await DataSourceFacade.coordinateToStatusThreadScene(
//                    provider: self,
//                    target: .repost,    // keep repost wrapper
//                    status: status
//                )
//            case .user(let user):
//                await DataSourceFacade.coordinateToProfileScene(
//                    provider: self,
//                    user: user
//                )
//            case .notification(let notification):
//                let managedObjectContext = self.context.managedObjectContext
//                guard let object = notification.object(in: managedObjectContext) else {
//                    assertionFailure()
//                    return
//                }
//                switch object {
//                case .mastodon(let notification):
//                    if let status = notification.status {
//                        await DataSourceFacade.coordinateToStatusThreadScene(
//                            provider: self,
//                            target: .repost,    // keep repost wrapper
//                            status: .mastodon(record: .init(objectID: status.objectID))
//                        )
//                    } else {
//                        await DataSourceFacade.coordinateToProfileScene(
//                            provider: self,
//                            user: .mastodon(record: .init(objectID: notification.account.objectID))
//                        )
//                    }
//                }
//            }
//        }   // end Task
//    }   // end func
    
}

