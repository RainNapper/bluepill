//
//  TestMethod.swift
//  pinpill
//
//  Created by Mansfield Mark on 6/1/20.
//  Copyright © 2020 Pinterest. All rights reserved.
//

import Foundation

struct TestMethod: Equatable, Hashable, CustomStringConvertible, Codable {
    var description: String { return "\(testClass)/\(method)" }

    let testClass: String
    let method: String

    init(testClass: String, method: String) {
        self.testClass = testClass
        self.method = method
    }

    static func == (lhs: TestMethod, rhs: TestMethod) -> Bool {
        return lhs.testClass == rhs.testClass && lhs.method == rhs.method
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(testClass)
        hasher.combine(method)
    }
}
