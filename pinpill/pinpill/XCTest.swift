//
//  XCTestRun.swift
//  pinpill
//
//  Created by Mansfield Mark on 5/29/20.
//  Copyright © 2020 Pinterest. All rights reserved.
//

import Foundation

class XCTest {
    enum XCTestRunError: Error {
        case missingXCTestRun
        case invalidXCTestRun
        case failToReadXCTestRun
        case missingTestHostPath
        case missingTestBundlePath
    }

    static let TESTROOT = "__TESTROOT__"
    static let TESTHOST = "__TESTHOST__"
    static let PLATFORMS = "__PLATFORMS__"
    static let TEST_HOST_PATH = "TestHostPath"
    static let TEST_BUNDLE_PATH = "TestBundlePath"
    static let TEST_HOST_BUNDLE_IDENTIFIER = "TestHostBundleIdentifier"
    static let UI_TARGET_APP_PATH = "UITargetAppPath"
    static let COMMAND_LINE_ARGUMENTS = "CommandLineArguments"
    static let ENVIRONMENT_VARIABLES = "EnvironmentVariables"
    static let DYLD_LIBRARY_PATH = "DYLD_LIBRARY_PATH"
    static let SKIP_TEST_IDENTIFIERS = "SkipTestIdentifiers"

    let name: String
    let testHostURL: URL
    let testBundleURL: URL
    let uiTargetAppURL: URL?
    let testHostBundleIdentifier: String?
    let commandLineArguments: [String]
    let environment: [String: String]
    let skipTestIdentifiers: [String]
    let testClasses: Set<TestMethod>

    init(name: String,
         testHostURL: URL,
         testBundleURL: URL,
         uiTargetAppURL: URL?,
         testHostBundleIdentifier: String?,
         commandLineArguments: [String],
         environment: [String: String],
         skipTestIdentifiers: [String],
         testClasses: Set<TestMethod>) {
        self.name = name
        self.testHostURL = testHostURL
        self.testBundleURL = testBundleURL
        self.uiTargetAppURL = uiTargetAppURL
        self.testHostBundleIdentifier = testHostBundleIdentifier
        self.commandLineArguments = commandLineArguments
        self.environment = environment
        self.skipTestIdentifiers = skipTestIdentifiers
        self.testClasses = testClasses
    }

    var appBundleURL: URL { uiTargetAppURL ?? testHostURL }
    var testRunnerAppURL: URL? { uiTargetAppURL != nil ? testHostURL : nil }

    static func getClassesInXCTest(xcTestURL: URL) -> Set<TestMethod> {
        let xcTestObjectURL = xcTestURL.appendingPathComponent(xcTestURL.deletingPathExtension().lastPathComponent)
        let objCSymbols = extractObjCTestSymbols(xcTestObjectURL: xcTestObjectURL)
        let swiftSymbols = extractSwiftTestSymbols(xcTestObjectURL: xcTestObjectURL)
        let symbols = objCSymbols + swiftSymbols

        // Ignore colons because test methods do not have arguments
        let symbolsWithoutArgs = symbols.filter { !$0.contains(":") }
        let classAndMethod = symbolsWithoutArgs
            // Class and method are separated by space
            .map { $0.split(separator: " ") }
            // Just ensure that there is only class and method
            .filter { $0.count == 2 }

        let testMethods = classAndMethod.map { TestMethod(testClass: String($0[0]), method: String($0[1])) }
        return Set(testMethods)
    }

    static func extractSwiftTestSymbols(xcTestObjectURL: URL) -> [String] {
        let shell = Shell()
        let nmTask = shell.launchWaitAndGetOutput(
            cmd: Shell.kBinNm,
            args: ["-gU", xcTestObjectURL.path]
        )
        let mangledSymbols = nmTask.stdOut
            .split(separator: "\n")
            .map { $0.split(separator: " ") }
            .filter { $0.count >= 3 }
            .map { String($0[2]) }
        let demangleTask = shell.launchWaitAndGetOutput(cmd: Shell.kBinXcRun, args: ["swift-demangle"] + mangledSymbols)
        let symbols = demangleTask.stdOut
            .split(separator: "\n")
            .map { $0.split(separator: " ") }
            .filter { $0.count >= 3 }
            .map { String($0[2]) }
        // This does not actually match the last step of the bluepill regex, and will probably break somewhere
        // nm -gU '%@' | cut -d' ' -f3 | xargs -s 131072 xcrun swift-demangle | cut -d' ' -f3 | grep -e '[\\.|_]'test
        let testSymbols = symbols.filter { $0.contains("test") }
        return testSymbols
    }

    static func extractObjCTestSymbols(xcTestObjectURL: URL) -> [String] {
        let shell = Shell()
        let nmTask = shell.launchWaitAndGetOutput(
            cmd: Shell.kBinNm,
            args: ["-U", xcTestObjectURL.path]
        )
        let symbols = nmTask.stdOut
            .split(separator: "\n")
            .filter { $0.contains(" t ") }
            .compactMap { (symbolLine) -> String? in
                if let range = symbolLine.range(of: "\\[.*\\]", options: .regularExpression) {
                    return String(symbolLine[range]).replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "")
                } else {
                    return nil
                }
            }.filter { $0.contains("test") }
        return symbols
    }

    static func readXCTestRun(atURL: URL) throws -> Any {
        guard let inputStream = InputStream(url: atURL) else {
            throw XCTestRunError.missingXCTestRun
        }

        defer {
            inputStream.close()
        }
        inputStream.open()
        do {
            return try PropertyListSerialization.propertyList(with: inputStream, format: nil)
        } catch {
            print("Failed to deserialize xctestrun at path \(atURL.absoluteString): \(error)")
            throw XCTestRunError.failToReadXCTestRun
        }
    }

    static func buildXCTestFromXCTestRunConfig(name: String, config: [String: Any], testRootURL: URL, xcodeURL: URL) throws -> XCTest {
        guard let testHostPath = (config[TEST_HOST_PATH] as? String)?.replacingOccurrences(of: "__TESTROOT__", with: testRootURL.path) else {
            throw XCTestRunError.missingTestHostPath
        }

        let testHostURL = URL(fileURLWithPath: testHostPath, relativeTo: URL(fileURLWithPath: FileManager.default.currentDirectoryPath))
        guard let testBundlePathRaw = config[TEST_BUNDLE_PATH] as? String else {
            throw XCTestRunError.missingTestBundlePath
        }

        let testBundlePath = testBundlePathRaw
            .replacingOccurrences(of: TESTHOST, with: testHostPath)
            .replacingOccurrences(of: TESTROOT, with: testRootURL.path)
            .replacingOccurrences(of: PLATFORMS, with: xcodeURL.appendingPathComponent("Platforms").path)
        let testBundleURL = URL(fileURLWithPath: testBundlePath)

        let uiAppTargetPath = (config[UI_TARGET_APP_PATH] as? String)?.replacingOccurrences(of: TESTROOT, with: testRootURL.path)
        let uiAppTargetURL: URL?
        if let uiAppTargetPathUnwrapped = uiAppTargetPath {
            uiAppTargetURL = URL(fileURLWithPath: uiAppTargetPathUnwrapped)
        } else {
            uiAppTargetURL = nil
        }

        let testHostBundleIdentifier = config[TEST_HOST_BUNDLE_IDENTIFIER] as? String
        let commandLineArguments = config[COMMAND_LINE_ARGUMENTS] as? [String] ?? []

        var environment = config[ENVIRONMENT_VARIABLES] as? [String: String] ?? [:]
        environment.removeValue(forKey: DYLD_LIBRARY_PATH)

        let skipTestIdentifiers = config[SKIP_TEST_IDENTIFIERS] as? [String] ?? []

        return XCTest(
            name: name,
            testHostURL: testHostURL,
            testBundleURL: testBundleURL,
            uiTargetAppURL: uiAppTargetURL,
            testHostBundleIdentifier: testHostBundleIdentifier,
            commandLineArguments: commandLineArguments,
            environment: environment,
            skipTestIdentifiers: skipTestIdentifiers,
            testClasses: getClassesInXCTest(xcTestURL: testBundleURL)
        )
    }

    static func fromXCTestRun(xcTestRunURL: URL, testRootURL: URL, xcodeURL: URL) throws -> [XCTest] {
        let testSuiteToConfig: [String: Any] = try readXCTestRun(atURL: xcTestRunURL) as! [String: Any]
        let testSuites: [(name: String, config: [String: Any])] = testSuiteToConfig.map { key, value in (name: key, config: value as! [String: Any]) }.sorted { $0.name < $1.name }
        return testSuites.compactMap { testSuite in
            do {
                return try buildXCTestFromXCTestRunConfig(name: testSuite.name, config: testSuite.config, testRootURL: testRootURL, xcodeURL: xcodeURL)
            } catch {
                Logger.warning(msg: "Failed to build XCTest from config for suite \(testSuite.name): \(error)")
                return nil
            }
        }
    }
}
