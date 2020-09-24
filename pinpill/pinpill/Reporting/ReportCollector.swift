//
//  ReportCollector.swift
//  pinpill
//
//  Created by Mansfield Mark on 6/16/20.
//  Copyright © 2020 Pinterest. All rights reserved.
//

import Foundation

class ReportCollector {
    let fileManager: FileManager

    init(fileManager: FileManager) {
        self.fileManager = fileManager
    }

    func collectReports(root: URL) {
        let reports = listReportsAtURL(root: root)
        Logger.verbose(msg: "Found reports:\n\(reports.map { $0.path }.joined(separator: "\n"))")
        let cases = reports.flatMap { getTestCases(report: $0) }

        let reportTree = ReportTree()
        for testCase in cases {
            reportTree.addCase(testCase: testCase)
        }

        let finalReportURL = root.appendingPathComponent("TEST-FinalReport.xml", isDirectory: false)
        Logger.info(msg: "Writing final report to \(finalReportURL.path)")
        reportTree.printTree()
        do {
            try reportTree.writeToXML(url: finalReportURL)
        } catch {
            Logger.error(msg: "Failed to write final XML report: \(error)")
        }
    }

    func listReportsAtURL(root: URL) -> [URL] {
        let enumerator = fileManager.enumerator(at: root, includingPropertiesForKeys: [])
        return enumerator?
            .compactMap { item -> URL? in
                switch item {
                case let fileURL as URL:
                    return fileURL
                default:
                    return nil
                }
            }
            .filter { url in url.pathExtension == "xml" }
            ?? []
    }

    func getTestCases(report: URL) -> [ReportTree.TestCase] {
        do {
            let document = try XMLDocument(contentsOf: report)
            return try document
                .nodes(forXPath: "//\(ReportTree.kElementTestCase)")
                .compactMap {
                    node -> ReportTree.TestCase? in
                    switch node {
                    case let element as XMLElement:
                        return ReportTree.TestCase(element: element)
                    default:
                        return nil
                    }
                }
        } catch {
            return []
        }
    }
}
