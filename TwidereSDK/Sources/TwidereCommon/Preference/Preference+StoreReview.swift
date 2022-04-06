//
//  Preference+StoreReview.swift
//  
//
//  Created by MainasuK on 2022-4-6.
//

import Foundation

extension UserDefaults {
    
    @objc public dynamic var storeReviewInteractTriggerCount: Int {
        get {
            return integer(forKey: #function)
        }
        set { self[#function] = newValue }
    }
    
    @objc public dynamic var lastVersionPromptedForReview: String? {
        get {
            return string(forKey: #function)
        }
        set { self[#function] = newValue }
    }
    
}
