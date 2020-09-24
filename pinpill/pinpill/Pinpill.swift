//
//  Pinpill.swift
//  pinpill
//
//  Created by Mansfield Mark on 5/29/20.
//  Copyright © 2020 Pinterest. All rights reserved.
//

import AppKit
import Foundation

class Pinpill {
    let config: PinpillConfiguration
    let metrics: Metrics

    let fileManager = FileManager.default

    var orchestrator: Orchestrator?
    var interrupted: Bool

    // Keep this here just as an easy way of generating unique task IDs. If this gets more complicated
    // consider abstracting into a TaskIDProvider.
    var taskCount = 0

    init(config: PinpillConfiguration) {
        self.config = config
        self.metrics = Metrics(outputRootURL: config.urls.outputURL)

        orchestrator = nil
        interrupted = false
    }

    func start() {
        do {
            let xcTests = try XCTest.fromXCTestRun(
                xcTestRunURL: config.urls.xcTestRunURL,
                testRootURL: config.urls.testRootURL,
                xcodeURL: config.urls.xcodeURL
            )

            let tasks = config.testTasks.flatMap { buildTaskFromConfig(taskConfig: $0, xcTests: xcTests) }
            Logger.info(msg: "Built \(tasks.count) test tasks: \(tasks.map { $0.label })")

            if interrupted {
                Logger.warning(msg: "Handling interrupt before opening simulator app, exiting early.")
                return
            }

            if !config.headless {
                openSimulatorApp()
            }

            if interrupted {
                Logger.warning(msg: "Handling interrupt before starting orchestrator, exiting early.")
                return
            }

            let orchestrator = Orchestrator(tasks: tasks, maxConcurrentTasks: config.maxSims, metrics: metrics)
            self.orchestrator = orchestrator
            orchestrator.start()

            let reportCollector = ReportCollector(fileManager: fileManager)
            reportCollector.collectReports(root: config.urls.outputURL)
            
            metrics.save()
        } catch {
            Logger.error(msg: error.localizedDescription)
        }
    }

    func openSimulatorApp() {
        let workspace = NSWorkspace()
        let options: NSWorkspace.LaunchOptions = [.async, .withoutActivation, .andHide]
        let configuration: [NSWorkspace.LaunchConfigurationKey: Any] = [NSWorkspace.LaunchConfigurationKey.arguments: ["-StartLastDeviceOnLaunch", "0"]]
        do {
            try workspace.launchApplication(at: config.urls.simulatorURL, options: options, configuration: configuration)
        } catch {
            Logger.error(msg: "Failed to launch Simulator.app with error: \(error)")
        }
    }

    func interrupt() {
        interrupted = true
        orchestrator?.interrupt()
    }

    func terminate() {
        interrupted = true
        orchestrator?.terminate()
    }

    func buildTaskFromConfig(taskConfig: TestTaskConfig, xcTests: [XCTest]) -> [TestTask] {
        // Verify that tests listed in TestTaskConfig can actually be run
        // Skip TestTask if:
        //  1) Any test is missing from all .xctest bundles
        //  2) Any two tests are from separate .xctest bundles (not compatible with bp)
        var xcTestForTaskOpt: XCTest?
        for test in taskConfig.tests {
            guard let xcTestForTest = (xcTests.first { xcTest in xcTest.testClasses.contains(test) }) else {
                Logger.error(msg: "Could not find test \(test) in any of the referenced test bundles. Skipping.")
                return []
            }

            if xcTestForTaskOpt == nil {
                xcTestForTaskOpt = xcTestForTest
            } else if xcTestForTest !== xcTestForTaskOpt {
                Logger.error(msg: "Each TestTask should only contain tests that are part of the same .xctest bundle. \(taskConfig.tests) are part of multiple different test bundles. Skipping.")
                return []
            }
        }

        guard let xcTestForTask = xcTestForTaskOpt else {
            Logger.error(msg: "Could not find any tests \(taskConfig.tests) in any of the referenced test bundles. Skipping.")
            return []
        }

        return (1 ... config.numTestRuns).map { _ in
            let task = TestTask(
                taskID: taskCount,
                testMethods: taskConfig.tests,
                label: taskConfig.label,
                xcTest: xcTestForTask,
                config: config
            )
            taskCount += 1
            return task
        }
    }
}
