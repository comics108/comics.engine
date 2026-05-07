//
//  AVPlayer+Fade.swift
//  SoundManager
//
//  Created by Olga Zhegulo  on 06 Apr 2018.
//  Copyright © 2018 Iron Water Studio. All rights reserved.
//

import AVKit

//https://stackoverflow.com/questions/1216581/avaudioplayer-fade-volume-out

extension AVPlayer {
	func fadeOut(to volume: Float, duration: TimeInterval, delay: Double = 0.1, completion: (() -> ())? = nil) {
		
		if volume >= self.volume {
			self.volume = volume
			return
		}
		
		let step: Float = (self.volume - volume) * (Float(delay / duration))
		
		self.fadeOut(to: volume, delay: delay, step: step, completion: completion)
	}
	
	private func fadeOut(to volume: Float, delay: Double, step: Float, completion: (() -> ())? = nil) {
		print("volume", self.volume, "to", volume)
		if self.volume - volume > step {
			print("step")

			DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delay, execute: {
				[weak self] in
				guard let strongSelf = self else { return }
				print("volume", strongSelf.volume)
				strongSelf.volume -= step
				strongSelf.fadeOut(to: volume, delay: delay, step: step, completion: completion)
			})
		} else {
			print("faded out volume", self.volume)
			self.volume = volume
			completion?()
		}
	}
}
