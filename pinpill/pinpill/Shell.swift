//
//  Shell.swift
//  pinpill
//
//  Created by Mansfield Mark on 5/30/20.
//  Copyright © 2020 Pinterest. All rights reserved.
//

import Foundation
class Shell {
    static let kBinPwd = "/bin/pwd"
    static let kBinKill = "/bin/kill"
    static let kBinKillAll = "/usr/bin/killall"
    static let kBinWhich = "/usr/bin/which"
    static let kBinPs = "/bin/ps"
    static let kBinXcRun = "/usr/bin/xcrun"
    static let kBinXCodeSelect = "/usr/bin/xcode-select"
    static let kBinXcodeBuild = "/usr/bin/xcodebuild"
    static let kBinLast = "/usr/bin/last"
    static let kBinDf = "/bin/df"
    static let kBinNm = "/usr/bin/nm"
    static let kDateFormat = "yyyy-MM-dd HH:mm:ss"
    static let kMaxCmdDisplayChars = 200

    let dateFormat = DateFormatter()

    init() {
        dateFormat.dateFormat = Shell.kDateFormat
    }

    func launchProcess(cmd: String,
                       args: [String] = [],
                       env: [String: String]? = nil,
                       printOutput: Bool = true,
                       stdIn: Pipe? = nil,
                       stdOut: Pipe = Pipe(),
                       stdErr: Pipe = Pipe(),
                       terminationHandler: ((Process) -> Void)? = nil) -> Process {
        let cmdString = "\(cmd) \(args.joined(separator: " "))"
        let p = Process()
        p.launchPath = "/bin/sh"
        p.arguments = ["-c", cmdString]

        if env != nil {
            p.environment = env
        }
        if terminationHandler != nil {
            p.terminationHandler = terminationHandler
        }

        if stdIn != nil {
            p.standardInput = stdIn
        }
        if printOutput {
            p.standardOutput = FileHandle.standardOutput
            p.standardError = FileHandle.standardError
        } else {
            p.standardOutput = stdOut
            p.standardError = stdErr
        }

        let displayCmdString: String
        if cmdString.count > Shell.kMaxCmdDisplayChars {
            displayCmdString = "\(cmdString.prefix(Shell.kMaxCmdDisplayChars))..."
        } else {
            displayCmdString = cmdString
        }

        Logger.info(msg: displayCmdString)
        p.launch()
        return p
    }

    func launchAndWaitForProcess(
        cmd: String,
        args: [String] = [],
        env: [String: String]? = nil,
        printOutput: Bool = true,
        stdOut: Pipe = Pipe(),
        stdErr: Pipe = Pipe()
    ) -> Process {
        let p = launchProcess(cmd: cmd, args: args, env: env, printOutput: printOutput, stdOut: stdOut, stdErr: stdErr)
        p.waitUntilExit()
        return p
    }

    func launchWaitAndGetOutput(cmd: String, args: [String] = [], env: [String: String]? = nil) -> (process: Process, stdOut: String) {
        let outPipe = Pipe()
        let process = launchProcess(cmd: cmd, args: args, env: env, printOutput: false, stdOut: outPipe, stdErr: outPipe)
        let stdOut = readPipeAsString(pipe: outPipe)
        process.waitUntilExit()
        return (process: process, stdOut: stdOut)
    }

    func which(executable: String) -> String? {
        let result = launchWaitAndGetOutput(cmd: Shell.kBinWhich, args: [executable])
        let executablePath = result.stdOut.trimmingCharacters(in: .whitespacesAndNewlines)
        if executablePath.isEmpty {
            Logger.error(msg: "Could not find path of executable named \(executable)")
            return nil
        }
        return executablePath
    }

    func readPipeAsString(pipe: Pipe) -> String {
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)!
    }

    func env(varName: String, fallback: String = "") -> String {
        let varValue = ProcessInfo.processInfo.environment[varName]
        if let varValue = varValue {
            return varValue
        }

        Logger.warning(msg: "Env var \(varName) was not assigned, defaulting to \"\(fallback)\"")
        return fallback
    }

    func envMap() -> [String: String] {
        return ProcessInfo.processInfo.environment
    }

    func envOrNil(varName: String) -> String? {
        return ProcessInfo.processInfo.environment[varName]
    }

    func envAsBool(varName: String) -> Bool {
        return ProcessInfo.processInfo.environment[varName]?.caseInsensitiveCompare("true") == .orderedSame
    }
}
