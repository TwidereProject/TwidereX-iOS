//
//  TabBarPageViewDelegate.swift
//  
//
//  Created by Cirno MainasuK on 2021-10-13.
//

import Foundation
import Tabman
import Pageboy

public typealias PageIndex = PageboyViewController.PageIndex

public protocol TabBarPageViewDelegate: AnyObject {
    func pageViewController(_ pageViewController: TabmanViewController, tabBarPage page: TabBarPage, at pageIndex: PageIndex)
}
