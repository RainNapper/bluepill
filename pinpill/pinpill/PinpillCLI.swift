//
//  PinpillCLI.swift
//  pinpill
//
//  Created by Mansfield Mark on 7/8/20.
//  Copyright © 2020 Pinterest. All rights reserved.
//

import ArgumentParser
import Foundation

extension Encodable {
    func toJSON() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return String(data: try! encoder.encode(self), encoding: .utf8)!
    }
}

struct PinpillCLI: ParsableCommand {
    @Flag(help: "Whether to run without GUI")
    var headless: Bool = false

    @Flag(help: "Disable saving videos of test runs.")
    var noRecordVideo: Bool = false

    @Flag(help: "Disable saving screenshots of failed UI tests.")
    var noRecordScreenshot: Bool = false

    @Option(help: "Maximum number of concurrent simulators")
    var maxSims: Int?

    @Option(help: "Maximum number of times to retry a test. Default \(PinpillConfiguration.kDefaultMaxRetries)")
    var maxRetries: Int?

    @Option(help: "Maximum number of times to run each test. Default \(PinpillConfiguration.kDefaultNumTestRuns)")
    var numTestRuns: Int?

    @Option(help: "The type of simulator device to use to run tests")
    var device: String?

    @Option(help: "OS to run on the simulator")
    var runtime: String?

    @Option(help: "Comma separated list of test methods to run")
    var testsToRun: String?

    @Option(help: "Path to the application under test")
    var app: String?

    @Option(help: "Path to the test runner application")
    var testApp: String?

    @Option(help: "Path to the xctestrun file to run the tests")
    var xcTestRunPath: String?

    @Option(help: "Path to the bp executable included in bluepill")
    var bpPath: String?

    @Option(help: "Directory where to put output log files.")
    var outputPath: String?

    @Option(help: "Path to simulator preferences file.")
    var simulatorPreferencesPath: String?

    @Option(help: "Environment variables to set in the simulator, in the form KEY:value,KEY2:value2")
    var environment: String?

    // -----------------------------------------------------------------------------

    @Option(help: "Path to pinpill configuration json, mirroring the CLI arguments. Keys must be in camelCase.")
    var configPath: String?

    func run() throws {
        let fileManager = FileManager.default

        let cliRawConfig = CLIPinpillArguments(command: self)
        let jsonRawConfig: JSONPinpillArguments?
        if let configPathUnwrapped = configPath {
            jsonRawConfig = readArgumentsFromFile(fileManager: fileManager, path: configPathUnwrapped)
        } else {
            jsonRawConfig = nil
        }

        let config = try PinpillConfiguration.fromRawConfig(baseConfig: jsonRawConfig, overrideConfig: cliRawConfig)
        Logger.info(msg: "Starting pinpill with configuration:")
        Logger.info(msg: config.toJSON())
        let pinpill = Pinpill(config: config)

        DispatchQueue.main.async {
            pinpill.start()
            Self.exit()
        }

        signal(SIGINT, SIG_IGN)
        let sigintSrc = DispatchSource.makeSignalSource(signal: SIGINT)
        sigintSrc.setEventHandler {
            Logger.warning(msg: "Intercepted SIGINT")
            pinpill.interrupt()
        }
        sigintSrc.activate()

        signal(SIGTERM, SIG_IGN)
        let sigtermSrc = DispatchSource.makeSignalSource(signal: SIGTERM)
        sigtermSrc.setEventHandler {
            Logger.warning(msg: "Intercepted SIGTERM")
            pinpill.terminate()
        }
        sigtermSrc.activate()

        dispatchMain()
    }

    func readArgumentsFromFile(fileManager: FileManager, path: String) -> JSONPinpillArguments? {
        let configURL = URL(fileURLWithPath: path)
        if (!fileManager.fileExists(atPath: configURL.path)) {
            Logger.error(msg: "Config file not found at path \(configURL.path)")
            return nil
        }
        let decoder = JSONDecoder()
        do {
            let jsonArgs = try decoder.decode(JSONPinpillArguments.self, from: Data(contentsOf: configURL))
            Logger.verbose(msg: "Parsed arguments from file:")
            Logger.verbose(msg: jsonArgs.toJSON())
            return jsonArgs
        } catch {
            Logger.error(msg: "Failed to decode arguments from file at \(path).")
            return nil
        }
    }
}
