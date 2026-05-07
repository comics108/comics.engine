import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_comics_method_channel.dart';

abstract class FlutterComicsPlatform extends PlatformInterface {
  /// Constructs a FlutterComicsPlatform.
  FlutterComicsPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterComicsPlatform _instance = MethodChannelFlutterComics();

  /// The default instance of [FlutterComicsPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterComics].
  static FlutterComicsPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterComicsPlatform] when
  /// they register themselves.
  static set instance(FlutterComicsPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
