//
//  Comics.swift
//  Mahabharata
//
//  Created by Roman Developer on 11/28/17.
//  Copyright © 2017 Iron Water Studio. All rights reserved.
//

import UIKit

class ScaleAnim: Anim {
	let scaleX: Double
	let scaleY: Double
	let pivotX: Double
	let pivotY: Double
	
	private enum CodingKeys: String, CodingKey {
		case scaleX
		case scaleY
		case pivotX
		case pivotY
	}
	
	required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.scaleX = (try? container.decode(Double.self, forKey: .scaleX)) ?? 0
		self.scaleY = (try? container.decode(Double.self, forKey: .scaleY)) ?? 0
		self.pivotX = (try? container.decode(Double.self, forKey: .pivotX)) ?? 0
		self.pivotY = (try? container.decode(Double.self, forKey: .pivotY)) ?? 0

		try super.init(from: decoder)
	}
	
	init(scaleX: Double, scaleY: Double, pivotX: Double, pivotY: Double) {
		self.scaleX = scaleX
		self.scaleY = scaleY
		self.pivotX = pivotX
		self.pivotY = pivotY
		
		super.init()
	}
	
	override var description: String {
		return [
			super.description,
			"ScaleX: \(scaleX)",
			"ScaleY: \(scaleY)",
			"PivotX: \(pivotX)",
			"PivotY: \(pivotY)"
			].joined(separator: ", ")
	}
	
	//MARK: - Overrides
	override func interpolate(endAnim: Anim, fraction: Double) -> Anim {
		let end = endAnim as! ScaleAnim
		return ScaleAnim(scaleX: LinearInterpolation.evaluate(fraction: fraction, startValue: self.scaleX, endValue: end.scaleX),
						 scaleY: LinearInterpolation.evaluate(fraction: fraction, startValue: self.scaleY, endValue: end.scaleY),
		                 pivotX: LinearInterpolation.evaluate(fraction: fraction, startValue: self.pivotX, endValue: end.pivotX),
		                 pivotY: LinearInterpolation.evaluate(fraction: fraction, startValue: self.pivotY, endValue: end.pivotY))
	}
	
	override func apply(to data: Layer.ViewData, width: Int, height: Int) {
		//Because we have system anchor point == (0.5, 0.5)
		let pivotX = self.pivotX - 0.5
		let pivotY = self.pivotY - 0.5
		
		data.matrix = CATransform3DTranslate(data.matrix, CGFloat(Double(width) * pivotX), CGFloat(Double(height) * pivotY), 0)
		data.matrix = CATransform3DScale(data.matrix, CGFloat(self.scaleX), CGFloat(self.scaleY), 1)
		data.matrix = CATransform3DTranslate(data.matrix, CGFloat(-Double(width) * pivotX), CGFloat(-Double(height) * pivotY), 0)
	}
}

