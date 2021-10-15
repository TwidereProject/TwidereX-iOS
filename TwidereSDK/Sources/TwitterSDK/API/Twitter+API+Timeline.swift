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
//    @available(*, deprecated, message: "")
//    public static func homeTimeline(session: URLSession, authorization: Twitter.API.OAuth.Authorization, query: TimelineQuery) -> AnyPublisher<Twitter.Response.Content<[Twitter.Entity.Tweet]>, Error> {
//        let request = Twitter.API.request(url: homeTimelineEndpointURL, httpMethod: "GET", authorization: authorization, queryItems: query.queryItems)
//        return session.dataTaskPublisher(for: request)
//            .tryMap { data, response in
//                do {
//                    let value = try Twitter.API.decode(type: [Twitter.Entity.Tweet].self, from: data, response: response)
//                    return Twitter.Response.Content(value: value, response: response)
//                } catch {
//                    debugPrint(error)
//                    throw error
//                }
//            }
//            .eraseToAnyPublisher()
//    }
    
//    public static func mentionTimeline(session: URLSession, authorization: Twitter.API.OAuth.Authorization, query: TimelineQuery) -> AnyPublisher<Twitter.Response.Content<[Twitter.Entity.Tweet]>, Error> {
//        let request = Twitter.API.request(url: mentionTimelineEndpointURL, httpMethod: "GET", authorization: authorization, queryItems: query.queryItems)
//        return session.dataTaskPublisher(for: request)
//            .tryMap { data, response in
//                let value = try Twitter.API.decode(type: [Twitter.Entity.Tweet].self, from: data, response: response)
//                return Twitter.Response.Content(value: value, response: response)
//            }
//            .eraseToAnyPublisher()
//    }
    
//    public static func userTimeline(session: URLSession, authorization: Twitter.API.OAuth.Authorization, query: TimelineQuery) -> AnyPublisher<Twitter.Response.Content<[Twitter.Entity.Tweet]>, Error> {
//        assert(query.userID != nil && query.userID != "")
//        
//        var components = URLComponents(string: userTimelineEndpointURL.absoluteString)!
//        components.queryItems = query.queryItems
//        let requestURL = components.url!
//        var request = URLRequest(
//            url: requestURL,
//            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
//            timeoutInterval: Twitter.API.timeoutInterval
//        )
//        request.setValue(
//            authorization.authorizationHeader(requestURL: requestURL, httpMethod: "GET"),
//            forHTTPHeaderField: Twitter.API.OAuth.authorizationField
//        )
//        
//        return session.dataTaskPublisher(for: request)
//            .tryMap { data, response in
//                do {
//                    let value = try Twitter.API.decode(type: [Twitter.Entity.Tweet].self, from: data, response: response)
//                    return Twitter.Response.Content(value: value, response: response)
//                } catch {
//                    debugPrint(error)
//                    throw error
//                }
//            }
//            .eraseToAnyPublisher()
//    }
    
}
