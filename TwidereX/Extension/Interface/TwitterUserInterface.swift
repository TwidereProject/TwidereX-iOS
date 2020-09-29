//
//  TwitterUserInterface.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-29.
//

import Foundation
import CoreDataStack
import TwitterAPI

public protocol TwitterUserInterface {
    typealias ID = String
    
    var idStr: String { get }
    
    var name: String? { get }
    var screenName: String? { get }
    var bioDescription: String? { get }
    var url: String? { get }
    var location: String? { get }
    var createdAt: Date? { get }
    
    var following: Bool? { get }
    var friendsCountInt: Int? { get }
    var followersCountInt: Int? { get }
    var listedCountInt: Int? { get }
    var favouritesCountInt: Int? { get }
    var statusesCountInt: Int? { get }
    var profileImageURLHTTPS: String? { get }
    var profileBannerURL: String? { get }

}

extension TwitterUserInterface {
    /// https://developer.twitter.com/en/docs/twitter-api/v1/accounts-and-users/user-profile-images-and-banners
    public func avatarImageURL(size: ProfileImageSize = .reasonablySmall) -> URL? {
        guard let imageURLString = profileImageURLHTTPS, var imageURL = URL(string: imageURLString) else { return nil }
        
        let pathExtension = imageURL.pathExtension
        imageURL.deletePathExtension()
        
        var imageIdentifier = imageURL.lastPathComponent
        imageURL.deleteLastPathComponent()
        for suffixedSize in ProfileImageSize.suffixedSizes {
            imageIdentifier.deleteSuffix("_\(suffixedSize.rawValue)")
        }
        
        switch size {
        case .original:
            imageURL.appendPathComponent(imageIdentifier)
        default:
            imageURL.appendPathComponent(imageIdentifier + "_" + size.rawValue)
        }
        
        imageURL.appendPathExtension(pathExtension)
        
        return imageURL
    }
}

extension Twitter.Entity.User: TwitterUserInterface {
    
    public var bioDescription: String? {
        return userDescription
    }
    
    public var friendsCountInt: Int? {
        return friendsCount
    }
    
    public var followersCountInt: Int? {
        return followersCount
    }
    
    public var listedCountInt: Int? {
        return listedCount
    }
    
    public var favouritesCountInt: Int? {
        return favouritesCount
    }
    
    public var statusesCountInt: Int? {
        return statusesCount
    }

}

extension TwitterUser: TwitterUserInterface { 
    
}

public enum ProfileImageSize: String {
    case original
    case reasonablySmall = "reasonably_small"       // 128 * 128
    case bigger                                     // 73 * 73
    case normal                                     // 48 * 48
    case mini                                       // 24 * 24
    
    static var suffixedSizes: [ProfileImageSize] {
        return [.reasonablySmall, .bigger, .normal, .mini]
    }
}


extension String {
    mutating func deleteSuffix(_ suffix: String) {
        guard hasSuffix(suffix) else { return }
        removeLast(suffix.count)
    }
}

