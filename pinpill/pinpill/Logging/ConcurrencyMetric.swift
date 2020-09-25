//
//  Metric.swift
//  pinpill
//
//  Created by Mansfield Mark on 8/12/20.
//  Copyright © 2020 Pinterest. All rights reserved.
//

import Foundation

class ConcurrencyMetric {
    static let kOutputFile = "concurrency.json";
    
    private let rowDispatchQueue: DispatchQueue
    
    var rows: [Row] = []
    
    struct Row: Encodable {
        let pass: Bool;
        let numActiveTasks: Int;
        let taskDescription: String;
    }
    
    init() {
        rowDispatchQueue = DispatchQueue(label: "pinpill-metric-concurrency-rows")
    }
    
    public func log(pass: Bool, numActiveTasks: Int, taskDescription: String) {
        rowDispatchQueue.sync {
            rows.append(Row(pass: pass, numActiveTasks: numActiveTasks, taskDescription: taskDescription))
        }
    }
    
    public func save(toFolderURL: URL) {
        let outputURL = toFolderURL.appendingPathComponent(Self.kOutputFile)
        do {
            var rowJson: String? = nil;
            rowDispatchQueue.sync {
                rowJson = rows.toJSON();
            }
            try rowJson!.data(using: .utf8)!.write(to: outputURL)
        } catch {
            Logger.error(msg: "Failed to write metric output file to \(outputURL):  \(error)")
        }
    }
}
