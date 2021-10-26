//
//  Log.swift
//  NeteaseMusic
//
//  Created by xjbeta on 9/26/21.
//  Copyright © 2021 xjbeta. All rights reserved.
//

import Cocoa
import CocoaLumberjackSwift


enum Log {
    static func setUp() {
        DDLog.add(DDOSLogger.sharedInstance) // Uses os_log
        DDOSLogger.sharedInstance.logFormatter = LogFormatter()
        
        if let logger = DDTTYLogger.sharedInstance {
            DDLog.add(logger)
            logger.logFormatter = LogFormatter()
        }
        
        let fileLogger = DDFileLogger() // File Logger
        
        fileLogger.doNotReuseLogFiles = true
        fileLogger.rollingFrequency = 60 * 60 * 24 // 24 hours
        fileLogger.logFileManager.maximumNumberOfLogFiles = 25
        
        DDLog.add(fileLogger)
        fileLogger.logFormatter = LogFormatter()
        
    }

    @inlinable
    static func verbose(_ message: @autoclosure () -> Any, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
       DDLogVerbose(message(), file: file, function: function, line: line)
    }

    @inlinable
    static func debug(_ message: @autoclosure () -> Any, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
       DDLogDebug(message(), file: file, function: function, line: line)
    }

    @inlinable
    static func info(_ message: @autoclosure () -> Any, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
       DDLogInfo(message(), file: file, function: function, line: line)
    }

    @inlinable
    static func warn(_ message: @autoclosure () -> Any, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
       DDLogWarn(message(), file: file, function: function, line: line)
    }

    @inlinable
    static func error(_ message: @autoclosure () -> Any, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
       DDLogError(message(), file: file, function: function, line: line)
    }
}

class LogFormatter: DDDispatchQueueLogFormatter {
    let dateFormatter: DateFormatter
    
    override init() {
        dateFormatter = DateFormatter()
        dateFormatter.formatterBehavior = .behavior10_4
        dateFormatter.dateFormat = "HH:mm:ss:SSS"
        
        super.init()
    }
    
    override func format(message logMessage: DDLogMessage) -> String? {
        let dateAndTime = dateFormatter.string(from: logMessage.timestamp)
        
        var file = [logMessage.fileName, "\(logMessage.line)"]
        if let f = logMessage.function {
            file.append(f)
        }
        
        return "\(dateAndTime) [\(file.joined(separator: ":"))]: \(logMessage.message)"
    }
}
