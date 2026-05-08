import Flutter
import UIKit

public class FlutterComicsPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_comics", binaryMessenger: registrar.messenger())
    let instance = FlutterComicsPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)

    // Register Platform View Factory for native comics rendering
    let factory = ComicsViewFactory(messenger: registrar.messenger())
    registrar.register(factory, withId: "flutter_comics_view")
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
