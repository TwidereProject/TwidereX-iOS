//
//  StatusProvider+ActionToolbarContainerDelegate.swift
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

extension ActionToolbarContainerDelegate where Self: StatusProvider {
    
    func actionToolbarContainer(_ actionToolbarContainer: ActionToolbarContainer, replayButtonDidPressed sender: UIButton) {
        StatusProviderFacade.coordinateToStatusReplyScene(provider: self)
    }
    
    func actionToolbarContainer(_ actionToolbarContainer: ActionToolbarContainer, retweetButtonDidPressed sender: UIButton) {
        StatusProviderFacade.responseToStatusRetweetAction(provider: self)
    }
    
    func actionToolbarContainer(_ actionToolbarContainer: ActionToolbarContainer, likeButtonDidPressed sender: UIButton) {
        StatusProviderFacade.responseToStatusLikeAction(provider: self)
    }
    
    func actionToolbarContainer(_ actionToolbarContainer: ActionToolbarContainer, menuButtonDidPressed sender: UIButton) {
        StatusProviderFacade.responseToStatusMenuAction(provider: self, sender: sender)
    }
    
}
