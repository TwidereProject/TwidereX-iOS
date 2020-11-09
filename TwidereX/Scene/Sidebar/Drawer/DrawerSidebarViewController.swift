//
//  DrawerSidebarViewController.swift
//  TwidereX
//
//  Created by DTK on 2020-11-9.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import Combine

final class DrawerSidebarViewController: UIViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }

    var disposeBag = Set<AnyCancellable>()

    let avatarButton = UIButton.avatarButton
    
    
}
