//
//  PlayCoreMediaKeysExtension.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/11/17.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa
import MediaPlayer

extension PlayCore {
    
    func initMediaKeysObservers() {
        playerStateObserver = player.observe(\.rate, options: [.initial, .new]) { player, _ in
            self.updateNowPlayingState(player.rate == 0 ? .paused : .playing)
        }
        playingInfoObserver = player.observe(\.currentItem, options: [.initial, .new]) { player, _ in
            self.updateNowPlayingInfo()
        }
    }
    
    func deinitMediaKeysObservers() {
        playerStateObserver?.invalidate()
        playingInfoObserver?.invalidate()
    }
    
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
        rcCenter.changePlaybackPositionCommand.addTarget { event in
            let d = (event as! MPChangePlaybackPositionCommandEvent).positionTime
            let time = CMTime(seconds: d, preferredTimescale: 1000)
            self.player.seek(to: time) { _ in }
            return .success
        }
    }
    
    func updateNowPlayingState(_ state: MPNowPlayingPlaybackState) {
        nowPlayingInfoCenter.playbackState = state
    }
    
    func updateNowPlayingInfo() {
        var info = [String: Any]()
        guard let track = fmMode ? currentFMTrack : currentTrack else {
            nowPlayingInfoCenter.nowPlayingInfo = [:]
            updateNowPlayingState(.unknown)
            return
        }
        
        info[MPMediaItemPropertyMediaType] = MPNowPlayingInfoMediaType.audio.rawValue
        info[MPMediaItemPropertyTitle] = track.name
        info[MPMediaItemPropertyAlbumTitle] = track.album.name
        info[MPMediaItemPropertyArtist] = track.artistsString
        
        info[MPMediaItemPropertyPlaybackDuration] = track.duration / 1000
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime().seconds
        
        info[MPNowPlayingInfoPropertyPlaybackRate] = player.rate
        info[MPNowPlayingInfoPropertyDefaultPlaybackRate] = 1
        
        info[MPMediaItemPropertyArtwork] =
        MPMediaItemArtwork(boundsSize: .init(width: 512, height: 512)) {
            let w = Int($0.width * (NSScreen.main?.backingScaleFactor ?? 1))
            guard var str = track.album.picUrl?.absoluteString else {
                return NSApp.applicationIconImage
            }
            str += "?param=\(w)y\(w)"
            guard let imageU = URL(string: str),
                let image = NSImage(contentsOf: imageU) else {
                return NSApp.applicationIconImage
            }
            return image
        }
        
        nowPlayingInfoCenter.nowPlayingInfo = info
    }
}
