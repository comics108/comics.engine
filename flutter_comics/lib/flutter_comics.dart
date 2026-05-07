
import 'flutter_comics_platform_interface.dart';

class FlutterComics {
  Future<String?> getPlatformVersion() {
    return FlutterComicsPlatform.instance.getPlatformVersion();
  }
}
