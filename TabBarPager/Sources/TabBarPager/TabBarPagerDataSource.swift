//
//  TabBarPagerDataSource.swift
//
//
//  Created by Cirno MainasuK on 2021-10-13.
//

import UIKit
import Tabman

public protocol TabBarPagerDataSource: AnyObject {
    func headerViewController() -> UIViewController & TabBarPagerHeader
    func pageViewController() -> TabmanViewController & TabBarPageViewController
}
