//
//  StatusProvider+StatusActionToolbarDelegate.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-13.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack
import TwitterAPI

extension StatusActionToolbarDelegate where Self: StatusProvider {
    
    func statusActionToolbar(_ toolbar: StatusActionToolbar, replayButtonDidPressed sender: UIButton) {
        StatusProviderFacade.coordinateToStatusReplyScene(provider: self)
    }
    
    func statusActionToolbar(_ toolbar: StatusActionToolbar, retweetButtonDidPressed sender: UIButton) {
        StatusProviderFacade.responseToStatusRetweetAction(provider: self)
    }
    
    func statusActionToolbar(_ toolbar: StatusActionToolbar, favoriteButtonDidPressed sender: UIButton) {
        StatusProviderFacade.responseToStatusLikeAction(provider: self)
    }
    
    func statusActionToolbar(_ toolbar: StatusActionToolbar, shareButtonDidPressed sender: UIButton) {
        StatusProviderFacade.responseToStatusMenuAction(provider: self, sender: sender)
    }
    
}
