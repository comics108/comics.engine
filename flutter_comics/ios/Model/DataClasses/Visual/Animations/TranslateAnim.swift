//
//  Comics.swift
//  Mahabharata
//
//  Created by Roman Developer on 11/28/17.
//  Copyright © 2017 Iron Water Studio. All rights reserved.
//

import UIKit

class TranslateAnim: Anim {
	let x: Int
	let y: Int
	
	private enum CodingKeys: String, CodingKey {
		case x
		case y
	}
	
	required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.x = (try? container.decode(Int.self, forKey: .x)) ?? 0
		self.y = (try? container.decode(Int.self, forKey: .y)) ?? 0
		
		try super.init(from: decoder)
	}
	
	init(x: Int, y: Int) {
		self.x = x
		self.y = y
		
		super.init()
	}
	
	override var description: String {
		return [
			super.description,
			"X: \(x)",
			"Y: \(y)"
			].joined(separator: ", ")
	}
	
	//MARK: - Overrides
	override func interpolate(endAnim: Anim, fraction: Double) -> Anim {
		let end = endAnim as! TranslateAnim
		//print("TranslateAnim interpolate. Fraction: \(fraction), start: \(self.y), end: \(end.y), interpolated y: \(LinearInterpolation.evaluate(fraction: fraction, startValue: self.y, endValue: end.y))")
		return TranslateAnim(x: LinearInterpolation.evaluate(fraction: fraction, startValue: self.x, endValue: end.x),
		                     y: LinearInterpolation.evaluate(fraction: fraction, startValue: self.y, endValue: end.y))
	}
	
	override func apply(to data: Layer.ViewData, width: Int, height: Int) {
		data.matrix = CATransform3DTranslate(data.matrix, CGFloat(self.x), CGFloat(self.y), 0)
	}
}

