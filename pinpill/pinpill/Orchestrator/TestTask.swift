//
//  TestTask.swift
//  pinpill
//
//  Created by Mansfield Mark on 6/1/20.
//  Copyright © 2020 Pinterest. All rights reserved.
//

import Foundation

class TestTask {
    enum Status {
        case none
        case started
        case completed
    }

    enum Outcome {
        case none
        case passed
        case flaky
        case failed
        case toolFailure
        case timeout
    }

    let taskID: Int
    let testMethods: [TestMethod]
    let label: String
    let xcTest: XCTest
    let config: PinpillConfiguration
    let timeoutQueue: DispatchQueue

    let bpConfig: [String: Any?]
    let bpConfigJSON: Data

    var status: Status
    var outcome: Outcome
    var runs: [TestRun]

    init(taskID: Int, testMethods: [TestMethod], label: String, xcTest: XCTest, config: PinpillConfiguration) {
        self.taskID = taskID
        self.testMethods = testMethods
        self.label = label
        self.xcTest = xcTest
        self.config = config
        self.timeoutQueue = DispatchQueue(label: "timeout-queue-\(taskID)")

        status = .none
        outcome = .none
        runs = []

        let combinedEnvironment = config.environment.merging(xcTest.environment) { (v1: String, v2: String) in
            Logger.warning(msg: "Found value conflict in environment: \(v1) and \(v2). Using the one in configuration: \(v1)")
            return v2
        }

        // bp can only handle one test-bundle-path at a time
        // if testMethods contains multiple tests, the tests
        // should be part of the same bundle.
        let bpConfig: [String: Any?] = [
            "headless": config.headless,
            "app": xcTest.appBundleURL.path,
            "test-bundle-path": xcTest.testBundleURL.path,
            "runner-app-path": xcTest.testRunnerAppURL?.path,
            "include": testMethods.map { $0.description },
            "device": config.device,
            "runtime": config.runtime,
            "xcode-path": config.urls.xcodeURL.path,
            "simulator-preferences-file": config.urls.simulatorPreferencesURL.path,
            "commandLineArguments": xcTest.commandLineArguments,
            "environmentVariables": combinedEnvironment,
            "test-timeout": 300,
            "delete-timeout": 60,
            "create-timeout": 60,
            "launch-timeout": 60,
            "repeat-count": 1,
            "failure-tolerance": 0,
            "error-retries": 0,
            "keep-simulator": false,
            "clone-simulator": false,
            "unsafe-skip-xcode-version-check": true,
            "keep-individual-test-reports": true,
        ]
        self.bpConfig = bpConfig
        bpConfigJSON = try! JSONSerialization.data(withJSONObject: bpConfig, options: [.prettyPrinted, .sortedKeys])
    }

    func initialRuns() -> [TestRun] {
        status = .started
        let run = TestRun(runID: runs.count, task: self)
        runs.append(run)
        return runs
    }

    func onRunComplete(testRun: TestRun) -> [TestRun] {
        Logger.verbose(msg: "TestTask \(testRun.description) - onRunComplete")
        if testRun.runID == 0 {
            return handleInitialRunComplete(testRun: testRun)
        }

        handleRetryRunComplete(testRun: testRun)
        return []
    }

    func handleInitialRunComplete(testRun: TestRun) -> [TestRun] {
        if testRun.outcome == .passed {
            status = .completed
            outcome = .passed
            return []
        }

        if config.maxRetries == 0 {
            status = .completed
            outcome = convertRunOutcomeToTaskOutcome(outcome: testRun.outcome)
            return []
        }

        // Build retry runs
        return (1 ... config.maxRetries).map { _ in
            let run = TestRun(runID: runs.count, task: self)
            runs.append(run)
            return run
        }
    }

    func handleRetryRunComplete(testRun _: TestRun) {
        // Not all are completed, just wait
        if runs.contains(where: { $0.status != .completed }) {
            return
        }

        status = .completed

        // If one of the retries passed, then we have a flaky test
        if runs.contains(where: { $0.outcome == .passed }) {
            outcome = .flaky
        } else {
            outcome = convertRunOutcomeToTaskOutcome(outcome: runs.last!.outcome)
        }
    }

    func convertRunOutcomeToTaskOutcome(outcome: TestRun.Outcome) -> Outcome {
        switch outcome {
        case .none:
            Logger.error(msg: "TestRun outcome was not populated!")
            return .toolFailure
        case .passed:
            Logger.error(msg: "TestRun outcome was passed, but we already assumed no retries passed!")
            return .toolFailure
        case .failed:
            return .failed
        case .toolFailure:
            return .toolFailure
        case .timeout:
            return .timeout
        }
    }
}
