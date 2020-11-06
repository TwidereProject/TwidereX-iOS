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

final class MediaPreviewViewModel: NSObject {
    
    // input
    let context: AppContext
    let rootItem: PreviewItem
    
    // output
    let viewControllers: [UIViewController]
    
    internal init(context: AppContext, root: Root) {
        self.context = context
        self.rootItem = .root(root)
        // setup viewControllers
        var viewControllers: [UIViewController] = []
        let managedObjectContext = self.context.managedObjectContext
        managedObjectContext.performAndWait {
            let tweet = managedObjectContext.object(with: root.tweetObjectID) as! Tweet
            guard let media = tweet.media?.sorted(by: { $0.index.compare($1.index) == .orderedAscending }) else { return }
            
            for (mediaEntity, image) in zip(media, root.preloadThumbnailImages) {
                switch mediaEntity.type {
                case "photo":
                    let mediaPreviewImageModel = MediaPreviewImageViewModel(thumbnail: image)
                    let mediaPreviewImageViewController = MediaPreviewImageViewController()
                    mediaPreviewImageViewController.viewModel = mediaPreviewImageModel
                    viewControllers.append(mediaPreviewImageViewController)
                default:
                    // TODO:
                    continue
                }
            }
        }
        self.viewControllers = viewControllers
        super.init()
    }
    
}

extension MediaPreviewViewModel {
    enum PreviewItem {
        case root(Root)
    }
    
    struct Root {
        let tweetObjectID: NSManagedObjectID
        let initialIndex: Int
        let preloadThumbnailImages: [UIImage?]
    }
}

// MARK: - PageboyViewControllerDataSource
extension MediaPreviewViewModel: PageboyViewControllerDataSource {
    
    func numberOfViewControllers(in pageboyViewController: PageboyViewController) -> Int {
        return viewControllers.count
    }
    
    func viewController(for pageboyViewController: PageboyViewController, at index: PageboyViewController.PageIndex) -> UIViewController? {
        let viewController = viewControllers[index]
        return viewController
    }
    
    func defaultPage(for pageboyViewController: PageboyViewController) -> PageboyViewController.Page? {
        guard case let .root(root) = rootItem else { return nil }
        return .at(index: root.initialIndex)
    }
    
}
