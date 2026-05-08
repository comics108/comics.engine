import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_comics_platform_interface.dart';

/// Method channel implementation of [FlutterComicsPlatform].
class MethodChannelFlutterComics extends FlutterComicsPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_comics');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<bool> isSupported() async {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return true;
      default:
        return false;
    }
  }
}
