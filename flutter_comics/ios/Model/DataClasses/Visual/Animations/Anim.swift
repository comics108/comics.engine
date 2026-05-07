//
//  Comics.swift
//  Mahabharata
//
//  Created by Roman Developer on 11/28/17.
//  Copyright © 2017 Iron Water Studio. All rights reserved.
//

import UIKit

enum AnimType: Int, Codable {
	case translate, rotate, scale, alpha, sound
}

class AnimWrapper: Decodable {
	var animation: Anim
	
	enum CodingKeys : String, CodingKey {
		case type
	}
	
	required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let type = (try? container.decode(AnimType.self, forKey: .type)) ?? .translate
		
		switch type {
		case .translate:
			self.animation = try TranslateAnim(from: decoder)
		case .sound:
			self.animation = try SoundAnim(from: decoder)
		case .scale:
			self.animation = try ScaleAnim(from: decoder)
		case .rotate:
			self.animation = try RotateAnim(from: decoder)
		case .alpha:
			self.animation = try AlphaAnim(from: decoder)
//		default:
//			throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unhandled type: \(type)")
		}
	}
}

class LinearInterpolation {
	public static func evaluate(fraction: Double, startValue: Double, endValue: Double) -> Double {
		return startValue + (endValue - startValue) * fraction
	}
	
	//TODO: Probably replace with templated function
	public static func evaluate(fraction: Double, startValue: Int, endValue: Int) -> Int {
		return startValue + Int(Double(endValue - startValue) * fraction)
	}
}

class Anim: Codable, CustomStringConvertible {
	let start: Int
	let end: Int
	let type: AnimType
	
	var isPoint: Bool {
		return self.start == self.end
	}
	
	private enum CodingKeys: String, CodingKey {
		case start, end, type
	}
	
	required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.start = (try? container.decode(Int.self, forKey: .start)) ?? 0
		self.end = (try? container.decode(Int.self, forKey: .end)) ?? 0
		self.type = (try? container.decode(AnimType.self, forKey: .type)) ?? .translate
	}
	
	init(start: Int = 0, end: Int = 0, type: AnimType = .translate){
		self.start = start
		self.end = end
		self.type = type
	}
	
	var description: String {
		return [
			"Start: \(start)",
			"End: \(end)",
			"Type: \(type)"
			].joined(separator: ", ")
	}
	
	//MARK: - Calculations
	func interpolate(endAnim: Anim, scrollOffset: Int) -> Anim {
		let scrollObject = scrollOffset - endAnim.start
		let animHeight = endAnim.end - endAnim.start
		let fraction = animHeight == 0 ? 1 : min(1, max(0, Double(scrollObject) / Double(animHeight)))
		return self.interpolate(endAnim: endAnim, fraction: transformToCubic(fraction))
	}
	
	//ERROR: 0 is not transformed into 0
	private func transformToCubic(_ fraction: Double) -> Double {
		return pow(fraction - 1, 3) + 1
	}
	
	func interpolate(endAnim: Anim, fraction: Double) -> Anim {
		fatalError("Must be overriden")
	}
	
	func apply(to data: Layer.ViewData, width: Int, height: Int) {
		fatalError("Must be overriden")
	}
}
