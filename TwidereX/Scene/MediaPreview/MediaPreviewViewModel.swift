//
//  MediaPreviewViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-5.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import Combine
import CoreData
import CoreDataStack
import Pageboy
import TwidereCore
import TwidereUI

final class MediaPreviewViewModel: NSObject {
    
    var observations = Set<NSKeyValueObservation>()
    
    weak var mediaPreviewImageViewControllerDelegate: MediaPreviewImageViewControllerDelegate?

    // input
    let context: AppContext
    let authContext: AuthContext
    let item: Item
    let transitionItem: MediaPreviewTransitionItem
    
    @Published var currentPage: Int
    
    // output
    var status: StatusObject?
    let viewControllers: [UIViewController]
    
    init(
        context: AppContext,
        authContext: AuthContext,
        item: Item,
        transitionItem: MediaPreviewTransitionItem
    ) {
        self.context = context
        self.authContext = authContext
        self.item = item
        self.currentPage = {
            switch item {
            case .statusAttachment(let previewContext):
                return previewContext.initialIndex
            case .image:
                return 0
            }
        }()
        self.transitionItem = transitionItem
        // setup output
        self.status = {
            switch item {
            case .statusAttachment(let previewContext):
                let status = previewContext.status.object(in: context.managedObjectContext)
                return status
            case .image:
                return nil
            }
        }()
        self.viewControllers = {
            var viewControllers: [UIViewController] = []
            switch item {
            case .statusAttachment(let previewContext):
                for (i, attachment) in previewContext.attachments.enumerated() {
                    switch attachment.kind {
                    case .image:
                        let viewController = MediaPreviewImageViewController()
                        viewController.viewModel = MediaPreviewImageViewModel(
                            context: context,
                            item: .remote(.init(
                                assetURL: attachment.assetURL,
                                thumbnail: previewContext.thumbnail(at: i)
                            ))
                        )
                        viewControllers.append(viewController)
                    case .video:
                        let viewController = MediaPreviewVideoViewController()
                        viewController.viewModel = MediaPreviewVideoViewModel(
                            context: context,
                            item: .video(.init(
                                assetURL: attachment.assetURL,
                                previewURL: attachment.previewURL
                            ))
                        )
                        viewControllers.append(viewController)
                    case .gif:
                        let viewController = MediaPreviewVideoViewController()
                        viewController.viewModel = MediaPreviewVideoViewModel(
                            context: context,
                            item: .gif(.init(
                                assetURL: attachment.assetURL,
                                previewURL: attachment.previewURL
                            ))
                        )
                        viewControllers.append(viewController)
                    case .audio:
                        viewControllers.append(UIViewController())
                    }
                }
            case .image(let previewContext):
                let viewController = MediaPreviewImageViewController()
                viewController.viewModel = MediaPreviewImageViewModel(
                    context: context,
                    item: .local(.init(image: previewContext.image))
                )
                viewControllers.append(viewController)
            }   // end switch
            return viewControllers
        }()
        super.init()
    }
    
//    init(context: AppContext, meta: LocalImagePreviewMeta) {
//        self.context = context
//        self.rootItem = .local(meta)
//        // setup viewControllers
//        let meta = MediaPreviewImageViewModel.LocalImagePreviewMeta(image: meta.image)
//        let mediaPreviewImageModel = MediaPreviewImageViewModel(meta: meta)
//        let mediaPreviewImageViewController = MediaPreviewImageViewController()
//        mediaPreviewImageViewController.viewModel = mediaPreviewImageModel
//        self.viewControllers = [mediaPreviewImageViewController]
//        super.init()
//    }
    
}

extension MediaPreviewViewModel {
    
    enum Item {
        case statusAttachment(StatusAttachmentPreviewContext)
        case image(ImagePreviewContext)
    }

    struct StatusAttachmentPreviewContext {
        let status: StatusRecord
        let attachments: [AttachmentObject]
        let initialIndex: Int
        let preloadThumbnails: [UIImage?]
        
        func thumbnail(at index: Int) -> UIImage? {
            guard index < preloadThumbnails.count else { return nil }
            return preloadThumbnails[index]
        }
    }

    struct ImagePreviewContext {
        let image: UIImage
    }
        
}

// MARK: - PageboyViewControllerDataSource
extension MediaPreviewViewModel: PageboyViewControllerDataSource {
    
    func numberOfViewControllers(in pageboyViewController: PageboyViewController) -> Int {
        return viewControllers.count
    }

    func viewController(for pageboyViewController: PageboyViewController, at index: PageboyViewController.PageIndex) -> UIViewController? {
        let viewController = viewControllers[index]
        if let mediaPreviewImageViewController = viewController as? MediaPreviewImageViewController {
            mediaPreviewImageViewController.delegate = mediaPreviewImageViewControllerDelegate
        }
        return viewController
    }

    func defaultPage(for pageboyViewController: PageboyViewController) -> PageboyViewController.Page? {
        switch item {
        case .statusAttachment(let previewContext):
            return .at(index: previewContext.initialIndex)
        case .image:
            return .first
        }
    }
    
}
