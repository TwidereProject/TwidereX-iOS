//
//  TwidereXTests+Issue92.swift
//  TwidereXTests
//
//  Created by MainasuK on 2022-7-19.
//  Copyright © 2022 Twidere. All rights reserved.
//

import XCTest
@testable import TwidereX

// https://github.com/TwidereProject/TwidereX-iOS/issues/92
extension TwidereXTests {
 
    @MainActor
    func testIssue92() async throws {
        let assetURL = URL(string: "https://pbs.twimg.com/media/FX9pNPaUcAATPfh?format=jpg&name=orig")!
        
        guard let fileURL = try await PhotoLibraryService().file(from: .remote(url: assetURL)) else {
            throw AppError.implicit(.internal(reason: "cannot save file"))
        }
        
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): url: \(fileURL), pathExtension: \(fileURL.pathExtension)")
        XCTAssert(!fileURL.pathExtension.isEmpty, "extension should be valid")
    }
    
}
