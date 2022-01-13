//
//  HomeTimelineViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-1.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import SwiftUI
import AVKit
import Combine
import CoreData
import CoreDataStack
import GameplayKit
import TwitterSDK
import Floaty
import AlamofireImage
import AppShared
import TwidereUI
import TwidereComposeUI

final class HomeTimelineViewController: TimelineViewController {

    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s:", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension HomeTimelineViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        #if DEBUG
        navigationItem.rightBarButtonItem = debugActionBarButtonItem
        #endif
    }
    
}
