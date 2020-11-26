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

    // description view
    let avatarImageURL = CurrentValueSubject<URL?, Never>(nil)
    let isVerified = CurrentValueSubject<Bool, Never>(false)
    let name = CurrentValueSubject<String?, Never>(nil)
    let content = CurrentValueSubject<String?, Never>(nil)
    
    init(context: AppContext, meta: TweetImagePreviewMeta) {
        self.context = context
        self.rootItem = .tweet(meta)
        // setup viewControllers
        var _tweet: Tweet?
        var viewControllers: [UIViewController] = []
        let managedObjectContext = self.context.managedObjectContext
        managedObjectContext.performAndWait {
            let tweet = managedObjectContext.object(with: meta.tweetObjectID) as! Tweet
            _tweet = tweet
            
            // configure viewControllers
            guard let media = tweet.media?.sorted(by: { $0.index.compare($1.index) == .orderedAscending }) else { return }
            
            for (mediaEntity, image) in zip(media, meta.preloadThumbnailImages) {
                let thumbnail: UIImage? = image.flatMap { $0.size != CGSize(width: 1, height: 1) ? $0 : nil }
                switch mediaEntity.type {
                case "photo":
                    guard let url = mediaEntity.photoURL(sizeKind: .original)?.0 else { continue }
                    let meta = MediaPreviewImageViewModel.TweetImagePreviewMeta(url: url, thumbnail: thumbnail)
                    let mediaPreviewImageModel = MediaPreviewImageViewModel(meta: meta)
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
            let text = (tweet.retweet ?? tweet).displayText
                .replacingOccurrences(of: "\n", with: " ")
            self.content.value = text
        }
    }
    
    init(context: AppContext, meta: LocalImagePreviewMeta) {
        self.context = context
        self.rootItem = .local(meta)
        // setup viewControllers
        let meta = MediaPreviewImageViewModel.LocalImagePreviewMeta(image: meta.image)
        let mediaPreviewImageModel = MediaPreviewImageViewModel(meta: meta)
        let mediaPreviewImageViewController = MediaPreviewImageViewController()
        mediaPreviewImageViewController.viewModel = mediaPreviewImageModel
        self.viewControllers = [mediaPreviewImageViewController]
        super.init()
    }
    
}

extension MediaPreviewViewModel {
    
    enum PreviewItem {
        case tweet(TweetImagePreviewMeta)
        case local(LocalImagePreviewMeta)
    }
    
    struct TweetImagePreviewMeta {
        let tweetObjectID: NSManagedObjectID
        let initialIndex: Int
        let preloadThumbnailImages: [UIImage?]
    }
    
    struct LocalImagePreviewMeta {
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
        guard case let .tweet(root) = rootItem else { return nil }
        return .at(index: root.initialIndex)
    }
    
}
