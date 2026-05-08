//
//  ArchiveManager.swift
//  Mahabharata
//
//  Created by Roman Developer on 12/5/17.
//  Copyright © 2017 Iron Water Studio. All rights reserved.
//

import UIKit

final class ArchiveManager {
	static let shared = ArchiveManager()

	var currentArchiveURL: URL?
	
	func comics(success: (Comics?) -> ()) {
		if let path = self.currentArchiveURL?.appendingPathComponent("data.json").relativePath,
			FileManager.default.fileExists(atPath: path) {
			do {
				let decoder = JSONDecoder()
				if let data = try? NSData(contentsOfFile: path, options: []) as Data {
					let comics = try decoder.decode(Comics.self, from: data)
					success(comics)
				} else {
					success(nil)
				}
			}
			catch {
				print("JSON parse error: \(error)")
			}
		}
	}
	
	func layer(name: String, success: @escaping (UIImage) -> ()) {
		guard let path = self.currentArchiveURL?.appendingPathComponent("layers").appendingPathComponent(name).relativePath
			else { return }
		
		if !FileManager.default.fileExists(atPath: path) {
			success(UIImage())
		} else {
			//A
//			let start = Date().timeIntervalSince1970
//			let image = UIImage(named: path) ?? UIImage()
//			print("==== Loaded: \(Date().timeIntervalSince1970 - start)")
//			success(image)
//			print("==== Handled: \(Date().timeIntervalSince1970 - start)")

			//B
//			let start = Date().timeIntervalSince1970
//			let image = UIImage(named: path) ?? UIImage()
//			DispatchQueue.global(qos: .userInitiated).async {
//				if let preloadedImage = ImageManager.preload(image) {
//					print("==== Loaded: \(Date().timeIntervalSince1970 - start)")
//					DispatchQueue.main.async {
//						success(preloadedImage)
//						print("==== Handled: \(Date().timeIntervalSince1970 - start)")
//					}
//				}
//			}
			
//			//c: reqman
//			let start = Date().timeIntervalSince1970
//			DispatchQueue.global(qos: .utility).async {
//
//				if let image = UIImage(named: path),
//					let preloadedImage = ImageManager.preload(image) {
//					print("==== Loaded: \(Date().timeIntervalSince1970 - start)")
//					DispatchQueue.main.async {
//						success(preloadedImage)
//						print("==== Handled: \(Date().timeIntervalSince1970 - start)")
//					}
//				} else {
//					DispatchQueue.main.async {
//						success(UIImage())
//					}
//				}
//			}

//			//d: delay
//			let start = Date().timeIntervalSince1970
//			DispatchQueue.global(qos: .utility).async {
//
//				if let image = UIImage(named: path) {
//					print("==== Loaded: \(Date().timeIntervalSince1970 - start)")
//
//					DispatchQueue.main.async {
//						success(image)
//						print("==== Handled: \(Date().timeIntervalSince1970 - start)")
//					}
//				} else {
//					DispatchQueue.main.async {
//						success(UIImage())
//					}
//				}
//			}
			
			//E
//			let start = Date().timeIntervalSince1970
			DispatchQueue.global().async {
				let imageData = try! NSData(contentsOfFile: path, options: []) as Data
				if let image = UIImage(data: imageData, scale: UIScreen.main.scale) {
//					print("==== Loaded: \(Date().timeIntervalSince1970 - start)")
					DispatchQueue.main.async {
						success(image)
//						print("==== Handled: \(Date().timeIntervalSince1970 - start)")
					}
				} else {
					DispatchQueue.main.async {
						success(UIImage())
//						print("==== Handled: \(Date().timeIntervalSince1970 - start)")
					}
				}
			}
		}
	}
	
	func sound(name: String, success: @escaping (URL?) -> ()) {
		guard let path = self.currentArchiveURL?.appendingPathComponent("sounds").appendingPathComponent(name).relativePath
			else { return }

		if !FileManager.default.fileExists(atPath: path) {
			success(nil)
		} else {
			success(URL(fileURLWithPath: path))
		}
	}
	
	//Async
	@objc
	private static func requestThreadEntryPoint(_ object: Any) {
		autoreleasepool {
			let currentRunLoop = RunLoop.current
			currentRunLoop.add(Port(), forMode: RunLoop.Mode(rawValue: RunLoop.Mode.default.rawValue))
			currentRunLoop.run()
		}
	}
}
