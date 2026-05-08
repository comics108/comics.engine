//
//  Comics.swift
//  Mahabharata
//
//  Created by Roman Developer on 11/28/17.
//  Copyright © 2017 Iron Water Studio. All rights reserved.
//

import UIKit

extension BinaryInteger {
	var degreesToRadians: CGFloat { return CGFloat(Int(self)) * .pi / 180 }
}

extension FloatingPoint {
	var degreesToRadians: Self { return self * .pi / 180 }
	var radiansToDegrees: Self { return self * 180 / .pi }
}

class RotateAnim: Anim {
	let angle: Double
	let pivotX: Double
	let pivotY: Double
	
	private enum CodingKeys: String, CodingKey {
		case angle
		case pivotX
		case pivotY
	}
	
	required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.angle = (try? container.decode(Double.self, forKey: .angle)) ?? 0
		self.pivotX = (try? container.decode(Double.self, forKey: .pivotX)) ?? 0
		self.pivotY = (try? container.decode(Double.self, forKey: .pivotY)) ?? 0
		
		try super.init(from: decoder)
	}
	
	init(angle: Double, pivotX: Double, pivotY: Double) {
		self.angle = angle
		self.pivotX = pivotX
		self.pivotY = pivotY
		
		super.init()
	}
	
	override var description: String {
		return [
			super.description,
			"Angle: \(angle)",
			"PivotX: \(pivotX)",
			"PivotY: \(pivotY)"
			].joined(separator: ", ")
	}
	
	//MARK: - Overrides
	override func interpolate(endAnim: Anim, fraction: Double) -> Anim {
		let end = endAnim as! RotateAnim
		return RotateAnim(angle: LinearInterpolation.evaluate(fraction: fraction, startValue: self.angle, endValue: end.angle),
		                  pivotX: LinearInterpolation.evaluate(fraction: fraction, startValue: self.pivotX, endValue: end.pivotX),
		                  pivotY: LinearInterpolation.evaluate(fraction: fraction, startValue: self.pivotY, endValue: end.pivotY))
	}
	
	override func apply(to data: Layer.ViewData, width: Int, height: Int) {
		//Because we have system anchor point == (0.5, 0.5)
		let pivotX = self.pivotX - 0.5
		let pivotY = self.pivotY - 0.5
		
		data.matrix = CATransform3DTranslate(data.matrix, CGFloat(Double(width) * pivotX), CGFloat(Double(height) * pivotY), 0)
		data.matrix = CATransform3DRotate(data.matrix, CGFloat(self.angle.degreesToRadians), 0, 0, 1)
		data.matrix = CATransform3DTranslate(data.matrix, CGFloat(-Double(width) * pivotX), CGFloat(-Double(height) * pivotY), 0)
	}
}

