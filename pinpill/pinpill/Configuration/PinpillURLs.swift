//
//  Bundles.swift
//  pinpill
//
//  Created by Mansfield Mark on 5/31/20.
//  Copyright © 2020 Pinterest. All rights reserved.
//

import Foundation

class PinpillURLs: Codable {
    enum PinpillURLError: Error {
        case fileNotFoundError(String)
    }
    
    let testBundleURL: URL
    let appBundleURL: URL
    let xcTestRunURL: URL
    let testRootURL: URL
    let xcodeURL: URL
    let bpURL: URL
    let outputURL: URL
    let simulatorPreferencesURL: URL
    let simulatorURL: URL

    init(fileManager: FileManager, testBundleURL: URL, appBundleURL: URL, xcTestRunURL: URL, xcodeURL: URL, bpURL: URL, outputURL: URL, simulatorPreferencesURL: URL) throws {
        self.testBundleURL = testBundleURL
        self.appBundleURL = appBundleURL
        self.xcTestRunURL = xcTestRunURL
        self.xcodeURL = xcodeURL
        self.bpURL = bpURL
        self.outputURL = outputURL
        self.simulatorPreferencesURL = simulatorPreferencesURL
        testRootURL = xcTestRunURL.deletingLastPathComponent()
        simulatorURL = xcodeURL.appendingPathComponent("/Applications/Simulator.app/Contents/MacOS/Simulator")
        
        try checkExists(fileManager: fileManager, path: testBundleURL, description: "test bundle")
        try checkExists(fileManager: fileManager, path: appBundleURL, description: "app bundle")
        try checkExists(fileManager: fileManager, path: xcTestRunURL, description: ".xctestrun")
        try checkExists(fileManager: fileManager, path: testBundleURL, description: "xcode")
        try checkExists(fileManager: fileManager, path: bpURL, description: "bp executable")
        try checkExists(fileManager: fileManager, path: simulatorPreferencesURL, description: "simulator preferences")
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
    
    func checkExists(fileManager: FileManager, path: URL, description: String) throws {
        if(!fileManager.fileExists(atPath: path.path)) {
            throw PinpillURLError.fileNotFoundError("\(description) not found at path \(path)")
        }
    }
}
