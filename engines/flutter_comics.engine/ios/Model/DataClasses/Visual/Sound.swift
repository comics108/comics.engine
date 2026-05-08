//
//  Comics.swift
//  Mahabharata
//
//  Created by Roman Developer on 11/28/17.
//  Copyright © 2017 Iron Water Studio. All rights reserved.
//

import UIKit

class Sound: Codable, CustomStringConvertible {
	//NOTE: do not set default values to make Codable decode properly
	let file: String? //should get as /sounds/file
	let animations: [SoundAnim]
	
	var description: String {
		return [
			"File: \(file ?? "")",
			"Animations: \(animations)"
			].joined(separator: ", ")
	}
}
