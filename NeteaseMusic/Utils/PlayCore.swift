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
import GSPlayer

class PlayCore: NSObject {
    static let shared = PlayCore()
    
    private override init() {
        player = AVPlayer()
        player.automaticallyWaitsToMinimizeStalling = false
        super.init()
        initPlayerObservers()
    }
    
// MARK: - NowPlayingInfoCenter
    
    let remoteCommandCenter = MPRemoteCommandCenter.shared()
    let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
    let seekTimer = DispatchSource.makeTimerSource(flags: [], queue: .main)
    
// MARK: - AVPlayer
    
    private let playerQueue = DispatchQueue(label: "com.xjbeta.NeteaseMusic.AVPlayerItem")
    
    let api = NeteaseMusicAPI()
    @objc dynamic var timeControlStatus: AVPlayer.TimeControlStatus = .waitingToPlayAtSpecifiedRate
    
    
    let player: AVPlayer
    
    @objc dynamic var playProgress: Double = 0 {
        didSet {
            updateNowPlayingInfo()
        }
    }
    
    @objc enum PlayerState: Int {
        case unknown = 0
        case playing = 1
        case paused = 2
        case stopped = 3
        case interrupted = 4
    }
    
    @objc dynamic var playerState: PlayerState = .stopped {
        didSet {
            updateNowPlayingInfo()
            let state = MPNowPlayingPlaybackState(rawValue: UInt(playerState.rawValue)) ?? .stopped
            updateNowPlayingState(state)
        }
    }

    var periodicTimeObserverToken: Any?
    var timeControlStautsObserver: NSKeyValueObservation?
    
    
    var playerShouldNextObserver: NSObjectProtocol?
    var playerStateObserver: NSKeyValueObservation?
    
    @objc dynamic var currentTrack: Track?
    
    @objc dynamic var playlist: [Track] = [] {
        didSet {
            guard fmMode else { return }
            if let ct = currentTrack,
               let i = playlist.firstIndex(of: ct) {
                internalPlaylistIndex = i
            } else {
                internalPlaylistIndex = -1
            }
        }
    }
    @objc dynamic var historys: [Track] = []
    @objc dynamic var fmMode = false
    
    @objc enum PNItemType: Int {
        case withoutNext
        case withoutPrevious
        case withoutPreviousAndNext
        case other
    }
    
    @objc dynamic var pnItemType: PNItemType = .withoutPreviousAndNext
    
    private var fmSavedTime = (id: -1, time: CMTime())
    
// MARK: - AVPlayer Internal Playlist
    private var playingNextLimit = 20
    private var playingNextList: [Int] {
        get {
            if fmMode {
                let list = playlist[internalPlaylistIndex..<playlist.count]
                return list.map({ $0.id })
            }
            
            let repeatMode = Preferences.shared.repeatMode
            updateInternalPlaylist()
            
            switch repeatMode {
            case .repeatItem where currentTrack != nil:
                return [currentTrack!.id]
            case .repeatItem where playlist.first != nil:
                return [playlist.first!.id]
            case .noRepeat, .repeatPlayList:
                let sIndex = internalPlaylistIndex + 1
                var eIndex = sIndex + playingNextLimit
                if eIndex > internalPlaylist.count {
                    eIndex = internalPlaylist.count
                }
                return internalPlaylist[sIndex..<eIndex].map{ $0 }
            default:
                return []
            }
        }
    }
    
    private var internalPlaylistIndex = -1 {
        didSet {
            switch (internalPlaylistIndex, fmMode) {
            case (0, false) where internalPlaylist.count == 1:
                pnItemType = .withoutPreviousAndNext
            case (0, _):
                pnItemType = .withoutPrevious
            case (-1, _):
                pnItemType = .withoutPreviousAndNext
            case (internalPlaylist.count - 1, false):
                pnItemType = .withoutNext
            case (playlist.count - 1, true):
                pnItemType = .withoutNext
            default:
                pnItemType = .other
            }
        }
    }
    private var internalPlaylist = [Int]()
    
    
// MARK: - AVPlayer Waiting
    
    private var itemWaitingToLoad: Int?
    private var loadingList = [Int]()
    
    
// MARK: - AVPlayer Functions
    
    func start(_ playlist: [Track],
               id: Int = -1,
               enterFMMode: Bool = false) {
        
        let pl = playlist.filter {
            $0.playable
        }
        guard pl.count > 0 else {
            return
        }
        
        var sid = id
        if fmMode {
            if !enterFMMode {
                fmSavedTime = (currentTrack?.id ?? -1, CMTime(value: 0, timescale: 1000))
            } else {
                sid = fmSavedTime.id
            }
        }
        fmMode = enterFMMode
        
        stop()
        
        self.playlist = pl
        
        initInternalPlaylist(sid)
        updateInternalPlaylist()

        if fmMode {
            var time = CMTime(value: 0, timescale: 1000)
            let id = id == -1 ? playlist.first!.id : id
            if id == fmSavedTime.id {
                time = fmSavedTime.time
            }
            
            guard let i = playlist.firstIndex(where: { $0.id == id }) else {
                return
            }
            internalPlaylistIndex = i
            let track = playlist[i]
            play(track, time: time)
        } else if id != -1,
                  let i = internalPlaylist.firstIndex(of: id),
                  let track = playlist.first(where: { $0.id == id }) {
            internalPlaylistIndex = i
            play(track)
        } else if let id = internalPlaylist.first,
                  let track = playlist.first(where: { $0.id == id }) {
            internalPlaylistIndex = 0
            play(track)
        } else {
            print("Not find track to start play.")
        }
    }
    
    func playNow(_ tracks: [Track]) {
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
    
    func nextSong() {
        playerState = .unknown
        
        if fmMode {
            guard let c = currentTrack,
               let ci = playlist.firstIndex(of: c),
               let track = playlist[safe: ci + 1] else {
                print("Can't find next fm track.")
                stop()
                return
            }
            play(track)
        } else {
            let repeatMode = Preferences.shared.repeatMode
            guard repeatMode != .repeatItem else {
                player.seek(to: CMTime(value: 0, timescale: 1000))
                player.play()
                return
            }
            
            updateInternalPlaylist()
            
            guard let id = internalPlaylist[safe: internalPlaylistIndex + 1],
                  let track = playlist.first(where: { $0.id == id }) else {
                print("Can't find next track.")
                stop()
                return
            }
            internalPlaylistIndex += 1
            play(track)
        }
    }
    
    func previousSong() {
        let list = fmMode ? playlist.map({ $0.id }) : internalPlaylist
        
        guard let id = list[safe: internalPlaylistIndex - 1],
              let track = playlist.first(where: { $0.id == id })
              else {
            return
        }
        internalPlaylistIndex -= 1
        play(track)
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
        playerState = .stopped
        player.pause()
        player.currentItem?.cancelPendingSeeks()
        player.currentItem?.asset.cancelLoading()
        player.replaceCurrentItem(with: nil)
        currentTrack = nil
        internalPlaylist.removeAll()
        internalPlaylistIndex = -1
        pnItemType = .withoutPreviousAndNext
        playlist.removeAll()
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
    
// MARK: - AVPlayer Internal Functions
    
    private func play(_ track: Track,
                      time: CMTime = CMTime(value: 0, timescale: 1000)) {
        
        currentTrack = track
        
        if let song = track.song,
           song.urlValid {
            itemWaitingToLoad = nil
            realPlay(track)
        } else if itemWaitingToLoad == track.id {
            return
        } else {
            itemWaitingToLoad = track.id
            loadUrls(track)
        }
    }
    
    
    private func loadUrls(_ track: Track) {
        let list = playingNextList.filter {
            !loadingList.contains($0)
        }.compactMap { id in
            playlist.first(where: { $0.id == id })
        }.filter {
            $0.playable
        }.filter {
            !($0.song?.urlValid ?? false)
        }
        
        var ids = [track.id]
        if list.count >= 4 {
            let l = list[0..<4].map { $0.id }
            ids.append(contentsOf: l)
        } else {
            let l = list.map { $0.id }
            ids.append(contentsOf: l)
        }
        
        ids = Array(Set(ids))
        loadingList.append(contentsOf: ids)
        
        let br = Preferences.shared.musicBitRate.rawValue
        api.songUrl(ids, br).done(on: .main) {
            $0.forEach { song in
                guard let track = self.playlist.first(where: { $0.id == song.id }) else { return }
                track.song = song
                self.loadingList.removeAll(where: { $0 == song.id })
                
                if self.itemWaitingToLoad == song.id {
                    self.realPlay(track)
                    self.itemWaitingToLoad = nil
                }
            }
        }.catch {
            print("Load Song urls error: \($0)")
        }
    }
    
    
    private func realPlay(_ track: Track) {
        guard let song = track.song,
              let url = song.url?.https else {
            return
        }
        
        playerQueue.async {
            let item = AVPlayerItem(loader: url)
            item.canUseNetworkResourcesForLiveStreamingWhilePaused = true
            
            DispatchQueue.main.async {
                self.player.replaceCurrentItem(with: item)
                self.player.play()
                self.playerState = .playing
                self.initNowPlayingInfo()
                
                self.historys.removeAll {
                    $0.id == track.id
                }
                self.historys.append(track)
                
                if self.historys.count > 100 {
                    self.historys.removeFirst()
                }
            }
        }
    }
    
    private func initInternalPlaylist(_ sid: Int) {
        let repeatMode = Preferences.shared.repeatMode
        let shuffleMode = Preferences.shared.shuffleMode
        internalPlaylist.removeAll()
        let idList = playlist.map {
            $0.id
        }
        var sid = sid
        guard idList.count > 0,
              let fid = idList.first,
              !fmMode else {
            internalPlaylistIndex = -1
            return
        }
        internalPlaylistIndex = 0
        
        if sid == -1 || !idList.contains(sid) {
            sid = fid
        }
        
        switch (repeatMode, shuffleMode) {
        case (.repeatItem, _):
            internalPlaylist = [sid]
        case (.noRepeat, .noShuffle),
             (.repeatPlayList, .noShuffle):
            var l = idList
            let i = l.firstIndex(of: sid)!
            l.removeSubrange(0..<i)
            internalPlaylist = l
        case (.noRepeat, .shuffleItems),
             (.repeatPlayList, .shuffleItems):
            var l = idList.shuffled()
            l.removeAll {
                $0 == sid
            }
            l.insert(sid, at: 0)
            internalPlaylist = l
        case (.noRepeat, .shuffleAlbums),
             (.repeatPlayList, .shuffleAlbums):
            var albumList = Set<Int>()
            var dic = [Int: [Int]]()
            playlist.forEach {
                let aid = $0.album.id
                var items = dic[aid] ?? []
                items.append($0.id)
                dic[aid] = items
                albumList.insert(aid)
            }
            let todo = ""
            break
        }
    }
    
    private func updateInternalPlaylist() {
        guard !fmMode else { return }
        guard playlist.count > 0 else {
            print("Nothing playable.")
            internalPlaylistIndex = -1
            currentTrack = nil
            return
        }
        
        let repeatMode = Preferences.shared.repeatMode
        let shuffleMode = Preferences.shared.shuffleMode
        
        let idList = playlist.map {
            $0.id
        }
        
        switch (repeatMode, shuffleMode) {
        case (.repeatPlayList, .noShuffle):
            while internalPlaylist.count - internalPlaylistIndex < playingNextLimit {
                internalPlaylist.append(contentsOf: idList)
            }
        case (.repeatPlayList, .shuffleItems):
            while internalPlaylist.count - internalPlaylistIndex < playingNextLimit {
                let list = idList + idList
                internalPlaylist.append(contentsOf: list.shuffled())
            }
        case (.repeatPlayList, .shuffleAlbums):
            break
        default:
            break
        }
    }
    
    func updateRepeatShuffleMode() {
        initInternalPlaylist(currentTrack?.id ?? -1)
    }
    
// MARK: - System Media Keys
    
    func setupSystemMediaKeys() {
        if #available(macOS 10.13, *) {
            if Preferences.shared.useSystemMediaControl {
                setupRemoteCommandCenter()
            } else {
                updateNowPlayingState(.stopped)
            }
        }
    }
    
// MARK: - Observers
    func initPlayerObservers() {
        timeControlStautsObserver = player.observe(\.timeControlStatus, options: [.initial, .new]) { [weak self] (player, changes) in
            self?.timeControlStatus = player.timeControlStatus
        }
        
        let timeScale = CMTimeScale(NSEC_PER_SEC)
        let time = CMTime(seconds: 0.5, preferredTimescale: timeScale)
        

        playerStateObserver = player.observe(\.rate, options: [.initial, .new]) { player, _ in
            guard player.status == .readyToPlay else { return }
            
            self.playerState = player.rate.isZero ? .paused : .playing
        }
        
        periodicTimeObserverToken = player .addPeriodicTimeObserver(forInterval: time, queue: .main) { [weak self] time in
            let pc = PlayCore.shared
            let player = pc.player
            
            self?.playProgress = player.playProgress
            
        }
        
        playerShouldNextObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: .main) { _ in
            self.nextSong()
        }
    }
    
    func deinitPlayerObservers() {
        if let timeObserverToken = periodicTimeObserverToken {
            player.removeTimeObserver(timeObserverToken)
            periodicTimeObserverToken = nil
            playProgress = 0
        }
        playerStateObserver?.invalidate()
        timeControlStautsObserver?.invalidate()
        
        if let obs = playerShouldNextObserver {
            NotificationCenter.default.removeObserver(obs)
            playerShouldNextObserver = nil
        }
    }
    
    
    deinit {
        deinitPlayerObservers()
    }
}
