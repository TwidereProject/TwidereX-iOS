//
//  UserDefaults.swift
//  
//
//  Created by MainasuK on 2021/11/17.
//

import UIKit

extension UserDefaults {
    public static let shared = UserDefaults(suiteName: AppCommon.groupID)!
}

extension UserDefaults {
    
    public subscript<T: RawRepresentable>(key: String) -> T? {
        get {
            if let rawValue = value(forKey: key) as? T.RawValue {
                return T(rawValue: rawValue)
            }
            return nil
        }
        set { set(newValue?.rawValue, forKey: key) }
    }
    
    public subscript<T>(key: String) -> T? {
        get { return value(forKey: key) as? T }
        set { set(newValue, forKey: key) }
    }
    
}
