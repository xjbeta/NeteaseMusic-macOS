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
import PromiseKit

class PlayCore: NSObject {
    static let shared = PlayCore()
    
    private override init() {
        player.automaticallyWaitsToMinimizeStalling = false
    }
    
// MARK: - NowPlayingInfoCenter
    
    let remoteCommandCenter = MPRemoteCommandCenter.shared()
    let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
    let seekTimer = DispatchSource.makeTimerSource(flags: [], queue: .main)
    
// MARK: - AVPlayer
    
    let api = NeteaseMusicAPI()
    let player = AVPlayer()
    
    var playerShouldNextObserver: NSObjectProtocol?
    var playerItemDownloadObserver: NSObjectProtocol?
    var playerStateObserver: NSKeyValueObservation?
    var playingInfoObserver: NSKeyValueObservation?
    
    @objc dynamic var currentTrack: Track?
    @objc dynamic var playlist: [Track] = []
    var plIDPrepared = [Int]()
    var playedIDInLoop = [Int]()
    
    @objc dynamic var historys: [Track] = []
    
    
    
    @objc dynamic var playedTracks = [Int]()
    var playedAlbums = [Int]()
    
    @objc dynamic var fmMode = false {
        didSet {
            if fmMode {
                // hide prevSong, repeatMode, shuffleMode, playlist
                
            }
        }
    }
    
    private var fmSavedTime = (id: -1, time: CMTime())
    
    
// MARK: - AVPlayer Functions
    
    func start(_ playlist: [Track],
               id: Int = -1,
               enterFMMode: Bool = false) {
        self.playlist = playlist
        
        
        if fmMode, !enterFMMode {
            fmSavedTime = (currentTrack?.id ?? -1, player.currentTime())
        }
        
        fmMode = enterFMMode
        initObservers()
        
        playedIDInLoop.removeAll()
        
        guard playlist.count > 0 else { return }
        
        if fmMode,
           let track = currentTrack,
           fmSavedTime.id == track.id {
            play(track, time: fmSavedTime.time)
        } else if let track = playlist.first(where: { $0.id == id }) {
            play(track)
        } else if let track = playlist.first {
            play(track)
        }
    }
    
    private func play(_ track: Track, time: CMTime = CMTime(value: 0, timescale: 1000)) {
        if track.song != nil {
            
            
            
        } else {
            
            
            
            
        }
        
        
        
        
        
        playerItems([track.id]).done {
            
            guard let re = $0.first else {
                let t = "empty result"
                return
            }
            
            guard re.2 != nil else {
                let t = "nil item"
                return
            }
            
            track.song = re.1
            
            self.currentTrack = track

            self.player.pause()
            self.player.replaceCurrentItem(with: re.2)
            self.player.seek(to: time) {_ in
                self.player.play()
            }

            self.historys.removeAll {
                $0.id == track.id
            }
            self.historys.append(track)
            self.playedIDInLoop.append(track.id)

            if self.historys.count > 100 {
                self.historys.removeFirst()
            }
            }.catch {
                print($0)
        }
    }
    
    func nextSong() {
        guard !fmMode else {
            if let track = currentTrack,
               let i = playlist.firstIndex(of: track),
               let next = playlist[safe: i + 1] {
                play(next)
            } else {
                // todo
                print("Can't find next FM track.")
            }
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
            if let track = currentTrack,
               let i = playlist.firstIndex(of: track),
               let prev = playlist[safe: i - 1] {
                play(prev)
            } else {
                // todo
                print("Can't find prev FM track.")
            }
        } else {
            guard playedTracks.count > 0 else { return }
            if let id = playedTracks.last, let track = playlist.first(where: { $0.id == id }) {
                playedTracks.removeLast()
                play(track)
            }
        }
    }
    
    func initObservers() {
        removeObservers()
        playerShouldNextObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: .main) { _ in
            self.nextSong()
        }
        
        playerItemDownloadObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDownloadFinished, object: nil, queue: .main) {
            guard let dic = $0.object as? [String: Int],
                  let id = dic["id"],
                  let item = self.playlist.first(where: { $0.id == id })?.playerItem else { return }
            
            item.downloadState = .downloadFinished
            self.loadMoreItems()
        }
    }
    
    func removeObservers() {
        if let obs = playerShouldNextObserver {
            NotificationCenter.default.removeObserver(obs)
            playerShouldNextObserver = nil
        }
        if let obs = playerItemDownloadObserver {
            NotificationCenter.default.removeObserver(obs)
            playerItemDownloadObserver = nil
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
        if currentTrack != nil {
            playOrPause()
        } else if let item = ViewControllerManager.shared.selectedSidebarItem?.type {
            switch item {
            case .fm:
                start([], enterFMMode: true)
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
        currentTrack = nil
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
    
    func playerItems(_ ids: [Int]) -> Promise<[(Int, Song, AVPlayerItem?)]> {
        let br = Preferences.shared.musicBitRate.rawValue
        return Promise { resolver in
            api.songUrl(ids, br).done {
                let re = $0.map { s -> (id: Int, song: Song, playerItem: AVPlayerItem?) in
                    
                    var r: (id: Int, song: Song, playerItem: AVPlayerItem?) = (s.id, s, nil)
                    
                    guard let uStr = s.url?.absoluteString.replacingOccurrences(of: "http://", with: "https://"),
                        let url = URL(string: uStr) else {
                        return r
                    }
                    
                    let asset = AVURLAsset(url: url)
                    guard asset.isPlayable else { return r }
                    r.playerItem = AVPlayerItem(asset: asset)
                    return r
                }
                
                resolver.fulfill(re)
                }.catch {
                    resolver.reject($0)
            }
        }
    }
    
    func loadMoreItems() {
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
        removeObservers()
    }
}



    }
}
