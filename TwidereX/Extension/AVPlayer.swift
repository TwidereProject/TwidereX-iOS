//
//  AVPlayer.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-17.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import AVKit

// MARK: - CustomDebugStringConvertible
extension AVPlayer.TimeControlStatus: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .paused:                           return "paused"
        case .waitingToPlayAtSpecifiedRate:     return "waitingToPlayAtSpecifiedRate"
        case .playing:                          return "playing"
        }
    }
}
