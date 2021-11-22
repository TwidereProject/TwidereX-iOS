//
//  NumberMetricFormatter.swift
//  NumberMetricFormatter
//
//  Copyright © 2021 Mastodon. All rights reserved.
//

import Foundation

public final class NumberMetricFormatter: Formatter {
    
    public func string(from number: Int) -> String? {
        let isPositive = number >= 0
        let symbol = isPositive ? "" : "-"
        
        let numberFormatter = NumberFormatter()
        
        let value = abs(number)
        let metric: String
        
        switch value {
        case 0..<1000:          // 0 ~ 1K
            metric = String(value)
        case 1000..<10000:      // 1K ~ 10K
            numberFormatter.maximumFractionDigits = 1
            let string = numberFormatter.string(from: NSNumber(value: Double(value) / 1000.0)) ?? String(value / 1000)
            metric = string + "K"
        case 10000..<1000000:    // 10K ~ 1M
            numberFormatter.maximumFractionDigits = 0
            let string = numberFormatter.string(from: NSNumber(value: Double(value) / 1000.0)) ?? String(value / 1000)
            metric = string + "K"
        default:
            numberFormatter.maximumFractionDigits = 0
            let string = numberFormatter.string(from: NSNumber(value: Double(value) / 1000000.0)) ?? String(value / 1000000)
            metric = string + "M"
        }
        
        return symbol + metric
    }
    
}
