//
//  Twitter+RetweetedStatus.swift
//  TwitterAPI
//
//  Created by Cirno MainasuK on 2020-9-3.
//

import Foundation

extension Twitter.Entity {
    /// https://developer.twitter.com/en/docs/twitter-api/v1/data-dictionary/overview/intro-to-tweet-json#retweet
    public class RetweetedStatus: Twitter.Entity.Tweet { }
}
