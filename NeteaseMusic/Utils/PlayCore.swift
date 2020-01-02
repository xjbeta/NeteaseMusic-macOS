//
//  PlayCore.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/3/31.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa
import MediaPlayer
import AVFoundation

class PlayCore: NSObject {
    static let shared = PlayCore()
    
    private override init() {
        player.automaticallyWaitsToMinimizeStalling = false
    }
    
    let remoteCommandCenter = MPRemoteCommandCenter.shared()
    let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
    
    let api = NeteaseMusicAPI()
    let player = AVPlayer()
    
    var playerShouldNextObserver: NSObjectProtocol?
    var playerStateObserver: NSKeyValueObservation?
    var playingInfoObserver: NSKeyValueObservation?
    
    let seekTimer = DispatchSource.makeTimerSource(flags: [], queue: .main)
    
    @objc dynamic var playlist: [Track] = []
    @objc dynamic var historys: [Track] = []
    
    @objc dynamic var currentTrack: Track?
    
    

    @objc dynamic var playedTracks = [Int]()
    var playedAlbums = [Int]()
    
    @objc dynamic var fmMode = false {
        didSet {
            if fmMode {
                // hide prevSong, repeatMode, shuffleMode, playlist
                
            }
        }
    }
    @objc dynamic var fmPlaylist: [Track] = []
    @objc dynamic var currentFMTrack: Track?
    private var fmSavedTime = (id: -1, time: CMTime())
    
    func start(_ index: Int = 0, enterFMMode: Bool = false) {
        if fmMode, !enterFMMode {
            fmSavedTime = (currentFMTrack?.id ?? -1, player.currentTime())
        }
        
        fmMode = enterFMMode
        
        removeObserver()
        playerShouldNextObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: .main) { _ in
            self.nextSong()
        }
        if fmMode {
            if let track = currentFMTrack {
                if fmSavedTime.id == track.id {
                    play(track, time: fmSavedTime.time)
                } else {
                    play(track)
                }
                fmSavedTime = (id: -1, time: CMTime())
            }
        } else {
            if let track = playlist[safe: index] {
                play(track)
            }
        }
    }
    
    func play(_ track: Track, time: CMTime = CMTime(value: 0, timescale: 1000)) {
        track.playerItemm().done {
            if self.fmMode {
                self.currentFMTrack = track
            } else {
                self.currentTrack = track
            }
            
            self.player.pause()
            self.player.replaceCurrentItem(with: $0)
            self.player.seek(to: time) {_ in
                self.player.play()
            }
            
            self.historys.removeAll {
                $0.id == track.id
            }
            self.historys.append(track)
            
            if self.historys.count > 100 {
                self.historys.removeFirst()
            }
            }.catch {
                print($0)
        }
    }
    
    func nextSong() {
        guard !fmMode else {
            guard let currentTrack = currentFMTrack,
                let index = fmPlaylist.firstIndex(of: currentTrack),
                let nextTrack = fmPlaylist[safe: index + 1] else { return }
            play(nextTrack)
            return
        }
        
        let repeatMode = Preferences.shared.repeatMode
        let shuffleMode = Preferences.shared.shuffleMode
        
        switch repeatMode {
        case .noRepeat, .repeatPlayList:
            guard let currentTrack = playlist.enumerated().first(where: { $0.element.id == currentTrack?.id }) else {
                print(playlist)
                print(player.currentItem)
                let t = "some thing wrong when break."
                break
            }
            playedTracks.append(currentTrack.element.id)
            
            switch shuffleMode {
            case .shuffleItems:
                if playlist.count == playedTracks.count, repeatMode == .repeatPlayList {
                    playedTracks.removeAll()
                }
                
                if let track = playlist.filter({ !playedTracks.contains($0.id) }).randomItem() {
                    play(track)
                }
            case .shuffleAlbums:
                break
            case .noShuffle:
                if currentTrack.offset + 1 == playlist.count {
                    // last track
                    if repeatMode == .repeatPlayList, let track = playlist.first {
                        play(track)
                    }
                } else {
                    // next track
                    if let track = playlist[safe: currentTrack.offset + 1] {
                        play(track)
                    }
                }
            }
        case .repeatItem:
            player.seek(to: CMTime(value: 0, timescale: 1000))
            player.play()
        }
    }
    
    func previousSong() {
        if fmMode {
            guard let currentTrack = currentFMTrack,
                let index = fmPlaylist.firstIndex(of: currentTrack),
                let prevTrack = fmPlaylist[safe: index - 1] else { return }
            play(prevTrack)
        } else {
            guard playedTracks.count > 0 else { return }
            if let id = playedTracks.last, let track = playlist.first(where: { $0.id == id }) {
                playedTracks.removeLast()
                play(track)
            }
        }
    }
    
    func removeObserver() {
        if let obs = playerShouldNextObserver {
            NotificationCenter.default.removeObserver(obs)
            playerShouldNextObserver = nil
        }
    }
    
    func playNow(_ tracks: [Track]) {
        print(tracks)
        
        
        if let currentTrack = currentTrack,
            let i = playlist.enumerated().filter({ $0.element == currentTrack }).first?.offset {
            playlist.insert(contentsOf: tracks, at: i + 1)
        } else {
            playlist.append(contentsOf: tracks)
        }
        if let t = tracks.first {
            play(t)
        }
    }
    
    func togglePlayPause() {
        guard player.error == nil else { return }
        func playOrPause() {
            if player.rate == 0 {
                player.play()
            } else {
                player.pause()
            }
        }
        if PlayCore.shared.fmMode, PlayCore.shared.currentFMTrack != nil {
            playOrPause()
        } else if !PlayCore.shared.fmMode, PlayCore.shared.currentTrack != nil {
            playOrPause()
        } else if let item = ViewControllerManager.shared.selectedSidebarItem?.type {
            switch item {
            case .fm:
                PlayCore.shared.start(enterFMMode: true)
            case .createdPlaylist, .subscribedPlaylist:
                let todo = "play playlist."
                break
            default:
                break
            }
        }
    }
    
    func increaseVolume() {
        var v = player.volume
        guard v < 1 else {
            return
        }
        v += 0.1
        player.volume = v >= 1 ? 1 : v
    }
    
    func decreaseVolume() {
        var v = player.volume
        guard v >= 0 else {
            player.volume = 0
            return
        }
        v -= 0.1
        player.volume = v < 0 ? 0 : v
    }
    
    func stop() {
        player.pause()
        player.replaceCurrentItem(with: nil)
        if fmMode {
            currentFMTrack = nil
        } else {
            currentTrack = nil
        }
    }
    
    func toggleRepeatMode() {
        print(#function)
    }
    
    func toggleShuffleMode() {
        print(#function)
    }
    
    func seekForward(_ seconds: Double) {
        let lhs = player.currentTime()
        let rhs = CMTimeMakeWithSeconds(5, preferredTimescale: 1)
        let t = CMTimeAdd(lhs, rhs)
        player.seek(to: t)
    }
    
    func seekBackward(_ seconds: Double) {
        let lhs = player.currentTime()
        let rhs = CMTimeMakeWithSeconds(-5, preferredTimescale: 1)
        let t = CMTimeAdd(lhs, rhs)
        player.seek(to: t)
    }
    
    func setupSystemMediaKeys() {
        if #available(macOS 10.13, *) {
            if Preferences.shared.useSystemMediaControl {
                setupRemoteCommandCenter()
                initMediaKeysObservers()
            } else {
                updateNowPlayingState(.stopped)
                deinitMediaKeysObservers()
            }
        }
    }
    
    deinit {
        deinitMediaKeysObservers()
        removeObserver()
    }
}

extension Array where Element: Track {
    func randomItem() -> Element? {
        guard self.count > 0 else { return nil }
        let randomIndex = Int.random(in: 0..<self.count)
        return self[safe: randomIndex]
    }
}
