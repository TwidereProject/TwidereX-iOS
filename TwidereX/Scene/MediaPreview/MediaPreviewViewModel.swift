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
    
    @Published public var viewLayoutFrame = ViewLayoutFrame()
    
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
            case .statusMedia(let previewContext):
                return previewContext.initialIndex
            case .image:
                return 0
            }
        }()
        self.transitionItem = transitionItem
        // setup output
        self.status = {
            switch item {
            case .statusMedia(let previewContext):
                let status = previewContext.status.object(in: context.managedObjectContext)
                return status
            case .image:
                return nil
            }
        }()
        self.viewControllers = {
            var viewControllers: [UIViewController] = []
            switch item {
            case .statusMedia(let previewContext):
                for (i, mediaViewModel) in previewContext.mediaViewModels.enumerated() {
                    switch mediaViewModel.mediaKind {
                    case .photo:
                        let viewController = MediaPreviewImageViewController()
                        viewController.viewModel = MediaPreviewImageViewModel(
                            context: context,
                            item: .remote(.init(
                                assetURL: mediaViewModel.assetURL,
                                thumbnail: previewContext.thumbnail(at: i)
                            ))
                        )
                        viewControllers.append(viewController)
                    case .video:
                        let viewController = MediaPreviewVideoViewController()
                        viewController.viewModel = MediaPreviewVideoViewModel(
                            context: context,
                            item: .video(.init(
                                assetURL: mediaViewModel.assetURL,
                                previewURL: mediaViewModel.previewURL
                            ))
                        )
                        viewControllers.append(viewController)
                    case .animatedGIF:
                        let viewController = MediaPreviewVideoViewController()
                        viewController.viewModel = MediaPreviewVideoViewModel(
                            context: context,
                            item: .gif(.init(
                                assetURL: mediaViewModel.assetURL,
                                previewURL: mediaViewModel.previewURL
                            ))
                        )
                        viewControllers.append(viewController)
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
        case statusMedia(StatusMediaPreviewContext)
        case image(ImagePreviewContext)
    }

    struct StatusMediaPreviewContext {
        let status: StatusRecord
        let mediaViewModels: [MediaView.ViewModel]
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
        case .statusMedia(let previewContext):
            return .at(index: previewContext.initialIndex)
        case .image:
            return .first
        }
    }
    
}
