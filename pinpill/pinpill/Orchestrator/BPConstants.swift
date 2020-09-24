//
//  BPConstants.swift
//  pinpill
//
//  Created by Mansfield Mark on 6/12/20.
//  Copyright © 2020 Pinterest. All rights reserved.
//

import Foundation

// Duplicate implementation of bp's exit status enum.
// Enum values in swift must be literals, so hardcode the
// bits
enum BPExitStatus: Int32 {
    case allTestsPassed = 0b0
    case testsFailed = 0b1
    case simulatorCreationFailed = 0b10
    case installAppFailed = 0b100
    case interrupted = 0b1000
    case simulatorCrashed = 0b10000
    case launchAppFailed = 0b100000
    case testTimeout = 0b1000000
    case appCrashed = 0b1000_0000
    case simulatorDeleted = 0b1_0000_0000
    case uninstallAppFailed = 0b10_0000_0000
    case simulatorReuseFailed = 0b100_0000_0000
}
