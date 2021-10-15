//
//  TabBarPageViewDelegate.swift
//  
//
//  Created by Cirno MainasuK on 2021-10-13.
//

import Foundation

public protocol TabBarPageViewDelegate: AnyObject {
    func pageViewController(_ pageViewController: TabBarPageViewController, didPresentingTabBarPage page: TabBarPage, at index: Int)
}
