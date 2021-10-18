//
//  Twitter+API+Timeline.swift
//  TwitterAPI
//
//  Created by Cirno MainasuK on 2020-9-3.
//

import Foundation
import Combine

extension Twitter.API.Timeline {

    static let mentionTimelineEndpointURL = Twitter.API.endpointURL.appendingPathComponent("statuses/mentions_timeline.json")
    
}

extension Twitter.API.Timeline {
//    public static func mentionTimeline(session: URLSession, authorization: Twitter.API.OAuth.Authorization, query: TimelineQuery) -> AnyPublisher<Twitter.Response.Content<[Twitter.Entity.Tweet]>, Error> {
//        let request = Twitter.API.request(url: mentionTimelineEndpointURL, httpMethod: "GET", authorization: authorization, queryItems: query.queryItems)
//        return session.dataTaskPublisher(for: request)
//            .tryMap { data, response in
//                let value = try Twitter.API.decode(type: [Twitter.Entity.Tweet].self, from: data, response: response)
//                return Twitter.Response.Content(value: value, response: response)
//            }
//            .eraseToAnyPublisher()
//    }
    
}
