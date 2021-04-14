//
//  Task.swift
//  pinpill
//
//  Created by Mansfield Mark on 5/29/20.
//  Copyright © 2020 Pinterest. All rights reserved.
//

import Foundation

class TestRun: CustomStringConvertible {
    var description: String { return "\(key) - \(task.label)" }

    enum Status {
        case none
        case started
        case completed
    }

    enum Outcome {
        case none
        case passed
        case failed
        case toolFailure
        case timeout
    }

    let runID: Int
    let task: TestTask
    let fm: FileManager
    let shell: Shell

    var bpConfigURL: URL?
    var process: Process?
    var status: Status
    var outcome: Outcome
    // Note: We only track this because for some reason, when bp gets SIGINT, it returns with BPExitStatusAllTestsPassed
    var interrupted: Bool
    var timedOut: Bool

    // This will be used in filenames, so avoid any invalid characters.
    var key: String { return "\(task.taskID)_\(runID)" }

    init(runID: Int, task: TestTask) {
        self.runID = runID
        self.task = task
        process = nil
        status = .none
        outcome = .none
        interrupted = false
        timedOut = false

        fm = FileManager.default
        shell = Shell()
    }

    func run(onRunComplete: @escaping (TestRun) -> Void) throws {
        status = .started
        let bpConfigURL = try writeBPConfigToTmpFile()
        self.bpConfigURL = bpConfigURL
        
        let env = ["_BP_NUM": description]
        let outputURL =
            task.config.urls.outputURL
                // Filter the label since it is user-inputted.
                .appendingPathComponent(task.label.filter(TestRun.isAllowedFilenameCharacter))
                .appendingPathComponent(key)
        let outputPath = outputURL.path
        let process = shell.launchProcess(
            cmd: task.config.urls.bpURL.path,
            args: [
                "-c", bpConfigURL.path,
                "--output-dir", outputPath,
                "--screenshots-directory", outputPath,
                "--videos-directory", outputPath,
            ],
            env: env,
            printOutput: true
        )
        self.process = process
        
        let timeoutSeconds = task.config.taskTimeoutSeconds
        let timeoutWork = DispatchWorkItem() {
            if (self.outcome != .none) {
                Logger.warning(msg: "Timeout task for run \(self.description) executed, but outcome was already set.")
                return
            }
            
            Logger.error(
                msg: "Test run timed out after \(timeoutSeconds) seconds. Interrupting test run \(self.description)")
            self.timedOut = true
            self.process?.interrupt()
        }
        self.task.timeoutQueue.asyncAfter(deadline: .now() + Double(timeoutSeconds), execute: timeoutWork)
        
        process.terminationHandler = { p in
            self.task.timeoutQueue.async {
                timeoutWork.cancel()
                self.finalizeRun(process: p)
                onRunComplete(self)
            }
        }
    }
    
    func finalizeRun(process: Process) {
        status = .completed

        if let bpConfigURL = self.bpConfigURL, fm.fileExists(atPath: bpConfigURL.path) {
            do {
                Logger.verbose(msg: "Deleting bp config after run completion.")
                try fm.removeItem(at: bpConfigURL)
            } catch {
                Logger.error(msg: "Failed to delete bp config file.\n\(error)")
            }
        }
        
        if timedOut {
            Logger.warning(msg: "Task \(description) timed out")
            outcome = .timeout
            return
        }

        if interrupted {
            Logger.warning(msg: "Task \(description) was interrupted.")
            outcome = .toolFailure
            return
        }

        guard let bpExitStatus = BPExitStatus(rawValue: process.terminationStatus) else {
            Logger.error(msg: "BP task exit code could not be converted to an exit status")
            outcome = .toolFailure
            return
        }

        Logger.info(msg: "TestRun \(key) process terminated with exit code \(process.terminationStatus), status \(bpExitStatus)")
        outcome = mapBPExitStatusToOutcome(bpExitStatus: bpExitStatus)
    }

    func mapBPExitStatusToOutcome(bpExitStatus: BPExitStatus) -> Outcome {
        switch bpExitStatus {
        case .allTestsPassed:
            return .passed
        case .testsFailed:
            return .failed
        case .simulatorCreationFailed:
            return .toolFailure
        case .installAppFailed:
            return .toolFailure
        case .interrupted:
            return .toolFailure
        case .simulatorCrashed:
            return .toolFailure
        case .launchAppFailed:
            return .toolFailure
        case .testTimeout:
            return .timeout
        case .appCrashed:
            return .failed
        case .simulatorDeleted:
            return .toolFailure
        case .uninstallAppFailed:
            return .toolFailure
        case .simulatorReuseFailed:
            return .toolFailure
        }
    }

    func writeBPConfigToTmpFile() throws -> URL {
        let tmpConfigURL = fm.temporaryDirectory.appendingPathComponent("\(key).json")
        Logger.verbose(msg: "Writing bp config to \(tmpConfigURL)")
        let success = fm.createFile(atPath: tmpConfigURL.path, contents: task.bpConfigJSON, attributes: nil)
        if !success {
            assert(success, "todo, config creation failed")
        }
        return tmpConfigURL
    }

    func interrupt() {
        interrupted = true
        process?.interrupt()
    }

    func terminate() {
        interrupted = true
        process?.terminate()
    }
    
    static func isAllowedFilenameCharacter(c: Character) -> Bool {
        return c.isLetter || c.isNumber || c == "-" || c == "_"
    }
}
