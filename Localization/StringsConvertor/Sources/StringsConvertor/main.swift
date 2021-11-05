import os.log
import Foundation

class Helper {
    
    func convert(from input: URL, to output: URL) {
        do {
            let inputLanguageDirectoryURLs = try FileManager.default.contentsOfDirectory(
                at: input,
                includingPropertiesForKeys: [.nameKey, .isDirectoryKey],
                options: []
            )
            for inputLanguageDirectoryURL in inputLanguageDirectoryURLs {
                let language = inputLanguageDirectoryURL.lastPathComponent
                guard let mappedLanguage = map(language: language) else { continue }
                let outputDirectoryURL = output.appendingPathComponent(mappedLanguage + ".lproj", isDirectory: true)
                os_log("%{public}s[%{public}ld], %{public}s: process %s -> %s", ((#file as NSString).lastPathComponent), #line, #function, language, mappedLanguage)
                
                let fileURLs = try FileManager.default.contentsOfDirectory(
                    at: inputLanguageDirectoryURL,
                    includingPropertiesForKeys: [.nameKey, .isDirectoryKey],
                    options: []
                )
                for jsonURL in fileURLs where jsonURL.pathExtension == "json" {
                    os_log("%{public}s[%{public}ld], %{public}s: process %s", ((#file as NSString).lastPathComponent), #line, #function, jsonURL.debugDescription)
                    let filename = jsonURL.deletingPathExtension().lastPathComponent
                    guard let (mappedFilename, keyStyle) = map(filename: filename) else { continue }
                    let outputFileURL = outputDirectoryURL.appendingPathComponent(mappedFilename).appendingPathExtension("strings")
                    let strings = try process(url: jsonURL, keyStyle: keyStyle)
                    try? FileManager.default.createDirectory(at: outputDirectoryURL, withIntermediateDirectories: true, attributes: nil)
                    try strings.write(to: outputFileURL, atomically: true, encoding: .utf8)
                }
            }
        } catch {
            os_log("%{public}s[%{public}ld], %{public}s: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
            exit(1)
        }
    }
    
    private func map(language: String) -> String? {
        switch language {
        case "ar_SA":   return "ar"         // Arabic
        case "en_US":   return "en"
        case "zh_CN":   return "zh-Hans"    // Chinese Simplified
        case "ja_JP":   return "ja"         // Japanese
        case "de_DE":   return "de"         // German
        case "pt_BR":   return "pt-BR"      // Brazilian Portuguese
        case "ca_ES":   return "ca"         // Catalan
        case "es_ES":   return "es"         // Spanish
        case "ko_KR":   return "ko"         // Korean
        default:        return nil
        }
    }
    
    private func map(filename: String) -> (filename: String, keyStyle: Parser.KeyStyle)? {
        switch filename {
        case "app":             return ("Localizable", .swiftgen)
        case "ios-infoPlist":   return ("infoPlist", .infoPlist)
        default:                return nil
        }
    }
    
    private func process(url: URL, keyStyle: Parser.KeyStyle) throws -> String {
        do {
            let data = try Data(contentsOf: url)
            let parser = try Parser(data: data)
            let strings = parser.generateStrings(keyStyle: keyStyle)
            return strings
        } catch {
            os_log("%{public}s[%{public}ld], %{public}s: error: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
            throw error
        }
    }
}

extension Helper {
    
    func move(from inputDirectoryURL: URL, to outputDirectoryURL: URL, sourceFilename: String, destinationFilename: String, pathExtension: String) {
        do {
            let inputLanguageDirectoryURLs = try FileManager.default.contentsOfDirectory(
                at: inputDirectoryURL,
                includingPropertiesForKeys: [.nameKey, .isDirectoryKey],
                options: []
            )
            for inputLanguageDirectoryURL in inputLanguageDirectoryURLs {
                let language = inputLanguageDirectoryURL.lastPathComponent
                guard let mappedLanguage = map(language: language) else { continue }
                let outputDirectoryURL = outputDirectoryURL.appendingPathComponent(mappedLanguage + ".lproj", isDirectory: true)
                os_log("%{public}s[%{public}ld], %{public}s: process %s -> %s", ((#file as NSString).lastPathComponent), #line, #function, language, mappedLanguage)
                
                let fileURLs = try FileManager.default.contentsOfDirectory(
                    at: inputLanguageDirectoryURL,
                    includingPropertiesForKeys: [.nameKey, .isDirectoryKey],
                    options: []
                )
                for dictURL in fileURLs where dictURL.pathExtension == pathExtension {
                    os_log("%{public}s[%{public}ld], %{public}s: process %s", ((#file as NSString).lastPathComponent), #line, #function, dictURL.debugDescription)
                    let filename = destinationFilename
                    
                    let outputFileURL = outputDirectoryURL.appendingPathComponent(filename).appendingPathExtension(pathExtension)
                    try? FileManager.default.createDirectory(at: outputDirectoryURL, withIntermediateDirectories: true, attributes: nil)
                    try FileManager.default.copyItem(at: dictURL, to: outputFileURL)
                }
            }
        } catch {
            os_log("%{public}s[%{public}ld], %{public}s: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
            exit(2)
        }
    }
    
}

let currentFileURL = URL(fileURLWithPath: "\(#file)", isDirectory: false)
let packageRootURL = currentFileURL.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
let inputDirectoryURL = packageRootURL.appendingPathComponent("input", isDirectory: true)
let outputDirectoryURL = packageRootURL.appendingPathComponent("output", isDirectory: true)

Helper().convert(from: inputDirectoryURL, to: outputDirectoryURL)
Helper().move(from: inputDirectoryURL, to: outputDirectoryURL, sourceFilename: "app", destinationFilename: "Localizable", pathExtension: "stringsdict")
