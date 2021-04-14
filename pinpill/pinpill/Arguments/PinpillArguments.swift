//
//  RawConfig.swift
//  pinpill
//
//  Created by Mansfield Mark on 7/9/20.
//  Copyright © 2020 Pinterest. All rights reserved.
//

import Foundation

/**
   Data class to hold all input arguments to the pinpill application. This is `Codable` to easily support a JSON file to pass arguments.
 */
protocol PinpillArguments: Codable {
    var headless: Bool? { get }
    var recordVideo: Bool? { get }
    var recordScreenshot: Bool? { get }
    var maxSims: Int? { get }
    var maxRetries: Int? { get }
    var numTestRuns: Int? { get }
    var device: String? { get }
    var runtime: String? { get }
    var testTasks: [TestTaskConfig]? { get }
    var appPath: String? { get }
    var testAppPath: String? { get }
    var xcTestRunPath: String? { get }
    var bpPath: String? { get }
    var outputPath: String? { get }
    var simulatorPreferencesPath: String? { get }
    var environment: [String: String]? { get }
    var taskTimeoutSeconds: Int? { get }
}
