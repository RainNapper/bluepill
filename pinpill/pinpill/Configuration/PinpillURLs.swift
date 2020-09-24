//
//  Bundles.swift
//  pinpill
//
//  Created by Mansfield Mark on 5/31/20.
//  Copyright © 2020 Pinterest. All rights reserved.
//

import Foundation

class PinpillURLs: Codable {
    let testBundleURL: URL
    let appBundleURL: URL
    let xcTestRunURL: URL
    let testRootURL: URL
    let xcodeURL: URL
    let bpURL: URL
    let outputURL: URL
    let simulatorPreferencesURL: URL

    let simulatorURL: URL

    init(fileManager: FileManager, testBundleURL: URL, appBundleURL: URL, xcTestRunURL: URL, xcodeURL: URL, bpURL: URL, outputURL: URL, simulatorPreferencesURL: URL) {
        precondition(fileManager.fileExists(atPath: testBundleURL.path), "Test bundle not found at path \(testBundleURL.path)")
        self.testBundleURL = testBundleURL

        precondition(fileManager.fileExists(atPath: appBundleURL.path), "App bundle not found at path \(appBundleURL.path)")
        self.appBundleURL = appBundleURL

        precondition(fileManager.fileExists(atPath: xcTestRunURL.path), ".xctestrun not found at path \(xcTestRunURL.path)")
        self.xcTestRunURL = xcTestRunURL

        precondition(fileManager.fileExists(atPath: xcodeURL.path), "xcode not found at path \(xcodeURL.path)")
        self.xcodeURL = xcodeURL

        precondition(fileManager.fileExists(atPath: bpURL.path), "bp executable not found at path \(bpURL.path)")
        self.bpURL = bpURL

        // Don't verify this exists because bp will create it for us if it's missing.
        self.outputURL = outputURL

        precondition(fileManager.fileExists(atPath: simulatorPreferencesURL.path), "simulator preferences not found at path \(simulatorPreferencesURL.path)")
        self.simulatorPreferencesURL = simulatorPreferencesURL

        testRootURL = xcTestRunURL.deletingLastPathComponent()
        simulatorURL = xcodeURL.appendingPathComponent("/Applications/Simulator.app/Contents/MacOS/Simulator")
    }

    func findXCTestURLs() -> [URL] {
        let pluginsURL = testBundleURL.appendingPathComponent("PlugIns")
        let pluginURLs: [URL]
        do {
            pluginURLs = try FileManager.default.contentsOfDirectory(at: pluginsURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants, .skipsSubdirectoryDescendants])
        } catch {
            print("Error occurred searching for xctests in URL \(pluginsURL.absoluteString): \(error)")
            return []
        }

        return pluginURLs.filter { $0.pathExtension == "xctest" }
    }
}
