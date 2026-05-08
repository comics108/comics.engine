//
//  Comics.swift
//  Mahabharata
//
//  Created by Roman Developer on 11/28/17.
//  Copyright © 2017 Iron Water Studio. All rights reserved.
//

import UIKit

class Comics: Codable, CustomStringConvertible {
	//NOTE: do not set default values to make Codable decode properly
	let width: Int
	let height: Int
	let layers: [Layer]
	let sounds: [Sound]
	
	//private var previousScrollOffset = -1
	
	var description: String {
		return [
			"Width: \(width)",
			"Height: \(height)",
			"Layers: \(layers)",
			"Sounds: \(sounds)"
			].joined(separator: ", ")
	}
	
	public func prepare() {
		for layer in self.layers {
			layer.prepare()
		}
	}
	
	public func process(scrollOffset: Int) {
		for layer in self.layers {
			layer.buildMatrixAndAlpha(scrollOffset: scrollOffset)
		}
		
		//self.previousScrollOffset = scrollOffset
	}
	
	public func hasPreview() -> Bool {
		for layer in self.layers {
			if layer.isPreview {
				return true
			}
		}
		
		return false
	}
}
