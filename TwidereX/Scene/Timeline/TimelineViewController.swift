//
//  TimelineViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-1.
//

import UIKit

final class TimelineViewController: UIViewController, NeedsDependency {
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
}

extension TimelineViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Timeline"
        view.backgroundColor = .systemBackground
    }
}
