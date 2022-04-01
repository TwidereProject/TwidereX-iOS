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
                os_log("%{public}s[%{public}ld], %{public}s: process %s -> %s", ((#file as NSString).lastPathComponent), #line, #function, language, mappedLanguage)
                
                let fileURLs = try FileManager.default.contentsOfDirectory(
                    at: inputLanguageDirectoryURL,
                    includingPropertiesForKeys: [.nameKey, .isDirectoryKey],
                    options: []
                )
                
                // needs convert JSON file only
                for jsonURL in fileURLs where jsonURL.pathExtension == "json" {
                    os_log("%{public}s[%{public}ld], %{public}s: process %s", ((#file as NSString).lastPathComponent), #line, #function, jsonURL.debugDescription)
                    
                    let filename = jsonURL.deletingPathExtension().lastPathComponent
                    guard let (mappedFilename, keyStyle) = map(filename: filename) else { continue }
                    guard let bundle = bundle(filename: filename) else { continue }
                    
                    let outputDirectoryURL = output
                        .appendingPathComponent(bundle, isDirectory: true)
                        .appendingPathComponent(mappedLanguage + ".lproj", isDirectory: true)
                    
                    let outputFileURL = outputDirectoryURL
                        .appendingPathComponent(mappedFilename)
                        .appendingPathExtension("strings")
                    
                    let strings = try process(url: jsonURL, keyStyle: keyStyle)
                    try? FileManager.default.createDirectory(at: outputDirectoryURL, withIntermediateDirectories: true, attributes: nil)
                    
                    try strings.write(to: outputFileURL, atomically: true, encoding: .utf8)
                }
            }
        } catch {
            os_log("%{public}s[%{public}ld], %{public}s: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
            debugPrint(error)
            exit(1)
        }
    }
    
    private func map(language: String) -> String? {
        switch language {
        case "ar_SA":   return "ar"         // Arabic
        case "eu_ES":   return "eu"         // Basque
        case "en_US":   return "en"
        case "zh_CN":   return "zh-Hans"    // Chinese Simplified
        case "ja_JP":   return "ja"         // Japanese
        case "de_DE":   return "de"         // German
        case "pt_BR":   return "pt-BR"      // Brazilian Portuguese
        case "ca_ES":   return "ca"         // Catalan
        case "es_ES":   return "es"         // Spanish
        case "ko_KR":   return "ko"         // Korean
        case "tr_TR":   return "tr"         // Turkish
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
    
    private func bundle(filename: String) -> String? {
        switch filename {
        case "app":             return "module"
        case "ios-infoPlist":   return "main"
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
    
    func copy(from inputDirectoryURL: URL, to outputDirectoryURL: URL, sourceFilename: String, destinationFilename: String, pathExtension: String) {
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
                for fileURL in fileURLs where fileURL.pathExtension == pathExtension {
                    os_log("%{public}s[%{public}ld], %{public}s: process %s", ((#file as NSString).lastPathComponent), #line, #function, fileURL.debugDescription)
                    
                    let filename = fileURL.deletingPathExtension().lastPathComponent
                    guard filename == sourceFilename else {
                        debugPrint("try move \(filename) but not match \(sourceFilename) rule. skip it")
                        continue
                    }
                    
                    let outputFileURL = outputDirectoryURL.appendingPathComponent(destinationFilename).appendingPathExtension(pathExtension)
                    try? FileManager.default.createDirectory(at: outputDirectoryURL, withIntermediateDirectories: true, attributes: nil)

                    try FileManager.default.copyItem(at: fileURL, to: outputFileURL)
                }
            }
        } catch {
            os_log("%{public}s[%{public}ld], %{public}s: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
            debugPrint(error)
            exit(2)
        }
    }
    
}

let currentFileURL = URL(fileURLWithPath: "\(#file)", isDirectory: false)
let packageRootURL = currentFileURL.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()

let inputDirectoryURL = packageRootURL.appendingPathComponent("input", isDirectory: true)
let outputDirectoryURL = packageRootURL.appendingPathComponent("output", isDirectory: true)
Helper().convert(from: inputDirectoryURL, to: outputDirectoryURL)

// use stringdict without convert
let outputBundleModuleDirectoryURL = outputDirectoryURL.appendingPathComponent("module", isDirectory: true)
Helper().copy(from: inputDirectoryURL, to: outputBundleModuleDirectoryURL, sourceFilename: "app", destinationFilename: "Localizable", pathExtension: "stringsdict")
