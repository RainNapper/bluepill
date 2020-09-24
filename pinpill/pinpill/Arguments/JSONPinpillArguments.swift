//
//  JSONRawConfig.swift
//  pinpill
//
//  Created by Mansfield Mark on 7/9/20.
//  Copyright © 2020 Pinterest. All rights reserved.
//

import Foundation

struct JSONPinpillArguments: PinpillArguments, Codable {
    var headless: Bool?

    var recordVideo: Bool?

    var recordScreenshot: Bool?

    var maxSims: Int?

    var maxRetries: Int?

    var numTestRuns: Int?

    var device: String?

    var runtime: String?

    var testTasks: [TestTaskConfig]?

    var appPath: String?

    var testAppPath: String?

    var xcTestRunPath: String?

    var bpPath: String?

    var outputPath: String?

    var simulatorPreferencesPath: String?

    var environment: [String: String]?
}
