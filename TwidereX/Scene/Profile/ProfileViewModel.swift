//
//  ProfileViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-27.
//

import Foundation
import Combine
import CoreDataStack

final class ProfileViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let twitterUser: CurrentValueSubject<TwitterUser?, Never>
    
    // output
    let bannerImageURL: CurrentValueSubject<URL?, Never>
    let avatarImageURL: CurrentValueSubject<URL?, Never>
    let name: CurrentValueSubject<String?, Never>
    let username: CurrentValueSubject<String?, Never>
    let isFolling: CurrentValueSubject<Bool?, Never>
    let bioDescription: CurrentValueSubject<String?, Never>
    let url: CurrentValueSubject<String?, Never>
    let location: CurrentValueSubject<String?, Never>
    let friendsCount: CurrentValueSubject<Int?, Never>
    let followersCount: CurrentValueSubject<Int?, Never>
    let listedCount: CurrentValueSubject<Int?, Never>
    
    init(twitterUser: TwitterUser) {
        self.twitterUser = CurrentValueSubject(twitterUser)
        self.bannerImageURL = CurrentValueSubject(twitterUser.profileBannerURL.flatMap { URL(string: $0) })
        self.avatarImageURL = CurrentValueSubject(twitterUser.avatarImageURL(size: .original))
        self.name = CurrentValueSubject(twitterUser.name)
        self.username = CurrentValueSubject(twitterUser.screenName)
        self.isFolling = CurrentValueSubject(twitterUser.following)
        self.bioDescription = CurrentValueSubject(twitterUser.bioDescription)
        self.url = CurrentValueSubject(twitterUser.url)
        self.location = CurrentValueSubject(twitterUser.location)
        self.friendsCount = CurrentValueSubject(twitterUser.friendsCount.flatMap { $0.intValue })
        self.followersCount = CurrentValueSubject(twitterUser.followersCount.flatMap { $0.intValue })
        self.listedCount = CurrentValueSubject(twitterUser.listedCount.flatMap { $0.intValue })
    }
    
    init(twitterUserIDStr: String) {
        self.twitterUser = CurrentValueSubject(nil)
        self.bannerImageURL = CurrentValueSubject(nil)
        self.avatarImageURL = CurrentValueSubject(nil)
        self.name = CurrentValueSubject(nil)
        self.username = CurrentValueSubject(nil)
        self.isFolling = CurrentValueSubject(nil)
        self.bioDescription = CurrentValueSubject(nil)
        self.url = CurrentValueSubject(nil)
        self.location = CurrentValueSubject(nil)
        self.friendsCount = CurrentValueSubject(nil)
        self.followersCount = CurrentValueSubject(nil)
        self.listedCount = CurrentValueSubject(nil)
    }
    
}
