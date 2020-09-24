//
//  Metrics.swift
//  pinpill
//
//  Created by Mansfield Mark on 8/12/20.
//  Copyright © 2020 Pinterest. All rights reserved.
//

import Foundation

class Metrics {
    let concurrency = ConcurrencyMetric()
    
    let outputURL: URL
    
    init(outputRootURL: URL) {
        self.outputURL = outputRootURL.appendingPathComponent("metrics")
        try! FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)
    }
    
    func save() {
        concurrency.save(toFolderURL: outputURL)
    }
}
