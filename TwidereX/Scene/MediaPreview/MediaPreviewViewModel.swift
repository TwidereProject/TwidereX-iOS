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
    weak var mediaPreviewImageViewControllerDelegate: MediaPreviewImageViewControllerDelegate?
    
    // output
    let viewControllers: [UIViewController]

    let avatarImageURL = CurrentValueSubject<URL?, Never>(nil)
    let isVerified = CurrentValueSubject<Bool, Never>(false)
    let name = CurrentValueSubject<String?, Never>(nil)
    let content = CurrentValueSubject<String?, Never>(nil)
    
    init(context: AppContext, root: Root) {
        self.context = context
        self.rootItem = .root(root)
        // setup viewControllers
        var _tweet: Tweet?
        var viewControllers: [UIViewController] = []
        let managedObjectContext = self.context.managedObjectContext
        managedObjectContext.performAndWait {
            let tweet = managedObjectContext.object(with: root.tweetObjectID) as! Tweet
            _tweet = tweet
            
            // configure viewControllers
            guard let media = tweet.media?.sorted(by: { $0.index.compare($1.index) == .orderedAscending }) else { return }
            
            for (mediaEntity, image) in zip(media, root.preloadThumbnailImages) {
                let thumbnail: UIImage? = image.flatMap { $0.size != CGSize(width: 1, height: 1) ? $0 : nil }
                switch mediaEntity.type {
                case "photo":
                    guard let url = mediaEntity.photoURL(sizeKind: .large)?.0 else { continue }
                    let mediaPreviewImageModel = MediaPreviewImageViewModel(url: url, thumbnail: thumbnail)
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
        
        // configure description view
        if let tweet = _tweet {
            self.avatarImageURL.value = (tweet.retweet ?? tweet).author.avatarImageURL()
            self.isVerified.value = (tweet.retweet ?? tweet).author.verified
            self.name.value = (tweet.retweet ?? tweet).author.name
            
            // remove line break
            let text = (tweet.retweet ?? tweet).text
                .replacingOccurrences(of: "\n", with: " ")
            self.content.value = text
        }
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
        if let mediaPreviewImageViewController = viewController as? MediaPreviewImageViewController {
            mediaPreviewImageViewController.delegate = mediaPreviewImageViewControllerDelegate
        }
        return viewController
    }
    
    func defaultPage(for pageboyViewController: PageboyViewController) -> PageboyViewController.Page? {
        guard case let .root(root) = rootItem else { return nil }
        return .at(index: root.initialIndex)
    }
    
}
