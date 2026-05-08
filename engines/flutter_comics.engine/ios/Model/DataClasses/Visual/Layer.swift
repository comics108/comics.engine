//
//  Comics.swift
//  Mahabharata
//
//  Created by Roman Developer on 11/28/17.
//  Copyright © 2017 Iron Water Studio. All rights reserved.
//

import UIKit

class Layer: Codable, CustomStringConvertible {
	private static let kDefaultTranslate: TranslateAnim = TranslateAnim(x: 0, y: 0)
	private static let kDefaultRotate: RotateAnim = RotateAnim(angle: 0, pivotX: 0.5, pivotY: 0.5)
	private static let kDefaultScale: ScaleAnim = ScaleAnim(scaleX: 1, scaleY: 1, pivotX: 0.5, pivotY: 0.5)
	private static let kDefaultAlpha: AlphaAnim = AlphaAnim(alpha: 1)
	
	let preview: Bool?
	let images: [Image]
	var animations: [Anim]	//Only of LayerAnim protocol
	
	private var translates = [TranslateAnim]()
	private var rotates = [RotateAnim]()
	private var scales = [ScaleAnim]()
	private var alphas = [AlphaAnim]()
	private var viewData = ViewData()
	public var inverse = CATransform3DIdentity
	
	var isPreview: Bool {
		return self.preview ?? false
	}
	
	var matrix: CATransform3D {
		return self.viewData.matrix
	}
	
	var alpha: Double {
		return self.viewData.alpha
	}
	
	var image: Image? {
		if self.images.isEmpty { return nil }

		let image = self.images[Settings.shared.language.rawValue]
        
#if DEBUG
        print("##### image: \(image.file ?? "n\\a")")
#endif
        
		if !image.isEmpty {
			return image
		}
		
		for item in self.images {
			if !item.isEmpty {
				return item
			}
		}
		
		return nil
	}
	
	var popup: String? {
		if self.images.isEmpty { return nil }
		
		let image = self.images[Settings.shared.language.rawValue]
		if image.hasPopup {
			return image.popup!
		}
		
		for item in self.images {
			if item.hasPopup {
				return item.popup!
			}
		}
		
		return nil
	}
	
	private enum CodingKeys: String, CodingKey {
		case preview
		case images
		case animations
	}
	
	required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.preview = try? container.decode(Bool.self, forKey: .preview)
		self.images = try container.decode([Image].self, forKey: .images)
		
		var animations: [Anim] = []
		var animationsContainer = try container.nestedUnkeyedContainer(forKey: .animations)
		while !animationsContainer.isAtEnd {
			let wrapper = try animationsContainer.decode(AnimWrapper.self)
			animations.append(wrapper.animation)
		}
		self.animations = animations
	}
	
	var description: String {
		return [
			"Preview: \(preview ?? false)",
			"Images: \(images)",
			"Animations: \(animations)"
			].joined(separator: ", ")
	}
	
	//MARK: - Functionality
	public func prepare() {
		for anim in self.animations {
			switch anim.type {
			case .translate:
				Layer.sortedAdd(animations: &self.translates, anim: anim as! TranslateAnim)
			case .rotate:
				Layer.sortedAdd(animations: &self.rotates, anim: anim as! RotateAnim)
			case .scale:
				Layer.sortedAdd(animations: &self.scales, anim: anim as! ScaleAnim)
			case .alpha:
				Layer.sortedAdd(animations: &self.alphas, anim: anim as! AlphaAnim)
			default:
				fatalError("Not implemented for animation type: \(anim.type)")
			}
		}
		
		self.animations.removeAll()
	}
	
	public func buildInverse() {
		self.inverse = CATransform3DInvert(self.matrix)
	}
	
	public func buildMatrixAndAlpha(scrollOffset: Int) {
		if self.image == nil { return }
		
		self.viewData.matrix = CATransform3DIdentity
		self.applyAnimations(animations: self.translates, defaultValue: Layer.kDefaultTranslate, scrollOffset: scrollOffset)
		self.applyAnimations(animations: self.rotates, defaultValue: Layer.kDefaultRotate, scrollOffset: scrollOffset)
		self.applyAnimations(animations: self.scales, defaultValue: Layer.kDefaultScale, scrollOffset: scrollOffset)
		self.applyAnimations(animations: self.alphas, defaultValue: Layer.kDefaultAlpha, scrollOffset: scrollOffset)
	}
	
	private func applyAnimations<T: Anim>(animations: [T], defaultValue: T, scrollOffset: Int) {
		var previousAnim = defaultValue
		var currentAnim: T? = nil
		
		for anim in animations {
			if currentAnim != nil {
				previousAnim = currentAnim!
			}
			currentAnim = anim
			if scrollOffset < anim.end {
				break
			}
		}
		
		if currentAnim == nil {
			currentAnim = defaultValue
		}
		
		let image = self.image!
		previousAnim.interpolate(endAnim: currentAnim!, scrollOffset: scrollOffset).apply(to: self.viewData, width: image.width, height: image.height)
	}
	
	private static func sortedAdd<T: Anim>(animations: inout [T], anim: T) {
		if animations.isEmpty {
			animations.append(anim)
			return
		}

        var index = 0
		for item in animations {
			if anim.start >= item.end {
				index += 1
			}
			else {
				break
			}
		}
        animations.insert(anim, at: index)
	}

	//MARK: - ViewData
	class ViewData {
		var matrix: CATransform3D = CATransform3DIdentity
		var alpha: Double = 1
		
		init() {}
		
		init(matrix: CATransform3D, alpha: Double) {
			self.matrix = matrix
			self.alpha = alpha
		}
	}
}
