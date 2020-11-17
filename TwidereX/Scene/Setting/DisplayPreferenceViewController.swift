//
//  DisplayPreferenceViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-17.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import SwiftUI
import Combine

final class DisplayPreferenceViewController: UIViewController, NeedsDependency {

    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
}

extension DisplayPreferenceViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
}
