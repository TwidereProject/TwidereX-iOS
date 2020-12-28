//
//  CombineTests.swift
//  TwidereXTests
//
//  Created by Cirno MainasuK on 2020-12-28.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import XCTest
import Combine
@testable import TwidereX

class CombineTests: XCTestCase {
    
    var disposeBag = Set<AnyCancellable>()

    
    /// Combine SDK issue test
    ///
    /// This test case crash on the iOS 14.1
    /// EXC_BAD_INSTRUCTION
    func testMapRetrySwitchToLatest() throws {
        let outputExpectation = self.expectation(description: "future")
        
        let inputA = PassthroughSubject<Int?, Never>()
        let inputB = PassthroughSubject<Int?, Never>()
        
        Publishers.CombineLatest(
            inputA.eraseToAnyPublisher(),
            inputB.eraseToAnyPublisher()
        )
        .compactMap { inputA, inputB -> (Int, Int)? in
            guard let inputA = inputA, let inputB = inputB else { return nil }
            return (inputA, inputB)
        }
        .setFailureType(to: Error.self)
        .map { inputA, inputB -> AnyPublisher<Int, Error> in
            return Future<Int, Error> { promise in
                AppContext.shared.backgroundManagedObjectContext.perform {
                    promise(.success(inputA + inputB))
                }
            }
            .tryMap { output -> AnyPublisher<Int, Error> in
                guard output != 0 else {
                    throw StubError.stub
                }
                
                return AppContext.shared.backgroundManagedObjectContext.performChanges {
                    // do nothing
                }
                .setFailureType(to: Error.self)
                .tryMap { result -> Int in
                    switch result {
                    case .success:                  return output
                    case .failure(let error):       throw error
                    }
                }
                .eraseToAnyPublisher()
            }
            .switchToLatest()
            .eraseToAnyPublisher()
            .retry(3)
            .eraseToAnyPublisher()
        }
        .switchToLatest()
        .sink { completion in
            switch completion {
            case .failure(let error):
                outputExpectation.fulfill()
            case .finished:
                break
            }
        } receiveValue: { response in
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: %ld", ((#file as NSString).lastPathComponent), #line, #function, response)
        }
        .store(in: &disposeBag)

        inputA.send(1)
        inputB.send(-1)

        wait(for: [outputExpectation], timeout: 20)
    }

}

extension CombineTests {
    enum StubError: Error {
        case stub
    }
}
