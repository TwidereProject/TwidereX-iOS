//
//  TabBarPagerDataSource.swift
//
//
//  Created by Cirno MainasuK on 2021-10-13.
//

import UIKit

public protocol TabBarPagerDataSource: AnyObject {
    func headerViewController() -> UIViewController & TabBarPagerHeader
    func pageViewController() -> UIViewController & TabBarPageViewController
}
