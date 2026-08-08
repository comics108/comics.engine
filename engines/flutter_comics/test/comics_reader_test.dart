// flows/sdd-flutter-comics Plan Task 4.2: ComicsArchiveReader round-trips a
// synthetic in-memory archive covering every current schema field --
// solidColor/mask/kind/style/parentId/groupId/textRegion/translations,
// scrollType/preferredOrientation/preferredViewportWidth/Height, Anim.basis,
// not just the five DartComicsViewerBackend's own deleted minimal parser
// used to handle (real drift confirmed during this flow's own analysis).
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_comics/flutter_comics.dart';

Uint8List _zipOf(Map<String, dynamic> dataJson) {
  final jsonBytes = utf8.encode(jsonEncode(dataJson));
  final archive = Archive()..addFile(ArchiveFile('data.json', jsonBytes.length, jsonBytes));
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

void main() {
  group('ComicsArchiveReader.readBytes -- full schema coverage', () {
    test('every current schema field round-trips, not just the legacy minimal subset', () async {
      final bytes = _zipOf({
        'width': 720,
        'height': 3200,
        'scrollType': 'horizontal',
        'preferredOrientation': 'landscape',
        'preferredViewportWidth': 1080,
        'preferredViewportHeight': 1920,
        'layers': [
          {
            'id': 'layer-1',
            'kind': 'balloon',
            'style': 'speech',
            'parentId': 'layer-0',
            'groupId': 'group-a',
            'solidColor': '#ff0000',
            'mask': {
              'shape': 'rect',
              'rect': {'x': 1.0, 'y': 2.0, 'w': 3.0, 'h': 4.0},
            },
            'textRegion': {
              'shape': 'polygon',
              'points': [
                {'x': 0.0, 'y': 0.0},
                {'x': 10.0, 'y': 0.0},
                {'x': 10.0, 'y': 10.0},
              ],
              'isHandLettered': true,
            },
            'translations': {'en': 'hello', 'ru': 'привет'},
            'images': [
              {'file': 'a_en_{0}_{1}_{2}.png', 'popup': 'a_en_popup.png'},
              {'file': 'a_ru_{0}_{1}_{2}.png'},
              {'file': ''},
            ],
            'animations': [
              {
                r'$type': 'Comics.Editor.Models.TranslateAnim, Comics.Editor',
                'x': 100,
                'y': 200,
                'start': 0,
                'end': 500,
                'basis': 'time',
                'loop': false,
              },
              {
                r'$type': 'Comics.Editor.Models.AlphaAnim, Comics.Editor',
                'alpha': 0.5,
              },
            ],
          },
        ],
        'sounds': [
          {
            'file': 'music.mp3',
            'animations': [
              {
                r'$type': 'Comics.Editor.Models.SoundAnim, Comics.Editor',
                'start': 10,
                'end': 20,
              },
            ],
          },
        ],
      });

      final doc = await ComicsArchiveReader.readBytes(bytes, name: 'chapter.comics');

      expect(doc.type, DocType.comics);
      expect(doc.width, 720);
      expect(doc.height, 3200);
      expect(doc.scrollType, ScrollType.horizontal);
      expect(doc.preferredOrientation, PreferredOrientation.landscape);
      expect(doc.preferredViewportWidth, 1080);
      expect(doc.preferredViewportHeight, 1920);

      expect(doc.layers, hasLength(1));
      final layer = doc.layers.single;
      expect(layer.id, 'layer-1');
      expect(layer.kind, 'balloon');
      expect(layer.style, 'speech');
      expect(layer.parentId, 'layer-0');
      expect(layer.groupId, 'group-a');
      expect(layer.solidColor, '#ff0000');
      expect(layer.mask!.shape, 'rect');
      expect(layer.mask!.rect, const Rect.fromLTWH(1, 2, 3, 4));
      expect(layer.textRegion!.shape, 'polygon');
      expect(layer.textRegion!.points, hasLength(3));
      expect(layer.textRegion!.isHandLettered, isTrue);
      expect(layer.translations['en'], 'hello');
      expect(layer.translations['ru'], 'привет');
      expect(layer.images[0].file, 'a_en_{0}_{1}_{2}.png');
      expect(layer.images[0].popup, 'a_en_popup.png');
      expect(layer.images[1].file, 'a_ru_{0}_{1}_{2}.png');

      expect(layer.anims, hasLength(2));
      final translate = layer.anims.firstWhere((a) => a.type == AnimType.translate);
      expect(translate.x, 100);
      expect(translate.y, 200);
      expect(translate.start, 0);
      expect(translate.end, 500);
      expect(translate.basis, AnimBasis.time);
      expect(translate.loop, isFalse);
      final alpha = layer.anims.firstWhere((a) => a.type == AnimType.alpha);
      expect(alpha.alpha, 0.5);

      expect(doc.sounds, hasLength(1));
      expect(doc.sounds.single.file, 'music.mp3');
      expect(doc.sounds.single.anims.single.type, AnimType.sound);
      expect(doc.sounds.single.anims.single.start, 10);
      expect(doc.sounds.single.anims.single.end, 20);
    });

    test('a .puzzle filename is detected via the name parameter, mirroring '
        "comicsFromCore's own filename sniff", () async {
      final bytes = _zipOf({'width': 1024, 'height': 768, 'layers': [], 'sounds': []});
      final doc = await ComicsArchiveReader.readBytes(bytes, name: 'board.puzzle');
      expect(doc.type, DocType.puzzle);
    });

    test('omitted name defaults to DocType.comics', () async {
      final bytes = _zipOf({'width': 1024, 'height': 768, 'layers': [], 'sounds': []});
      final doc = await ComicsArchiveReader.readBytes(bytes);
      expect(doc.type, DocType.comics);
    });

    test('missing scrollType/preferredOrientation/preferredViewportWidth/Height '
        'default exactly like comicsFromCore (backward-compat)', () async {
      final bytes = _zipOf({'width': 1080, 'height': 1920, 'layers': [], 'sounds': []});
      final doc = await ComicsArchiveReader.readBytes(bytes);
      expect(doc.scrollType, ScrollType.vertical);
      expect(doc.preferredOrientation, PreferredOrientation.portrait);
      expect(doc.preferredViewportWidth, 720);
      expect(doc.preferredViewportHeight, 1600);
    });

    test('a layer with no solidColor/mask/kind/style/parentId/groupId/textRegion '
        'leaves them all null, matching every real legacy file', () async {
      final bytes = _zipOf({
        'width': 1080,
        'height': 1920,
        'layers': [
          {'images': [{'file': 'x.png'}], 'animations': []},
        ],
        'sounds': [],
      });
      final doc = await ComicsArchiveReader.readBytes(bytes);
      final layer = doc.layers.single;
      expect(layer.solidColor, isNull);
      expect(layer.mask, isNull);
      expect(layer.kind, isNull);
      expect(layer.style, isNull);
      expect(layer.parentId, isNull);
      expect(layer.groupId, isNull);
      expect(layer.textRegion, isNull);
      expect(layer.translations, isEmpty);
    });
  });

  group('Error handling (F1)', () {
    test('missing data.json throws FormatException', () async {
      final archive = Archive();
      final bytes = Uint8List.fromList(ZipEncoder().encode(archive));
      expect(() => ComicsArchiveReader.readBytes(bytes), throwsFormatException);
    });

    test('a corrupt (non-zip) byte blob throws FormatException', () async {
      expect(
        () => ComicsArchiveReader.readBytes(Uint8List.fromList([1, 2, 3, 4, 5])),
        throwsFormatException,
      );
    });

    test('data.json that is not a JSON object throws FormatException', () async {
      final jsonBytes = utf8.encode(jsonEncode([1, 2, 3]));
      final archive = Archive()..addFile(ArchiveFile('data.json', jsonBytes.length, jsonBytes));
      final bytes = Uint8List.fromList(ZipEncoder().encode(archive));
      expect(() => ComicsArchiveReader.readBytes(bytes), throwsFormatException);
    });
  });

  group('ComicsArchiveReader.readFile', () {
    test('reads real bytes from disk via the Web-safe readFileBytes shim', () async {
      final bytes = _zipOf({'width': 500, 'height': 600, 'layers': [], 'sounds': []});
      final dir = await Directory.systemTemp.createTemp('comics_reader_test');
      final file = File('${dir.path}/sample.comics');
      await file.writeAsBytes(bytes);
      addTearDown(() => dir.deleteSync(recursive: true));

      final doc = await ComicsArchiveReader.readFile(file.path);
      expect(doc.type, DocType.comics);
      expect(doc.width, 500);
      expect(doc.height, 600);
    });

    test('a .puzzle file on disk is detected from its real filename', () async {
      final bytes = _zipOf({'width': 1024, 'height': 768, 'layers': [], 'sounds': []});
      final dir = await Directory.systemTemp.createTemp('comics_reader_test');
      final file = File('${dir.path}/board.puzzle');
      await file.writeAsBytes(bytes);
      addTearDown(() => dir.deleteSync(recursive: true));

      final doc = await ComicsArchiveReader.readFile(file.path);
      expect(doc.type, DocType.puzzle);
    });
  });
}
