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
    
    var rows: [Row] = []
    
    struct Row: Encodable {
        let pass: Bool;
        let numActiveTasks: Int;
        let taskDescription: String;
    }
    
    public func log(pass: Bool, numActiveTasks: Int, taskDescription: String) {
        rows.append(Row(pass: pass, numActiveTasks: numActiveTasks, taskDescription: taskDescription))
    }
    
    public func save(toFolderURL: URL) {
        let outputURL = toFolderURL.appendingPathComponent(Self.kOutputFile)
        do {
            try rows.toJSON().data(using: .utf8)!.write(to: outputURL)
        } catch {
            Logger.error(msg: "Failed to write metric output file to \(outputURL):  \(error)")
        }
    }
}
