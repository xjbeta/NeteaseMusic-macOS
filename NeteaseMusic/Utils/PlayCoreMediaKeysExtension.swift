//
//  PlayCoreMediaKeysExtension.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/11/17.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa
import MediaPlayer
import SDWebImage

extension PlayCore {
    
    func setupRemoteCommandCenter() {
        let rcCenter = remoteCommandCenter
        rcCenter.playCommand.addTarget { _ in
            self.player.play()
            return .success
        }
        rcCenter.pauseCommand.addTarget { _ in
            self.player.pause()
            return .success
        }
        rcCenter.togglePlayPauseCommand.addTarget { _ in
            self.togglePlayPause()
            return .success
        }
        rcCenter.stopCommand.addTarget { _ in
            self.stop()
            return .success
        }
        rcCenter.nextTrackCommand.addTarget { _ in
            self.nextSong()
            return .success
        }
        rcCenter.previousTrackCommand.addTarget { _ in
            self.previousSong()
            return .success
        }
        rcCenter.changeRepeatModeCommand.addTarget { _ in
            self.toggleRepeatMode()
            return .success
        }
        rcCenter.changeShuffleModeCommand.isEnabled = false
        rcCenter.changeShuffleModeCommand.addTarget { _ in
            self.toggleShuffleMode()
            return .success
        }
        rcCenter.changePlaybackRateCommand.supportedPlaybackRates = [0.25, 0.5, 0.75, 1]
        
        rcCenter.changePlaybackRateCommand.addTarget { event in
            self.player.rate = (event as! MPChangePlaybackRateCommandEvent).playbackRate
            return .success
        }
        rcCenter.seekForwardCommand.addTarget { event in
            let timer = self.seekTimer
            switch (event as! MPSeekCommandEvent).type {
            case .beginSeeking:
                timer.schedule(deadline: .now(), repeating: .seconds(1))
                timer.setEventHandler {
                    self.seekForward(5)
                }
                timer.resume()
            case .endSeeking:
                timer.suspend()
            @unknown default:
                return .commandFailed
            }
            return .success
        }
        
        rcCenter.seekBackwardCommand.addTarget { event in
            let timer = self.seekTimer
            switch (event as! MPSeekCommandEvent).type {
            case .beginSeeking:
                timer.schedule(deadline: .now(), repeating: .seconds(1))
                timer.setEventHandler {
                    self.seekBackward(5)
                }
                timer.resume()
            case .endSeeking:
                timer.suspend()
            @unknown default:
                return .commandFailed
            }
            return .success
        }
        rcCenter.changePlaybackPositionCommand.addTarget { event in
            let d = (event as! MPChangePlaybackPositionCommandEvent).positionTime
            let time = CMTime(seconds: d, preferredTimescale: 1000)
            self.player.seek(to: time) { _ in
                self.updateNowPlayingInfo()
            }
            return .success
        }
        
        /*
        rcCenter.skipForwardCommand.preferredIntervals = [5]
        rcCenter.skipForwardCommand.addTarget { event in
            self.seekForward((event as! MPSkipIntervalCommandEvent).interval)
            return .success
        }
        rcCenter.skipBackwardCommand.preferredIntervals = [5]
        rcCenter.skipBackwardCommand.addTarget { event in
            self.seekBackward((event as! MPSkipIntervalCommandEvent).interval)
            return .success
        }
         */
    }
    
    func updateNowPlayingState(_ state: MPNowPlayingPlaybackState) {
        nowPlayingInfoCenter.playbackState = state
    }
    
    func initNowPlayingInfo() {
        guard let track = currentTrack,
              let appIcon = NSApp.applicationIconImage else {
            nowPlayingInfoCenter.nowPlayingInfo = nil
            updateNowPlayingState(.unknown)
            return
        }
        
        var info = [String: Any]()
        
        info[MPNowPlayingInfoPropertyMediaType] = MPNowPlayingInfoMediaType.audio.rawValue
        info[MPMediaItemPropertyTitle] = track.name
        info[MPMediaItemPropertyArtist] = track.artistsString
        
        info[MPMediaItemPropertyAlbumArtist] = track.album.artists?.artistsString
        info[MPMediaItemPropertyAlbumTitle] = track.album.name
        
        info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: .init(width: 512, height: 512)) {
            
            guard let u = track.album.picUrl?.absoluteString.appending("?param=\(Int($0.width))y\(Int($0.height))"),
                  let url = URL(string: u),
                  let key = ImageLoader.key(url) else {
                return appIcon
            }
            
            let path = SDImageCache.shared.cachePath(forKey: u)
            if let image = SDImageCache.shared.imageFromMemoryCache(forKey: key) {
                return image
            } else if let image = NSImage(contentsOf: url) {
                SDImageCache.shared.store(image, forKey: key, completion: nil)
                return image
            } else {
                return appIcon
            }
        }
        nowPlayingInfoCenter.nowPlayingInfo = nil
        nowPlayingInfoCenter.nowPlayingInfo = info
    }
    
    func updateNowPlayingInfo() {
        guard let track = currentTrack,
              nowPlayingInfoCenter.nowPlayingInfo?[MPMediaItemPropertyTitle] as? String == track.name else {
            return
        }
        
        var info = nowPlayingInfoCenter.nowPlayingInfo ?? [:]
        info[MPMediaItemPropertyPlaybackDuration] = track.duration / 1000
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentDuration
        
        info[MPNowPlayingInfoPropertyPlaybackRate] = player.rate
        info[MPNowPlayingInfoPropertyDefaultPlaybackRate] = 1
        nowPlayingInfoCenter.nowPlayingInfo = info
    }
}
