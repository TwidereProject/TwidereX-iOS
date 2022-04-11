//
//  TranslateEndpoint.swift
//  
//
//  Created by MainasuK on 2022-4-1.
//

import Foundation

public enum TranslateEndpoint {
    public enum Vendor: String, CaseIterable {
        case bing   = "Bing"            // RFC-5646   [lang]-[script]
        case deepl  = "DeepL"           // ISO 639-1  [lang]
        case google = "Google"          // ISO 639-1  [lang]
    }
}

extension TranslateEndpoint.Vendor {
    
    var baseURL: String {
        switch self {
        case .bing:         return "https://www.bing.com/translator"
        case .deepl:        return "https://www.deepl.com/translator"
        case .google:       return "https://translate.google.com"
        }
    }
    
    func translate(
        content: String,
        locale: Locale
    ) -> URL {
        let languageCode = locale.languageCode ?? "en"
        let scriptCode = locale.scriptCode
        
        switch self {
        case .bing:
            var components = URLComponents(string: baseURL)!
            let to = [
                languageCode,
                scriptCode
            ]
            .compactMap { $0 }
            .joined(separator: "-")
            components.queryItems = [
                URLQueryItem(name: "from", value: "auto"),      // source language
                URLQueryItem(name: "to", value: to),            // target language
                URLQueryItem(name: "text", value: content),
            ]
            return components.url!
        case .deepl:
            // DeepL reject URL content
            let escapeURLContent: String = {
                guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
                    return content
                }
                
                let escaped = detector.stringByReplacingMatches(
                    in: content,
                    options: [],
                    range: NSRange(content.startIndex..<content.endIndex, in: content),
                    withTemplate: ""
                )
                
                return escaped
            }()
            var components = URLComponents(string: baseURL)!
            components.fragment = [
                "auto",
                "zh",
                escapeURLContent
            ]
            .joined(separator: "/")
            return components.url!          // base + #auto/<lang>/<content>
        case .google:
            var components = URLComponents(string: baseURL)!
            components.queryItems = [
                URLQueryItem(name: "sl", value: "auto"),        // source language
                URLQueryItem(name: "tl", value: languageCode),  // target language
                URLQueryItem(name: "text", value: content),
                URLQueryItem(name: "op", value: "translate"),   // translate
            ]
            return components.url!
        }
    }
}

extension TranslateEndpoint {
    
    public static func create(
        vendor: Vendor,
        content: String,
        locale: Locale
    ) -> URL {
        return vendor.translate(
            content: content,
            locale: locale
        )
    }
}
