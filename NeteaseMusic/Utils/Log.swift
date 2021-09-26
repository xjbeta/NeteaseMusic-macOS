//
//  Log.swift
//  NeteaseMusic
//
//  Created by xjbeta on 9/26/21.
//  Copyright © 2021 xjbeta. All rights reserved.
//

import Cocoa
import CocoaLumberjackSwift

class Log: NSObject {
    static func initLog() {
        DDLog.add(DDOSLogger.sharedInstance) // Uses os_log
        if let logger = DDTTYLogger.sharedInstance {
            DDLog.add(logger)
        }
        
        
        let fileLogger = DDFileLogger() // File Logger
        
        
        fileLogger.rollingFrequency = 60 * 60 * 24 // 24 hours
        fileLogger.logFileManager.maximumNumberOfLogFiles = 7
        DDLog.add(fileLogger)

    
//        DDLogVerbose("Verbose")
//        DDLogDebug("Debug")
//        DDLogInfo("Info")
//        DDLogWarn("Warn")
//        DDLogError("Error")
        
        
    }
    
    
    static func verbose(_ str: String) {
        DDLogVerbose(str)
    }
    
    static func debug(_ str: String) {
        DDLogDebug(str)
    }
    
    static func info(_ str: String) {
        DDLogInfo(str)
    }
    
    static func warn(_ str: String) {
        DDLogWarn(str)
    }
    
    static func error(_ str: String) {
        DDLogError(str)
    }
}
