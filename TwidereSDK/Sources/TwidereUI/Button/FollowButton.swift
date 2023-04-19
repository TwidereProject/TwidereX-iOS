//
//  FollowButton.swift
//  
//
//  Created by MainasuK on 2023/4/13.
//

import SwiftUI
import CoreDataStack

public struct FollowButton: View {
    
    @ObservedObject public var viewModel: ViewModel
    
    public var body: some View {
        Button {
            
        } label: {
            Text("Follow")
        }
        .buttonStyle(.borderless)
    }
}

extension FollowButton {
    public class ViewModel: ObservableObject {
        
        // input
        public let user: UserObject
        public let authContext: AuthContext
        
        // output
        
        
        public init(
            user: UserObject,
            authContext: AuthContext
        ) {
            self.user = user
            self.authContext = authContext
            // end init
        }

    }
}

extension FollowButton.ViewModel {
    public convenience init(
        user: TwitterUser,
        authContext: AuthContext
    ) {
        self.init(
            user: .twitter(object: user),
            authContext: authContext
        )
        // end init
    }
    
    public convenience init(
        user: MastodonUser,
        authContext: AuthContext
    ) {
        self.init(
            user: .mastodon(object: user),
            authContext: authContext
        )
        // end init
    }
}
