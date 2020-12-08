//
//  MediaPreviewPagingViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-6.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import Pageboy

protocol MediaPreviewPagingViewControllerDelegate: class {
    func profilePagingViewController(_ viewController: ProfilePagingViewController, didScrollToPostTimelineViewController postTimelineViewController: ScrollViewContainer, atIndex index: Int)
}


final class MediaPreviewPagingViewController: PageboyViewController {

}

