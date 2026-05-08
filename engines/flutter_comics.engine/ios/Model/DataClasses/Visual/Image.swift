//
//  Image
//  Mahabharata
//
//  Created by Roman Developer on 11/28/17.
//  Copyright © 2017 Iron Water Studio. All rights reserved.
//

import UIKit

class Image: Codable, CustomStringConvertible {
	let width: Int
	let height: Int
	let file: String?	//should get as /layers/file. File can be nil if image for localization is not set. In this case width and height will be 0
	let popup: String?	//and this too
	
	private enum CodingKeys: String, CodingKey {
		case width
		case height
		case file
		case popup
	}
	
	required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.width = (try? container.decode(Int.self, forKey: .width)) ?? 0
		self.height = (try? container.decode(Int.self, forKey: .height)) ?? 0
		self.file = try? container.decode(String.self, forKey: .file)
		self.popup = try? container.decode(String.self, forKey: .popup)
	}
	
	var description: String {
		return [
			"Width: \(width)",
			"Height: \(height)",
			"File: \(file ?? "")",
			"Popup: \(popup ?? "")"
			].joined(separator: ", ")
	}
	
	var isEmpty: Bool {
		return String.isNilOrWhiteSpace(self.file)
	}
	
	var hasPopup: Bool {
		return !String.isNilOrWhiteSpace(self.popup)
	}
}
