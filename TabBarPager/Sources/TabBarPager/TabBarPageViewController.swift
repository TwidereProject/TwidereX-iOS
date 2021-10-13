//
//  TabBarPageViewController.swift
//  
//
//  Created by Cirno MainasuK on 2021-10-13.
//

import UIKit

public protocol TabBarPageViewController: AnyObject {
    var tabBarPageViewDelegate: TabBarPageViewDelegate? { get set }
}
