//
//  PlayCore.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/3/31.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa
import MediaPlayer
import PromiseKit

class PlayCore: NSObject {
    static let shared = PlayCore()
    
    private override init() {
        player = FSAudioController()
        let conf = player.configuration
        conf?.enableTimeAndPitchConversion = true
    }
    
// MARK: - NowPlayingInfoCenter
    
    let remoteCommandCenter = MPRemoteCommandCenter.shared()
    let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
    let seekTimer = DispatchSource.makeTimerSource(flags: [], queue: .main)
    
// MARK: - AVPlayer
    
    let api = NeteaseMusicAPI()
    
    @objc dynamic var playerState: PlayerState = .unknown
    
    let player: FSAudioController
    
    private var muteVolume: Float = -1
    @objc dynamic var isMuted = false {
        didSet {
            if isMuted {
                muteVolume = player.volume
                player.volume = 0
            } else if muteVolume != -1 {
                player.volume = muteVolume
                muteVolume = -1
            }
        }
    }
    
    var nowPlayingCoverInited = false
    
    @objc dynamic var playProgress: Float = 0

    var progressUpdateTimer: DispatchSourceTimer?
    
    @objc dynamic var currentTrack: Track? {
        didSet {
            nowPlayingCoverInited = false
            updateNowPlayingInfo()
        }
    }
    @objc dynamic var playlist: [Track] = []
    @objc dynamic var historys: [Track] = []
    @objc dynamic var fmMode = false {
        didSet {
            if fmMode {
                // hide prevSong, repeatMode, shuffleMode, playlist
                
            }
        }
    }
    
    @objc enum PNItemType: Int {
        case withoutNext
        case withoutPrevious
        case withoutPreviousAndNext
        case other
    }
    
    @objc dynamic var pnItemType: PNItemType = .withoutPreviousAndNext
    
    private var fmSavedTime: (id: Int, time: Float) = (-1, 0)
    
// MARK: - AVPlayer Internal Playlist
    private var playingNextLimit = 20
    private var playingNextList: [Int] {
        get {
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
            switch internalPlaylistIndex {
            case 0 where internalPlaylist.count == 1:
                pnItemType = .withoutPreviousAndNext
            case 0:
                pnItemType = .withoutPrevious
            case -1:
                pnItemType = .withoutPreviousAndNext
            case internalPlaylist.count - 1:
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
        self.playlist = playlist.filter {
            $0.playable
        }
        currentTrack = nil
        initInternalPlaylist(id)
        updateInternalPlaylist()
        
        if fmMode, !enterFMMode {
            let time = player.activeStream.currentTimePlayed.playbackTimeInSeconds
            fmSavedTime = (currentTrack?.id ?? -1, time)
        }
        
        fmMode = enterFMMode
        
        guard playlist.count > 0 else { return }
        
        if fmMode,
           let track = currentTrack,
           fmSavedTime.id == track.id {
            play(track, time: fmSavedTime.time)
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
        let repeatMode = Preferences.shared.repeatMode
        guard repeatMode != .repeatItem else {
            var pos = FSStreamPosition()
            pos.position = 0
            player.activeStream.seek(to: pos)
            player.play()
            return
        }
        
        updateInternalPlaylist()
        
        guard let id = internalPlaylist[safe: internalPlaylistIndex + 1],
              let track = playlist.first(where: { $0.id == id }) else {
            stop()
            return
        }
        internalPlaylistIndex += 1
        play(track)
    }
    
    func previousSong() {
        guard let id = internalPlaylist[safe: internalPlaylistIndex - 1],
              let track = playlist.first(where: { $0.id == id })
              else {
            return
        }
        internalPlaylistIndex -= 1
        play(track)
    }

    func togglePlayPause() {
        if currentTrack != nil {
            player.pause()
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
        player.stop()
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
        var pos = FSStreamPosition()
        player.activeStream.seek(to: pos)
    }
    
    func seekBackward(_ seconds: Double) {
        var pos = FSStreamPosition()
        player.activeStream.seek(to: pos)
    }
    
    func currentTime() -> Float {
        guard let stream = player.activeStream else { return 0 }
        return Float(stream.currentTimePlayed.second)
    }
    
// MARK: - AVPlayer Internal Functions
    
    private func play(_ track: Track,
                      time: Float = 0) {
        
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
        
        player.url = url as NSURL
        player.play()
        
        player.activeStream.onStateChange = { state in
            self.updatePlayerState(state)
        }
        
        historys.removeAll {
            $0.id == track.id
        }
        historys.append(track)
        
        if historys.count > 100 {
            historys.removeFirst()
        }
    }
    
    private func initInternalPlaylist(_ sid: Int) {
        let repeatMode = Preferences.shared.repeatMode
        let shuffleMode = Preferences.shared.shuffleMode
        internalPlaylist.removeAll()
        internalPlaylistIndex = 0
        let idList = playlist.map {
            $0.id
        }
        var sid = sid
        guard idList.count > 0, let fid = idList.first else {
            internalPlaylistIndex = -1
            return
        }
        
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

    func updatePlayerState(_ state: FSAudioStreamState) {
        
        let state = PlayerState(rawValue: state.rawValue) ?? .unknown
        
        
        self.playerState = state
        
        var npState: MPNowPlayingPlaybackState = .unknown
        
        print(state.debug)
        
        switch state {
        case .playing:
            npState = .playing
            startProgressTimer()
            self.updateNowPlayingInfo()
        case .paused:
            npState = .paused
        case .seeking:
            break
        case .stopped:
            npState = .stopped
            stopProgressTimer()
        case .buffering:
            break
        case .endOfFile:
            break
        case .failed:
            break
        case .playbackCompleted:
            self.nextSong()
            break
        case .retrievingURL:
            break
        case .retryingStarted:
            break
        case .retryingFailed:
            break
        case .retryingSucceeded:
            break
        case .unknown:
            break
        }
        
        self.updateNowPlayingState(npState)
    }
    
    func startProgressTimer() {
        guard progressUpdateTimer == nil else { return }

        progressUpdateTimer = DispatchSource.makeTimerSource(flags: [], queue: .main)
        guard let timer = progressUpdateTimer else { return }
        timer.schedule(deadline: .now(), repeating: .milliseconds(500))
        timer.setEventHandler {
            if let stream = self.player.activeStream {
                self.playProgress = stream.currentTimePlayed.position
            } else {
                self.playProgress = -1
            }
        }
        timer.resume()
    }
    
    func stopProgressTimer() {
        guard let timer = progressUpdateTimer else { return }
        timer.cancel()
        progressUpdateTimer = nil
    }
    
    deinit {
        
    }
}
