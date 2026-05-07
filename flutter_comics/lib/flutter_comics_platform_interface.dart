import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_comics_method_channel.dart';
import 'src/models.dart';

/// Platform interface for flutter_comics plugin.
///
/// This class is used for registering platform-specific implementations
/// and provides the base API for platform communication.
abstract class FlutterComicsPlatform extends PlatformInterface {
  FlutterComicsPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterComicsPlatform _instance = MethodChannelFlutterComics();

  /// The default instance of [FlutterComicsPlatform] to use.
  static FlutterComicsPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterComicsPlatform].
  static set instance(FlutterComicsPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Get platform version (for debugging)
  Future<String?> getPlatformVersion() {
    throw UnimplementedError('getPlatformVersion() has not been implemented.');
  }

  /// Check if native rendering is available on this platform
  Future<bool> isSupported() {
    throw UnimplementedError('isSupported() has not been implemented.');
  }
}
