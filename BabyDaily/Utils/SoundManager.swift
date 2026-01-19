//
//  SoundManager.swift
//  plusone
//
//  Created by 常明 on 2026/1/12.
//

import AVFoundation
import Combine

class SoundManager: ObservableObject {
    @Published var isSoundEnabled: Bool = true
    
    private var celeSoundPlayer: AVAudioPlayer?
    private var lihuaSoundPlayer: AVAudioPlayer?
    
    init() {
        loadSoundEffects()
    }
    
    // 加载音效资源
    private func loadSoundEffects() {
        // 加载庆祝音效
        celeSoundPlayer = loadSound(named: "cele")
        // 加载礼花音效
        lihuaSoundPlayer = loadSound(named: "lihua")
    }
    
    // 从网络URL加载音效
    private func loadSound(fromURL urlString: String) -> AVAudioPlayer? {
        guard let url = URL(string: urlString) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let player = try AVAudioPlayer(data: data)
            player.prepareToPlay()
            return player
        } catch {
            return nil
        }
    }
    
    // 加载单个音效文件
    private func loadSound(named name: String, withExtension ext: String = "mp3") -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
            return nil
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            return player
        } catch {
            return nil
        }
    }
    
    // 播放庆祝音效
    func playCelebrationSound() {
        print("Play celebration sound called, isSoundEnabled: \(isSoundEnabled), celeSoundPlayer: \(celeSoundPlayer != nil)")
        guard isSoundEnabled, let player = celeSoundPlayer else { return }
        player.stop()
        player.currentTime = 0
        player.play()
    }
    
    // 播放礼花音效
    func playLihuaSound() {
        guard isSoundEnabled else { return }
        // 为每次播放创建新的AVAudioPlayer实例，确保每次调用都能完整播放声音
        if let player = loadSound(named: "lihua") {
            player.play()
        }
    }
    
    // 切换音效开关
    func toggleSound() {
        isSoundEnabled.toggle()
    }
}
