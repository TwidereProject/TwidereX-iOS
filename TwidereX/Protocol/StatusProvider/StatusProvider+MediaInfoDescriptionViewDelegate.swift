//
//  StatusProvider+MediaInfoDescriptionViewDelegate.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-16.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack
import ActiveLabel
import TwitterAPI

extension MediaInfoDescriptionViewDelegate where Self: StatusProvider {
    
    func mediaInfoDescriptionView(_ mediaInfoDescriptionView: MediaInfoDescriptionView, avatarImageViewDidPressed imageView: UIImageView) {
        StatusProviderFacade.coordinateToStatusAuthorProfileScene(for: .tweet, provider: self)
    }
    
    func mediaInfoDescriptionView(_ mediaInfoDescriptionView: MediaInfoDescriptionView, activeLabelDidPressed activeLabel: ActiveLabel) {
        StatusProviderFacade.coordinateToStatusConversationScene(for: .tweet, provider: self)
    }
    
}
