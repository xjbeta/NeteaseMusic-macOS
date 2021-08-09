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
    
    func setupRemoteCommandCenter() {
        let rcCenter = remoteCommandCenter
        rcCenter.playCommand.addTarget { _ in
            self.togglePlayPause()
            return .success
        }
        rcCenter.pauseCommand.addTarget { _ in
            self.togglePlayPause()
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
        rcCenter.changePlaybackRateCommand.supportedPlaybackRates = [0.5, 0.75, 1, 1.25, 1.5, 1.75, 2]
        
        rcCenter.changePlaybackRateCommand.addTarget { event in
            guard let rate = (event as? MPChangePlaybackRateCommandEvent)?.playbackRate else {
                return .commandFailed
            }
            self.player.activeStream.setPlayRate(rate)
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
            let time = (event as! MPChangePlaybackPositionCommandEvent).positionTime
            var pos = FSStreamPosition()
            pos.playbackTimeInSeconds = Float(time)
            self.player.activeStream.seek(to: pos)
            return .success
        }
    }
    
    func updateNowPlayingState(_ state: MPNowPlayingPlaybackState) {
        nowPlayingInfoCenter.playbackState = state
    }
    
    func updateNowPlayingInfo() {
        var info = [String: Any]()
        guard Preferences.shared.useSystemMediaControl,
              let track = currentTrack else {
            nowPlayingInfoCenter.nowPlayingInfo = [:]
            updateNowPlayingState(.unknown)
            return
        }
        
        info[MPMediaItemPropertyMediaType] = MPNowPlayingInfoMediaType.audio.rawValue
        info[MPMediaItemPropertyTitle] = track.name
        info[MPMediaItemPropertyAlbumTitle] = track.album.name
        info[MPMediaItemPropertyArtist] = track.artistsString
        
        info[MPMediaItemPropertyPlaybackDuration] = track.duration / 1000
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        
//        info[MPNowPlayingInfoPropertyPlaybackRate] = player.activeStream.setPlayRate(_:)
        info[MPNowPlayingInfoPropertyDefaultPlaybackRate] = 1
        
        
        
        if !nowPlayingCoverInited,
           let appIcon = NSApp.applicationIconImage {
            info[MPMediaItemPropertyArtwork] =
                MPMediaItemArtwork(boundsSize: .init(width: 512, height: 512)) {
                    let w = Int($0.width * (NSScreen.main?.backingScaleFactor ?? 1))
                    guard var str = track.album.picUrl?.absoluteString else {
                        return appIcon
                    }
                    str += "?param=\(w)y\(w)"
                    guard let imageU = URL(string: str),
                        let image = NSImage(contentsOf: imageU) else {
                            return appIcon
                    }
                    self.nowPlayingCoverInited = true
                    return image
            }
        } else {
            info[MPMediaItemPropertyArtwork] = nowPlayingInfoCenter.nowPlayingInfo?[MPMediaItemPropertyArtwork]
        }
        
        nowPlayingInfoCenter.nowPlayingInfo = info
    }
}
