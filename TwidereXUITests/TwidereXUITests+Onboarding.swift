//
//  TwidereXUITests+Onboarding.swift
//  TwidereXUITests
//
//  Created by MainasuK on 2022-3-4.
//  Copyright © 2022 Twidere. All rights reserved.
//

import XCTest

extension TwidereXUITests {
    
    func testOnboardingTwitterLogin() async throws {
        let app = XCUIApplication()
        app.launch()
        
        let twitterLoginButton = app.buttons["Sign in with Twitter"].firstMatch
        XCTAssert(twitterLoginButton.waitForExistence(timeout: 5))
        twitterLoginButton.tap()
        
        try await authorizeTwitter(app: app)
    }
    
}

extension TwidereXUITests {
    
    private func presentOnboardingWelcome(app: XCUIApplication) {
        
    }
    
    
    /// Fulfill the form and complete OAuth process
    private func authorizeTwitter(app: XCUIApplication) async throws {
        // input email
        let email = ProcessInfo.processInfo.environment["email"]!
        let emailTextField = app.textFields["Username or email"].firstMatch
        XCTAssert(emailTextField.waitForExistence(timeout: 20))
        emailTextField.tap()
        emailTextField.typeText(email)
        
        // input password
        let password = ProcessInfo.processInfo.environment["password"]!
        let passwordTextField = app.secureTextFields["Password"].firstMatch
        XCTAssert(passwordTextField.waitForExistence(timeout: 5))
        passwordTextField.tap()
        passwordTextField.typeText(password)
        
        let authorizeButton = app.buttons["Authorize app"].firstMatch
        XCTAssert(authorizeButton.waitForExistence(timeout: 5))
        authorizeButton.tap()
        
        try await Task.sleep(nanoseconds: .second * 10)
        
        guard app.navigationBars["Timeline"].exists else {
            XCTFail("Fail to authenticate")
            return
        }
    }
    
}
