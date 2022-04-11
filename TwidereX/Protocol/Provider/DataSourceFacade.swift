//
//  DataSourceFacade.swift
//  DataSourceFacade
//
//  Created by Cirno MainasuK on 2021-8-30.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import Foundation
import CoreData
import CoreDataStack

enum DataSourceFacade {
    static let logger = Logger(subsystem: "DataSourceFacade", category: "Facade")
    
    enum StatusTarget {
        case status         // remove repost wrapper
        case repost         // keep repost wrapper
        case quote          // remove repost wrapper then locate to quote
    }
}

