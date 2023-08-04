//
//  DrawerSidebarViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-9.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import Combine
import Meta
import TwidereCore

final class DrawerSidebarViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let authContext: AuthContext
    
    // output
    var sidebarDiffableDataSource: UICollectionViewDiffableDataSource<SidebarSection, SidebarItem>?
    var settingDiffableDataSource: UICollectionViewDiffableDataSource<SidebarSection, SidebarItem>?
    
    init(
        context: AppContext,
        authContext: AuthContext
    ) {
        self.context = context
        self.authContext = authContext
        // end init
    }
    
}
