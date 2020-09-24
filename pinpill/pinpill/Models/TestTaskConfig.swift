//
//  TestTaskConfig.swift
//  pinpill
//
//  Created by Mansfield Mark on 7/9/20.
//  Copyright © 2020 Pinterest. All rights reserved.
//

import Foundation

struct TestTaskConfig: CustomStringConvertible, Codable {
    var description: String { return label }

    let label: String
    let tests: [TestMethod]

    init(tests: [TestMethod], label: String) {
        self.tests = tests
        self.label = label
    }
}
