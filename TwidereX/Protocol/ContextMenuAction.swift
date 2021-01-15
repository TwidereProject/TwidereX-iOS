//
//  ContextMenuAction.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021/1/13.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit

protocol ContextMenuAction {
    
    var title: String { get }
    var discoverabilityTitle: String? { get }
    var image: UIImage? { get }
    
    
    var attributes: UIMenuElement.Attributes { get }
    var state: UIMenuElement.State { get }
    var style: UIAlertAction.Style { get }
    
    var handler: () -> Void { get }
    
    var menuElement: UIMenuElement? { get }
    var alertAction: UIAlertAction { get }
    
}
