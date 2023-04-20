//
//  Twitter+API+V2+Status+Timeline.swift
//  
//
//  Created by MainasuK on 2023/3/27.
//

import Foundation

extension Twitter.API.V2.Status {
    public enum Timeline { }
}

extension Twitter.API.V2.Status.Timeline {
    private static func conversationEndpointURL(statusID: Twitter.Entity.V2.Tweet.ID) -> URL {
        return Twitter.API.endpointV2URL
            .appendingPathComponent("timeline")
            .appendingPathComponent("conversation")
            .appendingPathComponent(statusID)
            .appendingPathExtension("json")
    }
    
    public static func conversation(
        session: URLSession,
        statusID: Twitter.Entity.V2.Tweet.ID,
        query: TimelineQuery,
        authorization: Twitter.API.Guest.GuestAuthorization
    ) async throws -> Twitter.Response.Content<Twitter.API.V2.Status.Timeline.ConversationContent> {
        let request = Twitter.API.request(
            url: conversationEndpointURL(statusID: statusID),
            method: .GET,
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Twitter.API.decode(type: Twitter.API.V2.Status.Timeline.ConversationContent.self, from: data, response: response)
        return Twitter.Response.Content(value: value, response: response)
    }

    public struct TimelineQuery: Query {
        public let cursor: String?
        
        public init(cursor: String?) {
            self.cursor = cursor
        }
        
        public var queryItems: [URLQueryItem]? { nil }
        public var encodedQueryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            cursor.flatMap { items.append(URLQueryItem(name: "cursor", value: $0.urlEncoded)) }
            guard !items.isEmpty else { return nil }
            return items
        }
        public var formQueryItems: [URLQueryItem]? { nil }
        public var contentType: String? { nil }
        public var body: Data? { nil }
    }
    
    public struct ConversationContent: Decodable {
        public let globalObjects: GlobalObjects
        public let timeline: Timeline
        
        public struct GlobalObjects: Codable {
            public let tweets: [Twitter.Entity.Internal.Tweet]
            public let users: [Twitter.Entity.User]
            
            public init(from decoder: Decoder) throws {
                let values = try decoder.container(keyedBy: CodingKeys.self)
                tweets = try {
                    let dict = try values.decode([String: Twitter.Entity.Internal.Tweet].self, forKey: .tweets)
                    return Array(dict.values)
                }()
                users = try {
                    let dict = try values.decode([String: Twitter.Entity.User].self, forKey: .users)
                    return Array(dict.values)
                }()
            }
        }
        
        public struct Timeline: Decodable {
            public let id: String
            public let entries: [Entry]
            public let topCursor: String?
            public let bottomCursor: String?
            
            public enum Entry {
                case tweet(statusID: Twitter.Entity.Internal.Tweet.ID)
                case conversationThread(components: [Twitter.Entity.Internal.Tweet.ID])
            }
            
            enum CodingKeys: String, CodingKey {
                case id
                case instructions
            }
            
            enum InstructionKeys: String, CodingKey {
                case clearCache
                case addEntries
            }
            
            enum EntryContainerKeys: String, CodingKey {
                case entries
            }
            
            enum EntryKeys: String, CodingKey {
                case content
            }
            
            enum EntryItemKeys: String, CodingKey {
                case item
            }
            
            enum EntryOprationKeys: String, CodingKey {
                case item
            }
            
            enum TweetKeys: String, CodingKey {
                case id
            }
            
            enum CursorKeys: String, CodingKey {
                case value
                case cursorType
            }
            
            public init(from decoder: Decoder) throws {
                // -> timeline
                let values = try decoder.container(keyedBy: CodingKeys.self)
                // -> timeline.id
                self.id = try values.decode(String.self, forKey: .id)
                
                var entriesResult: [Entry] = []
                var topCursor: String?
                var bottomCursor: String?

                // -> timeline.instructions[]
                var container = try values.nestedUnkeyedContainer(forKey: .instructions)
                while !container.isAtEnd {
                    // -> timeline.instructions[index]
                    let instructionContainer = try container.nestedContainer(keyedBy: InstructionKeys.self)
                    // -> timeline.instructions[index].addEntries
                    guard let entryContainer = try? instructionContainer.nestedContainer(keyedBy: EntryContainerKeys.self, forKey: .addEntries) else {
                        continue
                    }

                    // -> timeline.instructions[index] { .addEntries }
                    var entries = try entryContainer.nestedUnkeyedContainer(forKey: .entries)
                    while !entries.isAtEnd {
                        // -> timeline.instructions[index] { .addEntries.entries }
                        let entry = try entries.nestedContainer(keyedBy: EntryKeys.self)
                        
                        if let content = try? entry.decode(ItemTweetEntry.self, forKey: .content) {
                            entriesResult.append(.tweet(statusID: content.item.content.tweet.id))
                        } else if let content = try? entry.decode(ItemConversationThreadEntry.self, forKey: .content) {
                            var components: [Twitter.Entity.V2.Tweet.ID] = []
                            for component in content.item.content.conversationThread.conversationComponents {
                                let id = component.conversationTweetComponent.tweet.id
                                components.append(id)
                            }
                            entriesResult.append(.conversationThread(components: components))
                        } else if let content = try? entry.decode(OperationEntry.self, forKey: .content) {
                            switch content.operation.cursor.cursorType.lowercased() {
                            case "top":
                                topCursor = content.operation.cursor.value
                            case "bottom":
                                bottomCursor = content.operation.cursor.value
                            case "ShowMoreThreads".lowercased():
                                bottomCursor = content.operation.cursor.value
                            case "ShowMoreThreadsPrompt".lowercased():
                                bottomCursor = content.operation.cursor.value
                            default:
                                assertionFailure()
                                continue
                            }
                        } else {
                            continue
                        }
                    }
                }
                
                self.entries = entriesResult
                self.topCursor = topCursor
                self.bottomCursor = bottomCursor
            }   // end init
        }
        
        struct ItemTweetEntry: Codable {
            let item: Item
            
            struct Item: Codable {
                let content: Content
                
                struct Content: Codable {
                    let tweet: Tweet
                    
                    struct Tweet: Codable {
                        let id: String
                    }
                }
            }
        }   // end ItemTweetEntry
        
        struct ItemConversationThreadEntry: Codable {
            let item: Item
            
            struct Item: Codable {
                let content: Content
                
                struct Content: Codable {
                    let conversationThread: ConversationThread
                    
                    struct ConversationThread: Codable {
                        let conversationComponents: [ConversationComponent]
                        
                        struct ConversationComponent: Codable {
                            let conversationTweetComponent: ConversationTweetComponent
                        }

                        struct ConversationTweetComponent: Codable {
                            let tweet: Tweet
                            
                            struct Tweet: Codable {
                                let id: String
                            }
                        }
                    }
                }
            }
        }   // end ItemConversationThreadEntry
        
        struct OperationEntry: Codable {
            let operation: Operation
            
            struct Operation: Codable {
                let cursor: Cursor
                
                struct Cursor: Codable {
                    let value: String
                    let cursorType: String
                }
            }
        }   // end OperationEntry
    }
}
