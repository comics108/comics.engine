import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_comics/flutter_comics.dart';
import 'package:flutter_comics/flutter_comics_platform_interface.dart';
import 'package:flutter_comics/flutter_comics_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterComicsPlatform
    with MockPlatformInterfaceMixin
    implements FlutterComicsPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterComicsPlatform initialPlatform = FlutterComicsPlatform.instance;

  test('$MethodChannelFlutterComics is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterComics>());
  });

  test('getPlatformVersion', () async {
    FlutterComics flutterComicsPlugin = FlutterComics();
    MockFlutterComicsPlatform fakePlatform = MockFlutterComicsPlatform();
    FlutterComicsPlatform.instance = fakePlatform;

    expect(await flutterComicsPlugin.getPlatformVersion(), '42');
  });
}
