//
//  TimelineTableViewCellContextMenuConfiguration.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-30.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit

// note: use subclass configuration not custom NSCopying identifier due to identifier cause crash issue
final class TimelineTableViewCellContextMenuConfiguration: UIContextMenuConfiguration {
    
    var indexPath: IndexPath?
    var index: Int?
    
}
