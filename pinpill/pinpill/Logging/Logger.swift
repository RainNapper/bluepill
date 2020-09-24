//
//  Logger.swift
//  pinpill
//
//  Created by Mansfield Mark on 8/12/20.
//  Copyright © 2020 Pinterest. All rights reserved.
//

import Foundation

class Logger {
    enum Severity: String, Comparable {
        case verbose = "V"
        case info = "I"
        case warning = "W"
        case error = "E"
        
        func compareValue() -> Int {
            switch(self) {
            case .verbose:
                return 1
            case .info:
                return 2
            case .warning:
                return 3
            case .error:
                return 4
            }
        }
        
        static func < (lhs:Self, rhs:Self) -> Bool{
            return lhs.compareValue() < rhs.compareValue()
        }
    }
    
    static let TAG = "Pinpill"
    static var severity: Severity = .info
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SS"
        return formatter
    }()
    
    static func verbose(msg: String) {
        if (severity > .verbose) {
            return
        }
        log(severity: .verbose, msg: msg)
    }
    
    static func info(msg: String) {
        if (severity > .info) {
            return
        }
        log(severity: .info, msg: msg)
    }
    
    static func warning(msg: String) {
        if (severity > .warning) {
            return
        }
        log(severity: .warning, msg: msg)
    }
    
    static func error(msg: String) {
        if (severity > .error) {
            return
        }
        log(severity: .error, msg: msg)
    }
    
    static func log(severity: Severity, msg: String) {
        print("\(dateFormatter.string(from: Date.init())) - \(severity.rawValue)/[\(TAG)] \(msg)")
    }
}
