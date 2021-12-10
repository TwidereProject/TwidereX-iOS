//
//  Date.swift
//  
//
//  Created by MainasuK on 2021-12-10.
//

import Foundation
import TwidereLocalization

extension Date {
    public var localizedTimeLeft: String? {
        let date = Date()
        let earlierDate = date < self ? date : self
        let latestDate = earlierDate == date ? self : date
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: earlierDate, to: latestDate)
        
        if components.year! > 0 {
            return L10n.Date.Year.left(components.year!)
        } else if components.month! > 0 {
            return L10n.Date.Month.left(components.month!)
        } else if components.day! > 0 {
            return L10n.Date.Day.left(components.day!)
        } else if components.hour! > 0 {
            return L10n.Date.Hour.left(components.hour!)
        } else if components.minute! > 0 {
            return L10n.Date.Minute.left(components.minute!)
        } else if components.second! > 0 {
            return L10n.Date.Year.left(components.second!)
        } else {
            return nil
        }
    }
}
