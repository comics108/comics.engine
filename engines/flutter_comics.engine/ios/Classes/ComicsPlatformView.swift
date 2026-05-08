//
//  ComicsPlatformView.swift
//  flutter_comics
//
//  Platform View wrapper for native comics rendering
//

import Flutter
import UIKit
import ZIPFoundation

class ComicsPlatformView: NSObject, FlutterPlatformView, ImageScrollViewDelegate {
    private var scrollView: ImageScrollView
    private var channel: FlutterMethodChannel?
    private var archivePath: String?
    private var extractedPath: URL?
    private var languageIndex: Int = 0
    private var soundEnabled: Bool = true

    init(
        frame: CGRect,
        viewId: Int64,
        messenger: FlutterBinaryMessenger?,
        args: [String: Any]
    ) {
        scrollView = ImageScrollView()
        super.init()

        if let messenger = messenger {
            channel = FlutterMethodChannel(
                name: "flutter_comics_\(viewId)",
                binaryMessenger: messenger
            )
            channel?.setMethodCallHandler(handleMethodCall)
        }

        scrollView.scrollDelegate = self
        scrollView.frame = frame
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        // Get creation params
        let zoomEnabled = args["zoomEnabled"] as? Bool ?? false
        languageIndex = args["languageIndex"] as? Int ?? 0
        soundEnabled = args["soundEnabled"] as? Bool ?? true
        scrollView.isComics = !zoomEnabled

        // Load scene if archivePath is provided
        if let path = args["archivePath"] as? String, !path.isEmpty {
            loadScene(path: path)
        }
    }

    func view() -> UIView {
        return scrollView
    }

    // MARK: - Method Channel Handler

    private func handleMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "setScrollOffset":
            if let args = call.arguments as? [String: Any],
               let offset = args["offset"] as? Int {
                let scale = scrollView.zoomScale
                scrollView.setContentOffset(CGPoint(x: 0, y: CGFloat(offset) * scale), animated: true)
            }
            result(nil)

        case "getScrollOffset":
            let offset = Int(scrollView.contentOffset.y / scrollView.zoomScale)
            result(offset)

        case "setLanguageIndex":
            if let args = call.arguments as? [String: Any],
               let index = args["index"] as? Int {
                languageIndex = index
                // Reload language-specific content
                scrollView.reloadLanguage()
            }
            result(nil)

        case "setSoundEnabled":
            if let args = call.arguments as? [String: Any],
               let enabled = args["enabled"] as? Bool {
                soundEnabled = enabled
                scrollView.mute(!enabled)
            }
            result(nil)

        case "pauseSounds":
            scrollView.pauseSounds()
            result(nil)

        case "resumeSounds":
            scrollView.resumeSounds()
            result(nil)

        case "hitTest":
            if let args = call.arguments as? [String: Any],
               let x = args["x"] as? Double,
               let y = args["y"] as? Double {
                let hitResult = performHitTest(x: CGFloat(x), y: CGFloat(y))
                result(hitResult)
            } else {
                result(nil)
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Scene Loading

    private func loadScene(path: String) {
        archivePath = path

        // Check if path is a ZIP file or directory
        let fileURL = URL(fileURLWithPath: path)
        var sourceURL: URL

        if fileURL.pathExtension == "comics" || fileURL.pathExtension == "zip" {
            // Extract ZIP to temp directory
            let tempDir = FileManager.default.temporaryDirectory
                .appendingPathComponent("flutter_comics_\(UUID().uuidString)")

            do {
                try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
                try FileManager.default.unzipItem(at: fileURL, to: tempDir)
                extractedPath = tempDir
                sourceURL = tempDir
            } catch {
                channel?.invokeMethod("onError", arguments: "Failed to extract archive: \(error.localizedDescription)")
                return
            }
        } else {
            sourceURL = fileURL
            extractedPath = fileURL
        }

        // Set archive URL for ArchiveManager
        let arcMan = ArchiveManager()
        arcMan.currentArchiveURL = sourceURL

        // Load comics data
        arcMan.comics { [weak self] comics in
            guard let self = self, let comics = comics else {
                self?.channel?.invokeMethod("onError", arguments: "Failed to load comics data")
                return
            }

            // Configure archive manager for tile loading
            ArchiveManager.shared.currentArchiveURL = sourceURL

            // Set comics to scrollView
            self.scrollView.comics = comics

            // Notify Flutter
            self.channel?.invokeMethod("onSceneLoaded", arguments: [
                "width": comics.width,
                "height": comics.height,
                "layerCount": comics.layers.count,
                "hasSound": !comics.sounds.isEmpty
            ])
        }
    }

    // MARK: - ImageScrollViewDelegate

    func imageScrollViewDidScroll(_ view: ImageScrollView) {
        let offset = Int(view.contentOffset.y / view.zoomScale)
        let contentHeight = Int(view.contentSize.height / view.zoomScale)
        let viewHeight = Int(view.frame.height / view.zoomScale)
        let maxOffset = max(0, contentHeight - viewHeight)

        channel?.invokeMethod("onScrollChanged", arguments: [
            "offset": offset,
            "maxOffset": maxOffset
        ])
    }

    // MARK: - Hit Testing

    private func performHitTest(x: CGFloat, y: CGFloat) -> [String: Any]? {
        guard let comics = scrollView.comics else { return nil }

        let scale = scrollView.zoomScale
        let scrollX = scrollView.contentOffset.x / scale
        let scrollY = scrollView.contentOffset.y / scale

        // Convert touch coordinates to content coordinates
        let contentX = x / scale + scrollX
        let contentY = y / scale + scrollY

        // Test layers from top to bottom (reversed order)
        for (index, layer) in comics.layers.enumerated().reversed() {
            guard let image = layer.image else { continue }

            // Get layer transform
            let transform = CATransform3DGetAffineTransform(layer.matrix)
            let layerRect = CGRect(x: 0, y: 0, width: image.width, height: image.height)
            let transformedRect = layerRect.applying(transform)

            if transformedRect.contains(CGPoint(x: contentX, y: contentY)) {
                return [
                    "layerIndex": index,
                    "popupPath": layer.popup ?? NSNull(),
                    "isHit": true
                ]
            }
        }

        return ["isHit": false, "layerIndex": -1]
    }

    // MARK: - Cleanup

    deinit {
        channel?.setMethodCallHandler(nil)

        // Clean up extracted files
        if let extractedPath = extractedPath {
            try? FileManager.default.removeItem(at: extractedPath)
        }
    }
}
