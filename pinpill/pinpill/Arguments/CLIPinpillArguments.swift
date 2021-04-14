//
//  CLIConfig.swift
//  pinpill
//
//  Created by Mansfield Mark on 7/9/20.
//  Copyright © 2020 Pinterest. All rights reserved.
//

import Foundation

struct CLIPinpillArguments: PinpillArguments {
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
    
    var taskTimeoutSeconds: Int?

    init(command: PinpillCLI) {
        headless = command.headless ? true : nil
        recordVideo = command.noRecordVideo ? false : nil
        recordScreenshot = command.noRecordScreenshot ? false : nil
        maxSims = command.maxSims
        maxRetries = command.maxRetries
        numTestRuns = command.numTestRuns
        device = command.device
        runtime = command.runtime
        taskTimeoutSeconds = command.taskTimeoutSeconds

        if let testsToRunString = command.testsToRun {
            testTasks = testsToRunString
                .split(separator: ",")
                .map { $0.split(separator: "/") }
                .map { TestMethod(testClass: String($0[0]), method: String($0[1])) }
                .map { method in TestTaskConfig(tests: [method], label: method.description) }
        } else {
            testTasks = nil
        }

        appPath = command.app
        testAppPath = command.testApp
        xcTestRunPath = command.xcTestRunPath
        bpPath = command.bpPath
        outputPath = command.outputPath
        simulatorPreferencesPath = command.simulatorPreferencesPath

        if let environmentString = command.environment {
            let environmentKeyValuePairs = environmentString.split(separator: ",")
                .compactMap { (keyValueString: Substring) -> (String, String)? in
                    let keyValueStringSplit = keyValueString.split(separator: ":", maxSplits: 1)
                    if keyValueStringSplit.count != 2 {
                        print("[Error] Skipping over invalid environment assignment: \(keyValueString)")
                        return nil
                    }
                    return (String(keyValueStringSplit[0]), String(keyValueStringSplit[1]))
                }
            environment = Dictionary(uniqueKeysWithValues: environmentKeyValuePairs)
        } else {
            environment = nil
        }
    }
}
