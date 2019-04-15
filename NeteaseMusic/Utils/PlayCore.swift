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

    }
    
    enum PlayMode {
        case repeatPlayList, repeatItem, noRepeat
    }
    enum ShuffleMode {
        case noShuffle, shuffleItems, shuffleAlbums
    }
    
    let api = NeteaseMusicAPI()
    let player = AVPlayer()
    
    @objc dynamic var selectedSidebarItem: SidebarViewController.TableViewItem? = nil
    var playerShouldNextObserver: NSObjectProtocol?
    @objc dynamic var playlist: [Playlist.Track] = []
    @objc dynamic var currentTrack: Playlist.Track?
    
    
    var playMode: PlayMode = .repeatPlayList
    var shuffleMode: ShuffleMode = .shuffleItems
    var playedTracks = [Int]()
    var playedAlbums = [Int]()
    
    func start() {
        removeObserver()
        playerShouldNextObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: .main) { _ in
            self.nextSong()
        }
        
        if let track = playlist.first(where: { $0.song?.url != nil }) {
            play(track)
        }
    }
    
    func play(_ track: Playlist.Track) {
        guard let item = track.song?.playerItem else { return }
        
        currentTrack = track
        
        player.pause()
        player.replaceCurrentItem(with: item)
        player.seek(to: CMTime(value: 0, timescale: 1000)) {_ in
            self.player.play()
        }
        
    }
    
    func nextSong() {
        switch playMode {
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
                if tracks.count == playedTracks.count, playMode == .repeatPlayList {
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
                    if playMode == .repeatPlayList, let track = tracks.first {
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
        guard playedTracks.count > 0 else { return }
        if let id = playedTracks.last, let track = effectiveTracks().first(where: { $0.id == id }) {
            playedTracks.removeLast()
            play(track)
        }
    }
    
    func removeObserver() {
        if let obs = playerShouldNextObserver {
            NotificationCenter.default.removeObserver(obs)
            playerShouldNextObserver = nil
        }
    }
    
    func effectiveTracks() -> [Playlist.Track] {
        return playlist.filter {
            $0.song?.playerItem != nil
        }
    }
    
    deinit {
        removeObserver()
    }
}

extension Array where Element: Playlist.Track {
    func randomItem() -> Element? {
        let randomIndex = Int.random(in: 0..<self.count)
        return self[safe: randomIndex]
    }
}
