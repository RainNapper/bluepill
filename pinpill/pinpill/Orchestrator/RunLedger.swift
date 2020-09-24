//
//  RunLedger.swift
//  pinpill
//
//  Created by Mansfield Mark on 7/13/20.
//  Copyright © 2020 Pinterest. All rights reserved.
//

import Foundation

/**
 Class to handle adding and tracking tasks to be run. Also enforces a maximum number of concurrent runs.
 */
class RunLedger {
    let maxConcurrentRuns: Int
    
    /// Used to synchronize access to variables that track run status.
    private let runLedgerUpdateDispatchQueue: DispatchQueue

    private var unstartedRuns: [TestRun]
    private var activeRuns: [String: TestRun]
    private var completedRuns: [TestRun]
    private var frozen: Bool

    init(maxConcurrentRuns: Int) {
        self.maxConcurrentRuns = maxConcurrentRuns

        runLedgerUpdateDispatchQueue = DispatchQueue(label: "pinpill-run-ledger-updates")
        unstartedRuns = []
        activeRuns = [:]
        completedRuns = []
        frozen = false
    }

    /**
     Adds the provided test runs to the queue.
     */
    func addRuns(runs: [TestRun]) {
        runLedgerUpdateDispatchQueue.sync {
            if frozen {
                print("[Warning] Frozen ledger, ignoring addRuns")
                return
            }
            unstartedRuns.append(contentsOf: runs)
        }
    }

    /**
     Pops as many runs from the queue as allowed within the max concurrent runs, and returns them. These tasks are now considered active.
     */
    func flush() -> [TestRun] {
        runLedgerUpdateDispatchQueue.sync {
            if frozen {
                print("[Warning] Frozen ledger, ignoring flush")
                return []
            }

            if activeRuns.count > maxConcurrentRuns {
                print("[Error] Number of active runs exceeded max concurrent tasks")
            }

            var newActiveRuns: [TestRun] = []
            while activeRuns.count < maxConcurrentRuns, !unstartedRuns.isEmpty {
                let run = unstartedRuns.removeFirst()
                activeRuns[run.key] = run
                newActiveRuns.append(run)
            }

            return newActiveRuns
        }
    }

    /**
     Marks a currently active run as completed.
     */
    func completeRun(run: TestRun) {
        runLedgerUpdateDispatchQueue.sync {
            if frozen {
                print("[Warning] Frozen ledger, ignoring completeRun")
                return
            }

            guard let completedRun = self.activeRuns.removeValue(forKey: run.key) else {
                print("[Error] Couldn't find active run for a task that just completed")
                return
            }
            self.completedRuns.append(completedRun)
        }
    }

    /**
     Freeze the dispatch queue from changing. This is helpful to prevent new tasks from being registered.
     */
    func freeze() {
        runLedgerUpdateDispatchQueue.sync {
            print("Freezing run ledger")
            self.frozen = true
        }
    }
    
    func getNumActiveRuns() -> Int {
        runLedgerUpdateDispatchQueue.sync {
            return activeRuns.count
        }
    }

    func getActiveRuns() -> [TestRun] {
        runLedgerUpdateDispatchQueue.sync {
            if !frozen {
                print("[Warning] Accessing active runs on an unfrozen ledger.")
            }

            return Array(activeRuns.values)
        }
    }
}
