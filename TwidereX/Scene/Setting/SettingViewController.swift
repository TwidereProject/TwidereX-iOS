//
//  SettingViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-10.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import SwiftUI
import Combine

final class SettingViewController: UIViewController, NeedsDependency {
        
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }

    var disposeBag = Set<AnyCancellable>()
    let settingListView = SettingListView()
}

extension SettingViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Settings"
        
        let hostingViewController = UIHostingController(rootView: settingListView.environmentObject(context))
        addChild(hostingViewController)
        hostingViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingViewController.view)
        NSLayoutConstraint.activate([
            hostingViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        context.viewStateStore.settingView.presentSettingListEntryPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] entry in
                guard let self = self else { return }
                let alertController = UIAlertController(title: nil, message: "Not implement yet", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alertController.addAction(okAction)
                self.present(alertController, animated: true, completion: nil)
                
                switch entry.type {
                case .appearance:
                    break
                case .display:
                    break
                case .layout:
                    break
                case .webBrowser:
                    break
                case .about:
                    break
                }
            }
            .store(in: &disposeBag)
    }
    
}

//extension SettingViewController {
//    enum Entry {
//        case appearance
//        case display
//        case layout
//        case webBrowser
//        case about
//        
//        var title: String {
//            switch self {
//            case .messages:     return "Messages"
//            case .likes:        return "Likes"
//            case .lists:        return "Lists"
//            case .trends:       return "Trends"
//            case .drafts:       return "Drafts"
//            case .settings:     return "Settings"
//            }
//        }
//        
//        var image: UIImage {
//            switch self {
//            case .messages:     return Asset.Communication.mail.image.withRenderingMode(.alwaysTemplate)
//            case .likes:        return Asset.Health.heart.image.withRenderingMode(.alwaysTemplate)
//            case .lists:        return Asset.ObjectTools.bookmarks.image.withRenderingMode(.alwaysTemplate)
//            case .trends:       return Asset.Arrows.trendingUp.image.withRenderingMode(.alwaysTemplate)
//            case .drafts:       return Asset.ObjectTools.note.image.withRenderingMode(.alwaysTemplate)
//            case .settings:     return Asset.Editing.sliderHorizontal3.image.withRenderingMode(.alwaysTemplate)
//            }
//        }
//    }
//}


