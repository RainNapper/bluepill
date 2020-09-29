//
//  Orchestrator.swift
//  pinpill
//
//  Created by Mansfield Mark on 6/2/20.
//  Copyright © 2020 Pinterest. All rights reserved.
//

import Foundation

public class Orchestrator {
    private let tasks: [TestTask]
    private let maxConcurrentTasks: Int
    private let metrics: Metrics
    
    private let runLedger: RunLedger
    
    
    /// Used to execute the test tasks concurrently
    private let runDispatchQueue: DispatchQueue
    /// Tracks all the active tasks so we can easily wait for them all to complete.
    private let runDispatchGroup: DispatchGroup

    private var stopNewRuns: Bool

    init(tasks: [TestTask], maxConcurrentTasks: Int, metrics: Metrics) {
        self.tasks = tasks
        self.maxConcurrentTasks = maxConcurrentTasks
        self.metrics = metrics

        stopNewRuns = false

        runLedger = RunLedger(maxConcurrentRuns: self.maxConcurrentTasks)
        runDispatchQueue = DispatchQueue(label: "pinpill-orchestrator-runs", attributes: .concurrent)
        runDispatchGroup = DispatchGroup()
    }

    func queueRuns(runs: [TestRun]) {
        if stopNewRuns {
            Logger.warning(msg: "Orchestrator was interrupted, not queuing new runs \(runs.map { $0.description }.joined(separator: ", "))")
            return
        }

        runLedger.addRuns(runs: runs)
    }

    func flushQueue() {
        let newActiveRuns = runLedger.flush()
        newActiveRuns.forEach {
            startRun(run: $0)
        }
    }

    func startRun(run: TestRun) {
        if stopNewRuns {
            Logger.warning(msg: "Orchestrator was interrupted, not starting run \(run)")
            return
        }

        runDispatchGroup.enter()
        runDispatchQueue.async {
            Logger.info(msg: "Starting run: \(run.description)")
            do {
                try run.run() { run in
                    self.onRunComplete(run: run)
                    self.runDispatchGroup.leave()
                }
            } catch {
                Logger.error(msg: "Run \(run.description) leave due to error.")
                self.runDispatchGroup.leave()
                Logger.error(msg: "Error starting run \(run). Skipping.\n\(error)")
            }
        }
    }

    func onRunComplete(run: TestRun) {
        precondition(run.status == .completed && run.outcome != .none, "TestRun completed with an incompleted state: \(run.outcome)")
        Logger.info(msg: "TestRun \(run) completed with outcome \(run.outcome)")
        let numActiveTasks = runLedger.getNumActiveRuns()
        Logger.info(msg: "At completion, there were \(numActiveTasks) active tasks")
        metrics.concurrency.log(pass: run.outcome == .passed, numActiveTasks: numActiveTasks, taskDescription: run.task.label)
        
        runLedger.completeRun(run: run)

        let retries = run.task.onRunComplete(testRun: run)
        if !retries.isEmpty {
            Logger.info(msg: "Scheduling retries: \(retries.map { $0.description }.joined(separator: ", "))")
            queueRuns(runs: retries)
        } else {
            Logger.info(msg: "TestTask \(run.task.label) complete.")
        }
        flushQueue()
    }

    func start() {
        let initialRuns: [TestRun] = tasks.flatMap { $0.initialRuns() }
        queueRuns(runs: initialRuns)
        flushQueue()

        runDispatchGroup.notify(queue: runDispatchQueue) {
            Logger.info(msg: "All tasks completed")
        }

        runDispatchGroup.wait()
    }

    func interrupt() {
        Logger.warning(msg: "Interrupting orchestrator")
        stopNewRuns = true
        runLedger.freeze()
        runLedger.getActiveRuns().forEach {
            $0.interrupt()
        }
    }

    func terminate() {
        Logger.warning(msg: "Terminating orchestrator")
        stopNewRuns = true
        runLedger.freeze()
        runLedger.getActiveRuns().forEach {
            $0.terminate()
        }
    }
}
