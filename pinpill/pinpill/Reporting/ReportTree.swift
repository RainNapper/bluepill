//
//  ReportTree.swift
//  pinpill
//
//  Created by Mansfield Mark on 6/16/20.
//  Copyright © 2020 Pinterest. All rights reserved.
//

import Foundation

class ReportTree {
    static let kElementTestSuites = "testsuites"
    static let kElementTestSuite = "testsuite"
    static let kElementTestCase = "testcase"
    static let kElementFailure = "failure"
    static let kElementError = "error"

    static let kAttributeName = "name"
    static let kAttributeTests = "tests"
    static let kAttributeFailures = "failures"
    static let kAttributeErrors = "errors"
    static let kAttributeTime = "time"

    class TestSuite {
        let name: String
        let isRoot: Bool

        var suites: [String: TestSuite]
        var cases: [TestCase]
        var totals: (tests: Int, failures: Int, errors: Int, time: Double)

        init(name: String, isRoot: Bool = false) {
            self.name = name
            self.isRoot = isRoot
            suites = [:]
            cases = []
            totals = (0, 0, 0, 0.0)
        }

        func getOrAddSuite(name: String) -> TestSuite {
            if let existingSuite = suites[name] {
                return existingSuite
            } else {
                let newSuite = TestSuite(name: name)
                suites[name] = newSuite
                return newSuite
            }
        }

        func addCase(depth: Int, testCase: TestCase) {
            if depth == testCase.path.count {
                cases.append(testCase)
            } else {
                getOrAddSuite(name: testCase.path[depth])
                    .addCase(depth: depth + 1, testCase: testCase)
            }

            updateTotals(testCase: testCase)
        }

        func updateTotals(testCase: TestCase) {
            totals.tests += 1
            totals.time += testCase.time
            switch testCase.outcome {
            case .pass:
                break
            case .fail:
                totals.failures += 1
            case .error:
                totals.errors += 1
            }
        }

        func printSuite(depth: Int) {
            let spacing = String(repeating: "--", count: depth)
            print("\(spacing) \(name) \(totals)")
            for testCase in cases {
                testCase.printCase(depth: depth + 1)
            }
            for testSuite in suites.values {
                testSuite.printSuite(depth: depth + 1)
            }
        }

        func toXML() -> XMLElement {
            let element = buildEmptyElement(
                type: isRoot ? kElementTestSuites : kElementTestSuite,
                name: name, tests: totals.tests,
                failures: totals.failures,
                errors: totals.errors,
                time: totals.time
            )

            for suite in suites.values {
                element.addChild(suite.toXML())
            }

            for testCase in cases {
                element.addChild(testCase.element)
            }

            return element
        }
    }

    class TestCase {
        enum CaseOutcome {
            case pass
            case fail
            case error
        }

        let element: XMLElement
        let name: String
        let path: [String]
        let time: Double
        let outcome: CaseOutcome

        init(element: XMLElement) {
            precondition(element.name == kElementTestCase)
            self.element = element

            name = element.attribute(forName: kAttributeName)?.stringValue ?? "unknown"

            let children = element.children ?? []
            time = Double(element.attribute(forName: kAttributeTime)?.stringValue ?? "") ?? 0.0
            outcome =
                children.contains { $0.name == kElementFailure }
                    ? .fail
                    : (children.contains { $0.name == kElementError }
                        ? .error
                        : .pass)

            var pathBuilder: [String] = []
            var trav: XMLElement = element
            while let parentNode = trav.parent {
                if parentNode.name == kElementTestSuites {
                    break
                }

                precondition(
                    parentNode.name == kElementTestSuite,
                    "Expected only \(kElementTestSuite) parents for \(kElementTestCase). Instead found '\(parentNode.name ?? "missing tag name")'"
                )
                guard let parentElement = parentNode as? XMLElement else {
                    break
                }

                pathBuilder.insert(parentElement.attribute(forName: kAttributeName)?.stringValue ?? "", at: 0)
                trav = parentElement
            }
            path = pathBuilder
        }

        func printCase(depth: Int) {
            let spacing = String(repeating: "--", count: depth)
            print("\(spacing) \(name) \(time) \(outcome)")
        }
    }

    let rootSuite: TestSuite

    init() {
        rootSuite = TestSuite(name: "All tests", isRoot: true)
    }

    func addCase(testCase: TestCase) {
        rootSuite.addCase(depth: 0, testCase: testCase)
    }

    func printTree() {
        rootSuite.printSuite(depth: 0)
    }

    func writeToXML(url: URL) throws {
        let document = XMLDocument(rootElement: rootSuite.toXML())
        document.characterEncoding = "UTF-8"
        document.version = "1.0"
        document.isStandalone = true

        let data = document.xmlData(options: .nodePrettyPrint)
        try data.write(to: url)
    }

    class func buildEmptyElement(type: String, name: String, tests: Int, failures: Int, errors: Int, time: Double) -> XMLElement {
        let element = XMLElement()
        element.name = type
        element.addAttribute(XMLNode.attribute(withName: kAttributeName, stringValue: name) as! XMLNode)
        element.addAttribute(XMLNode.attribute(withName: kAttributeTests, stringValue: String(tests)) as! XMLNode)
        element.addAttribute(XMLNode.attribute(withName: kAttributeFailures, stringValue: String(failures)) as! XMLNode)
        element.addAttribute(XMLNode.attribute(withName: kAttributeErrors, stringValue: String(errors)) as! XMLNode)
        element.addAttribute(XMLNode.attribute(withName: kAttributeTime, stringValue: String(time)) as! XMLNode)
        return element
    }
}
