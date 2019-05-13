//
//  PlayCore.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/3/31.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa
import AVFoundation

class PlayCore: NSObject {
    static let shared = PlayCore()
    
    private override init() {
        player.automaticallyWaitsToMinimizeStalling = false
    }
    
    enum RepeatMode {
        case repeatPlayList, repeatItem, noRepeat
    }
    enum ShuffleMode {
        case noShuffle, shuffleItems, shuffleAlbums
    }
    
    let api = NeteaseMusicAPI()
    let player = AVPlayer()
    
    @objc dynamic var selectedSidebarItem: SidebarViewController.TableViewItem? = nil
    var playerShouldNextObserver: NSObjectProtocol?
    @objc dynamic var playlist: [Track] = []
    @objc dynamic var currentTrack: Track?
    
    
    var repeatMode: RepeatMode = .noRepeat
    var shuffleMode: ShuffleMode = .shuffleItems
    @objc dynamic var playedTracks = [Int]()
    var playedAlbums = [Int]()
    
    var fmMode = false {
        didSet {
            if fmMode {
                // hide prevSong, repeatMode, shuffleMode, playlist
                
            }
        }
    }
    @objc dynamic var fmPlaylist: [Track] = []
    @objc dynamic var currentFMTrack: Track?
    
    func start(_ index: Int = 0, enterFMMode: Bool = false) {
        fmMode = enterFMMode
        removeObserver()
        playerShouldNextObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: .main) { _ in
            self.nextSong()
        }
        if fmMode {
            if let track = currentFMTrack {
                play(track)
            }
        } else {
            if let track = effectiveTracks()[safe: index] {
                play(track)
            }
        }
    }
    
    func play(_ track: Track) {
        guard let item = track.song?.playerItem else { return }
        
        if fmMode {
            currentFMTrack = track
        } else {
            currentTrack = track
        }
        
        player.pause()
        player.replaceCurrentItem(with: item)
        player.seek(to: CMTime(value: 0, timescale: 1000)) {_ in
            self.player.play()
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
        
        switch repeatMode {
        case .noRepeat, .repeatPlayList:
            let tracks = effectiveTracks()
            
            guard let currentTrack = tracks.enumerated().first(where: { $0.element.song?.playerItem == player.currentItem }) else {
                print(tracks)
                print(player.currentItem)
                let t = "some thing wrong when break."
                break
            }
            
            playedTracks.append(currentTrack.element.id)
            
            switch shuffleMode {
            case .shuffleItems:
                if tracks.count == playedTracks.count, repeatMode == .repeatPlayList {
                    playedTracks.removeAll()
                }
                
                if let track = tracks.filter({ !playedTracks.contains($0.id) }).randomItem() {
                    play(track)
                }
            case .shuffleAlbums:
                break
            case .noShuffle:
                if currentTrack.offset + 1 == tracks.count {
                    // last track
                    if repeatMode == .repeatPlayList, let track = tracks.first {
                        play(track)
                    }
                } else {
                    // next track
                    if let track = tracks[safe: currentTrack.offset + 1] {
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
            if let id = playedTracks.last, let track = effectiveTracks().first(where: { $0.id == id }) {
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
    
    func effectiveTracks() -> [Track] {
        return playlist.filter {
            $0.song?.playerItem != nil
        }
    }
    
    deinit {
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
