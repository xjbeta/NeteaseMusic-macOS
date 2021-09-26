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
    
    
    static func verbose(_ item: Any) {
        DDLogVerbose(item)
    }
    
    static func debug(_ item: Any) {
        DDLogDebug(item)
    }
    
    static func info(_ item: Any) {
        DDLogInfo(item)
    }
    
    static func warn(_ item: Any) {
        DDLogWarn(item)
    }
    
    static func error(_ item: Any) {
        DDLogError(item)
    }
}
