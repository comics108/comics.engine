//
//  SoundManager.swift
//  SoundManager
//
//  Created by Olga Zhegulo  on 02 Jun 2017.
//  Copyright © 2017 Iron Water Studio. All rights reserved.
//
//  Dependencies:
//      system: AVFoundation
//      custom: AVPlayer+Fade.h
//
//  Changes history:
// 		7 Dec 2018. Olga Zhegulo:
//			* added iOS9 branch for AVAudioSession.sharedInstance().setCategory call (imported missing header by Objective C category)
//		21 Jun 2019. Olga Zhegulo:
//			* changed support target from 9.0 to 10.0 and removed call to iOS 9.0 function signature
//		25 Oct 2019. Olga Zhegulo:
//			* added loop play
//

import AVFoundation

final class SoundManager {
	
	static let shared = SoundManager(audioSessionCategory: AVAudioSession.Category.playback.rawValue)
	
	private var player: AVPlayer?
	var isLoop: Bool = false
	
	var currentTime: Double {
		let currentTime = player?.currentTime() ?? CMTime()
		return CMTimeGetSeconds(currentTime)
	}
	
	var isReadyToPlay: Bool {
		if let player = player, let currentItem = player.currentItem {
			return currentItem.status == .readyToPlay
		}
		return false
	}
	
	var isMuted: Bool {
		set {
			player?.isMuted = newValue
		}
		get {
			return player?.isMuted ?? false
		}
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	private init() {
		player = AVPlayer()
	}
	
	convenience init(audioSessionCategory: String?) {
		self.init()
		if let category = audioSessionCategory {
			do {
				try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category(rawValue: category), mode: .default, options: [])
				try AVAudioSession.sharedInstance().setActive(true)
			} catch {
				print("Error during setting category: \(category)")
			}
		}
	}
	
	func setupSharedAudioSession(audioSessionCategory: String?) {
		if let category = audioSessionCategory {
			do {
				try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category(rawValue: category), mode: .default, options: [])
				try AVAudioSession.sharedInstance().setActive(true)
			} catch {
				print("Error during setting category: \(category)")
			}
		}
	}
	
	func play(url: URL, loop: Bool = false) {
		
		self.isLoop = loop
		
		if currentTime.isNaN {
			//Clear resources
			stop()
			
			//Play source
			player = AVPlayer(url: url)
			player?.volume = 1.0
		}
		
		if self.isLoop {
			NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
		}
		player?.play()
	}
	
	func pause() {
		player?.pause()
		NotificationCenter.default.removeObserver(self)
	}
	
	func resume() {
		
		if self.isLoop {
			NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
		}
		player?.play()
	}
	
	func stop() {
		player?.pause()
		NotificationCenter.default.removeObserver(self)
		player = nil
	}
	
	func seek(time: TimeInterval) {
		//Fix for seek in stream
		var currentAssetTimeScale: CMTimeScale = 1
		if let player = self.player, let currentItem = player.currentItem {
			currentAssetTimeScale = currentItem.asset.duration.timescale
		}
		
		let seekTime = CMTime(seconds: time, preferredTimescale: currentAssetTimeScale)
		player?.seek(to: seekTime)
	}
	
	func fadeOut(to volume: Float = 0, duration: TimeInterval, delay: Double = 0.1, completion: (() -> ())? = nil) {
		self.player?.fadeOut(to: volume, duration: duration, delay: delay, completion: {
			self.stop()
			completion?()
		})
	}
	
	//MARK: - Notification
	
	//Is called only for loop player
	@objc func playerDidFinishPlaying(notification: NSNotification) {
		if let player = self.player {
			//Go to start
			player.seek(to: CMTime.zero)
			//And play again
			player.play()
		}
	}
	
	/**
	Duration in seconds
	*/
	static func duration(url: URL) -> Double {
		let audioAsset = AVURLAsset(url: url)
		let audioDuration: CMTime = audioAsset.duration
		return CMTimeGetSeconds(audioDuration)
	}
	
	static func playSystemSound(systemSoundID: SystemSoundID) {
		AudioServicesPlaySystemSoundWithCompletion(systemSoundID, nil)
	}
}
