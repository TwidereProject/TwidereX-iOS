//
//  TrendObject.swift
//  
//
//  Created by MainasuK on 2021-12-28.
//

import Foundation
import TwitterSDK

public enum TrendObject: Hashable {
    case twitter(trend: Twitter.Entity.Trend)
}
