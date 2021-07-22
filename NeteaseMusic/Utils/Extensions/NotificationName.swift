//
//  NotificationName.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/4/12.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa
import Foundation

extension Notification.Name {
    static let showPlayingSong = Notification.Name("com.xjbeta.NeteaseMusic.ShowPlayingSong")
    static let playingSongViewStatus = Notification.Name("com.xjbeta.NeteaseMusic.PlayingSongViewStatus")
    static let selectSidebarItem = Notification.Name("com.xjbeta.NeteaseMusic.SelectSidebarItem")
    static let updateLoginStatus = Notification.Name("com.xjbeta.NeteaseMusic.UpdateLoginStatus")
    static let displayMessage = Notification.Name("com.xjbeta.NeteaseMusic.displayMessage")
    static let initSidebarPlaylists = Notification.Name("com.xjbeta.NeteaseMusic.initSidebarPlaylists")
}
