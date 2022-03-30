//
//  IntentHandler.swift
//  TwidereXIntent
//
//  Created by MainasuK on 2022-3-30.
//  Copyright © 2022 Twidere. All rights reserved.
//

import Intents


class IntentHandler: INExtension {
    
    override func handler(for intent: INIntent) -> Any {
        // This is the default implementation.  If you want different objects to handle different intents,
        // you can override this and return the handler you want for that particular intent.
        switch intent {
        case is SwitchAccountIntent:
            return SwitchAccountIntentHandler()
        default:
            return self
        }
    }
    
}
